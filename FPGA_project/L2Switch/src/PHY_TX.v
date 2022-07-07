// TX CSMA/CD Half-Duplex Ethernet Module with SNI Interface
// Transmit data to PHY
// Get data from FIFO until read EOD flags
// notice : this module don't add FCS currently.

module PHY_TX #(
    parameter IFG = 96, // Interframe Gap
    parameter CRC32_RES = 64'hC704_DD7B
)( 
	arst_n,
	// FIFO signal
	fifo_aempty, fifo_dout, fifo_empty, fifo_rden,
	// Original FIFO signal
	fifo_EOD_out,
	// SNI signal
	TXC, COL, CRS, TXD, TXEN
);
    input wire arst_n;            // async reset from user clock domain
    
    // FIFO Interface signal
    input wire fifo_aempty;       // fifo also_empty
    input wire [7:0]  fifo_dout;
    input wire fifo_empty;
    output reg fifo_rden;    
	// Original FIFO signal    
    input  wire fifo_EOD_out;     // indicates End of Data. Useful to detect frame to frame.

    // SNI (Serial Network Interface) signal
	input  wire TXC;
    input  wire COL;
    input  wire CRS;
    output wire TXD;
    output wire TXEN;
    
wire [31:0] rand_value;
// xorshift randgen (.clk(TXC), .arst_n(arst_n), .rand(rand_value));
m_seq_32 randgen(.clk(TXC), .reset(arst_n), . mseq32(rand_value));

reg [2:0] STATE;
localparam S_IDLE = 3'b000,
    S_PREAMBLE = 3'b001,
    S_BODY     = 3'b011,
    S_FCS      = 3'b111,
    S_COL      = 3'b100,
    S_END      = 3'b110;	

// used in all state
reg TXD_reg;
reg TXEN_reg;

// used in only one state
reg [5:0]  PRE_cnt;
reg [15:0] BODY_cnt;
reg [7:0]  rand_cnt;
reg [31:0] FCS_reg;
reg [4:0]  FCS_cnt;
reg [6:0]  END_cnt;

// wire assign
assign TXD  = TXD_reg;
assign TXEN = TXEN_reg;

always @(posedge TXC or negedge arst_n)
begin
    if (~arst_n)
    begin
        STATE    <= S_IDLE;
        TXD_reg  <= 1'b0;
        PRE_cnt  <= 6'b0;
		BODY_cnt <= 16'b0;
        rand_cnt <= 8'b0;
        FCS_reg  <= 32'b0;
        FCS_cnt  <= 5'b0;
        END_cnt  <= 7'b0;
        fifo_rden<= 1'b0;
    end
    else
    begin
    	fifo_rden <= 1'b0;
    	// if data is in fifo, and ~CRS, can transmit data
        if      (STATE == S_IDLE)
        begin
            TXEN_reg <= 1'b0;
            if (~fifo_aempty & ~CRS) // fifo has some data & CRS is 0
            begin
            	rand_cnt <= rand_value[7:0]; // used in S_COL
                STATE    <= S_PREAMBLE;
                if (fifo_EOD_out)    // pop last session's EOD Data from FIFO
                	fifo_rden <= 1'b1;
            end
        end
        
        // Transmit Preamble
        else if (STATE == S_PREAMBLE)
        begin
            // send preamble
            PRE_cnt     <= PRE_cnt + 6'b1; // ½I½[½o½[½t½½½[½ã“!
            TXD_reg     <= ~TXD_reg;
            TXEN_reg    <= 1'b1;
            if (PRE_cnt == 6'd63)// final preamble bit
            begin
                TXD_reg <= 1'b1; 
                STATE   <= S_BODY;
            end
        end
        
        // Transmit Frame Body
        else if (STATE == S_BODY)
        begin
            // send body data
            BODY_cnt <= BODY_cnt + 3'b1;
            TXD_reg  <= fifo_dout[BODY_cnt[2:0]];
            TXEN_reg    <= 1'b1;
            // TODO : check this state
            if (BODY_cnt[2:0] == 3'd7)
            begin
                if (fifo_EOD_out)          // detect end of data, go to S_FCS.                                    
                    STATE <= S_FCS;
                else if (fifo_empty)        // no remain data, go to S_END.
                	STATE <= S_END;
               	else
               		fifo_rden <= 1'b1;
            end
        end
        
        // Transmit FCS
        else if (STATE == S_FCS)
        begin
            // *TODO* : calc. CRC and attach FCS, currently send NULL data
            FCS_cnt   <= FCS_cnt + 5'b1;
            TXD_reg   <= FCS_reg[FCS_cnt];
            TXEN_reg  <= 1'b1;
            if (FCS_cnt == 5'd31)
            	STATE <= S_END;
        end
        
        // Discard remain data from fifo, then wait random time
        // then go to S_END
        else if (STATE == S_COL)
        begin
        	// Discard remain data from fifo.
        	fifo_rden <= ~fifo_EOD_out;
        	if (fifo_EOD_out)
        	begin
        		// Then wait randome time 
        		rand_cnt <= rand_cnt - 8'b1;
        		if (rand_cnt == 8'b0)
        			STATE <= S_END;
        	end
        end
        
        // reset all registers
        // wait to secure IFG, then go to S_IDLE
        else if (STATE == S_END)
        begin
            TXEN_reg  <= 1'b0;
            END_cnt   <= END_cnt + 7'b1;
            if (END_cnt == 7'd95) // to secure IFG (Interframe Gap), need 96 tick
            begin
            	PRE_cnt  <= 6'b0;
				BODY_cnt <= 16'b0;
                rand_cnt <= 8'b0;
                FCS_cnt  <= 5'b0;
                FCS_reg  <= 32'b0;
                END_cnt  <= 7'b0;
                STATE    <= S_IDLE;
            end
        end
        
        // undefined state, go to S_END
        else
        begin
        	// *TODO* : should discard remain data from fifo like S_COL
            TXEN_reg  <= 1'b0;
            STATE     <= S_END;
        end

        // if detect collision, go to S_COL at any state without S_COL
        if (COL & (STATE != S_COL))
        begin
            TXEN_reg  <= 1'b0;
            STATE     <= S_COL;
        end
            
    end
end
endmodule