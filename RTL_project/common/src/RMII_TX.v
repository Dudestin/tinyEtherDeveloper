/* RMII PHY-TX Interface */

module RMII_TX #( 
    parameter IFG = 48 // Interframe Gap, when 100Mbps, 0.96us.
)( 
	arst_n,
	// FIFO signal
	fifo_aempty, fifo_dout, fifo_empty, fifo_rden,
	// Original FIFO signal
	fifo_EOD_out,
	// RMII signal
	REF_CLK, TXD0, TXD1, TX_EN, CRS_DV, 
	
	// config
	duplex_mode, // 1 means full-duplex, 0 means half-duplex
	
	// monitor signal
	succ_tx_count_gray, // Success to TX frame counter, gray-encoded, 16-bit counter
	fail_tx_count_gray  // Fail to TX frame counter, gray-encoded, 16-bit counter
);

	input wire arst_n;
	input wire fifo_aempty;
	input wire [7:0] fifo_dout;
	input wire fifo_empty;
	output reg  fifo_rden;
	input wire fifo_EOD_out;
	
	input  wire REF_CLK; // 50MHz, come from PHY-Chip
	output wire TXD0;
	output wire TXD1;
	output wire TX_EN;
	input  wire CRS_DV;
	
	reg TXD0_reg;
	reg TXD1_reg;
	reg TXEN_reg;
	assign TXD0 = TXD0_reg;
	assign TXD1 = TXD1_reg;
	assign TX_EN = TXEN_reg;
	
	input wire duplex_mode;
	
	// pseudo collision detection, enable when Half-duplex mode.
	wire COL;
	assign COL = duplex_mode ? 1'b0 : CRS_DV & TX_EN;
	
	output wire [15:0] succ_tx_count_gray;
	reg [15:0] succ_tx_count; // raw binary counter
	my_bin2gray #(.WIDTH(16)) 
		succ_gray(.din(succ_tx_count), .dout(succ_tx_count_gray));
	output wire [15:0] fail_tx_count_gray;
	reg [15:0] fail_tx_count;
	my_bin2gray #(.WIDTH(16))
		fail_gray(.din(fail_tx_count), .dout(fail_tx_count_gray));
	
	reg [2:0] STATE;
	localparam S_IDLE = 3'd0,
       	S_PREAMBLE = 3'd1,
       	S_BODY     = 3'd2,
       	S_FCS      = 3'd3,
       	S_COL      = 3'd4,
       	S_END      = 3'd5;
       	
    	/* general purpose counter */
    	reg [7:0] cnt_reg;
    
    /* S_COL : random counter */
	reg [7:0] rand_cnt_reg; 
	
	/* rand value generater */
	wire [31:0] rand_value;
	m_seq_32 randgen(.clk(REF_CLK), .reset(arst_n), .mseq32(rand_value));
	
	reg [7:0] fetched_seq;
	reg fetched_EOD;
       	
    always @(posedge REF_CLK or negedge arst_n)
    	if (~arst_n)
    	begin
    		cnt_reg <= 8'b0;
        	STATE    <= S_IDLE;
        	TXD0_reg <= 1'b0;
        	TXD1_reg <= 1'b0;
        	TXEN_reg <= 1'b0;
			succ_tx_count <= 16'b0;
			fail_tx_count <= 16'b0;
        	cnt_reg  <= 8'b0;
        	rand_cnt_reg <= 8'b0;
        	fifo_rden<= 1'b0;
    	end
    	else
    	begin
    		/* default register value */
    		fifo_rden <= 1'b0;
    		  		
    		case (STATE)
    			S_IDLE : 
    			begin
    				TXD0_reg <= 1'b0; TXD1_reg <= 1'b0;
    				TXEN_reg <= 1'b0;
            		if (~fifo_aempty & ~(CRS_DV & ~duplex_mode)) // fifo has some data & CRS is 0
            		begin
            	        rand_cnt_reg  <= rand_value[7:0]; // used in S_COL	
                		STATE         <= S_PREAMBLE;
                	end
    			end
    			
    			/* transmit preamble section */
    			S_PREAMBLE : 
    			begin
    				cnt_reg <= cnt_reg + 1'b1;
    				TXEN_reg <= 1'b1;
    				if (cnt_reg < 8'd30)
    				begin
    					TXD0_reg <= 1'b1;
    					TXD1_reg <= 1'b0;
    				end
    				else if (cnt_reg == 8'd31)
    				begin
    					TXD0_reg <= 1'b1;
    					TXD1_reg <= 1'b1;
    					cnt_reg <= 0;
    					fetched_seq <= fifo_dout;
    					fetched_EOD <= 1'b0;
    					fifo_rden <= 1'b1;
    					STATE   <= S_BODY;
    				end
    			end
    			
    			/* transmit frame header & body */
    			S_BODY : 
    			begin
    				cnt_reg <= cnt_reg + 1'b1;
    				TXD0_reg <= fetched_seq[0];
    				TXD1_reg <= fetched_seq[1];
    				TXEN_reg <= 1'b1;
    				if (cnt_reg[1:0] == 2'd3)
    				begin
    					cnt_reg <= 8'b0;
    					fetched_seq <= fifo_dout; // load new byte
    					fetched_EOD <= fifo_EOD_out; // fetch eod
    					fifo_rden <= 1'b1;
						if (fetched_EOD)
						begin
    						STATE <= S_END;
    						fifo_rden <= 1'b0;
    						succ_tx_count <= succ_tx_count + 1'b1;							
						end    					
    					else if (fifo_empty)
    					begin
    						STATE <= S_END;
							fifo_rden <= 1'b0;
    						fail_tx_count <= fail_tx_count + 1'b1;
    					end
    				end else begin
    					fetched_seq <= {2'b0, fetched_seq[7:2]}; // shift sequence
    				end
    			end
    			
    			/* not implemented yet */
      			S_FCS : 
    			begin
    			
    			end 
    			
    			/* not used when full-duplex mode */	
           		// Collision occured
        		// discard remain data from fifo, then wait random time
        		// then go to S_END 			
      			S_COL : 
    			begin
    				TXEN_reg <= 1'b0;
         			// Discard remain data from fifo.
        			fifo_rden <= ~fifo_EOD_out;
        			if (fifo_EOD_out)
        			begin
        				// Then wait random time 
        				if (rand_cnt_reg == 8'b0)
        					STATE <= S_END;
        				else
        					rand_cnt_reg <= rand_cnt_reg - 1'b1;
        			end
    			end
    			
           		/* reset all registers
        		   wait to secure IFG, then go to S_IDLE */			
       			S_END : 
    			begin
    				TXD0_reg <= 1'b0; TXD1_reg <= 1'b0;
    				TXEN_reg <= 1'b0;
             		cnt_reg     <= cnt_reg + 1'b1;
            		if (cnt_reg == IFG)  // to secure IFG (Interframe Gap)
            		begin
						cnt_reg  <= 8'b0;
                		STATE    <= S_IDLE;
           			end   			
    			end
    			
    			default : // undefined state, go to S_END
    			begin
             		STATE     <= S_END;   			
    			end			
    		endcase
    		
    		if (COL & (STATE != S_COL))
            	STATE     <= S_COL;
    	end
endmodule