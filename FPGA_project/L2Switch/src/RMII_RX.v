// RX Ethernet Module with RMII Interface
// Receive data from PHY, then store Header, Body and FCS to FIFO.

module RMII_RX( 
	arst_n,
	fifo_afull, fifo_din, fifo_wren,
	// Original FIFO Signal
	fifo_EOD_in,
	// RMII signal
	REF_CLK, CRS, RXD0, RXD1,
	
	// monitor signal
	succ_rx_count_gray, // 16-bit, gray-code
	buff_OF_count_gray  // 16-bit, gray-code
 );
    // general interface
    input wire arst_n;            // async reset from user clock domain
    
    // FIFO Interface signal
    input  wire fifo_afull;       // fifo also_full
    output wire [7:0] fifo_din;
    output wire fifo_wren;
	// Original FIFO signal    
    output wire fifo_EOD_in;      // indicates End of Data. Useful to detect frame end.

    // RMII signal
	input  wire REF_CLK;
    input  wire RXD0;
    input  wire RXD1;
    input  wire CRS;
    
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

	assign fifo_din = seq;
	// store to fifo 1Byte cycle
	assign fifo_wren = (counter == 2'd3);
	// assign fifo_wren = 1'b1;	
	assign fifo_EOD_in = ~CRS & (STATE == S_BODY);
	
	always @(posedge REF_CLK or negedge arst_n)
	begin
		if (~arst_n)
		begin
			STATE   <= S_IDLE;
			seq     <= 8'b0;
			counter <= 2'b0;
		end
		else
		begin
			seq <= {seq[5:0], RXD0, RXD1};
			if (STATE == S_IDLE)
			begin
				if (CRS)
					if (fifo_afull)
						buff_OF_count <= buff_OF_count + 1'b1;
					else
						STATE <= S_PREAMBLE;
			end
			
			else if (STATE == S_PREAMBLE)
			begin
				if (~CRS)
					STATE <= S_IDLE;
				else if (seq == 8'b1010_1011) // detect SFD
					STATE <= S_BODY;
			end
						
			else if (STATE == S_BODY)
			begin
				counter <= counter + 2'b1;
				if (~CRS)
				begin
					STATE <= S_END;
				end
		
				// store to fifo 1-Byte cycle
			end
			
			else if (STATE == S_END)
			begin
				counter <= 2'b0;
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
