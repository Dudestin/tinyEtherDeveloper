// RX Ethernet Module with RMII Interface
// Receive data from PHY, then store Header, Body and FCS to FIFO.

module RMII_RX( 
    arst_n,
    fifo_afull, fifo_din, fifo_wren,
    // Original FIFO Signal
    fifo_EOD_in,
    // RMII signal
    REF_CLK, CRS_DV, RXD0, RXD1,
    
    // monitor signal
    succ_rx_count_gray, // 16-bit, gray-code
    buff_OF_count_gray  // 16-bit, gray-code
 );
    // general interface
    input wire arst_n;            // async reset from user clock domain

    // RMII signal
    input  wire REF_CLK;
    input  wire RXD0;
    input  wire RXD1;
    input  wire CRS_DV;
    
    // FIFO Interface signal
    input  wire fifo_afull;       // fifo also_full
    output reg [7:0] fifo_din;
    output reg fifo_wren;
    // Original FIFO signal    
    output wire fifo_EOD_in;      // indicates End of Data. Useful to detect frame end.
     
    // monitor signal
    output wire [15:0] succ_rx_count_gray;    
    reg [15:0] succ_rx_count;
    my_bin2gray #(.WIDTH(16)) 
        succ_gray(.din(succ_rx_count), .dout(succ_rx_count_gray));
        
    output wire [15:0] buff_OF_count_gray;
    reg [15:0] buff_OF_count;
    my_bin2gray #(.WIDTH(16))
        buff_OF_gray (.din(buff_OF_count), .dout(buff_OF_count_gray));    
    
    // state 
    reg [1:0] STATE;
    localparam S_IDLE = 2'b00,
          S_PREAMBLE = 2'b01,
          S_BODY     = 2'b10,
          S_END      = 2'b11;
    
    reg [7:0] seq;
    reg [1:0] counter;

    reg RXD0_lat;
    reg RXD1_lat;
    reg CRS_DV_lat;
    
    wire DV = CRS_DV | CRS_DV_lat; // demodulate DV (Data Valid) Signal
    assign fifo_EOD_in = (STATE == S_BODY) && (counter == 2'b00) && ~DV;    
    
    always @(posedge REF_CLK or negedge arst_n)
    begin
        if (~arst_n)
        begin
            RXD0_lat <= 1'b0;
            RXD1_lat <= 1'b0;
            CRS_DV_lat <= 1'b0;     
        end else begin
            RXD0_lat <= RXD0;
            RXD1_lat <= RXD1;
            CRS_DV_lat <= CRS_DV;
        end
    end
    
    always @(posedge REF_CLK or negedge arst_n)
    begin
        if (~arst_n)
        begin
            STATE   <= S_IDLE;
            seq     <= 8'b0;
            counter <= 2'b0;
            succ_rx_count <= 16'b0;
            buff_OF_count <= 16'b0;
            fifo_wren <= 1'b0;
            fifo_din  <= 8'b0;
        end
        else
        begin
            seq <= {RXD1_lat, RXD0_lat, seq[7:2]};
            fifo_wren <= 1'b0;
            if (STATE == S_IDLE)
            begin
                counter <= 2'b0;
                if (CRS_DV)
                    if (fifo_afull)
                        buff_OF_count <= buff_OF_count + 1'b1;
                    else
                        STATE <= S_PREAMBLE;
            end
            
            else if (STATE == S_PREAMBLE)
            begin
                if (~CRS_DV)
                    STATE <= S_IDLE;
                else if (seq == 8'b1101_0101) // detect SFD
                    STATE <= S_BODY;
            end
                        
            else if (STATE == S_BODY)
            begin   
                counter <= counter + 2'b1;
                if (counter[1:0] == 2'b11)
                begin
                    fifo_din  <= seq;
                    fifo_wren <= 1'b1;
                end
                if (~DV)
                    STATE <= S_END;
            end
            
            else if (STATE == S_END)
            begin
                STATE   <= S_IDLE;
            end

            // undefined state, go to S_END 
            else
            begin
                STATE <= S_END;
            end     
            
        end
    end

endmodule
