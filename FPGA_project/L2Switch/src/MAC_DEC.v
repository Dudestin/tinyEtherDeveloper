// Separate incoming data to HEADER and PAYLOAD at MAC Layer,
// Then Store to each FIFO.
// HEADER : {DST_MAC[63:0], SRC_MAC[63:0], LEN[15:0]}
// PAYLOAD: [8:0][MTU-1:0] notice : expanded 8 to 9, need to store EOD Flags

module MAC_DEC #( 
    parameter MTU = 1500
) (
	// general interface
	input  wire clk,
	input  wire arst_n,

    // SNI (Serial Network Interface) signal
    input  wire RXC,  // RX Clock
    input  wire CRS,  // Carrier Sense
    output wire RXD,
    
	// Source FIFO  Interface
	input  wire S_fifo_aempty,     // threshold should be set to nearby MTU
	input  wire S_fifo_rden,
	output wire [7:0]  S_fifo_dout,
    
    // Destination FIFO Intereface
    // Header FIFO
    inout  wire H_fifo_mutex,
    input  wire H_fifo_aempty, // threshold should set to FIFOLENGTH - MTU
 	output wire [111:0] H_fifo_din,
 	
 	// Payload FIFO
 	inout  wire P_fifo_mutex,
 	input  wire P_fifo_aempty,
 	output wire [7:0] P_fifo_din
);

	// state 
	reg [1:0]  STATE;
	paramter S_IDLE = 2'b00,
		S_HEADER = 2'b01,
		S_BODY   = 2'b10,
		S_END    = 2'b11;

	// To detect SFD & FCS
	reg [31:0] seq;

	reg [6:0]  S_HEADER_cnt;
	
	reg [111:0] header_reg;
	
	reg [15:0]  S_BODY_cnt;
	reg [7:0]   payload_reg;

	always @(posedge clk or negedge arst_n)
	begin
		if (arst_n == 1'b0)
		begin
			// TODO : reset process
		end
		else
		begin
			// Main Procedure Section
			if (STATE == S_IDLE)
			begin
				if (~S_fifo_aempty & ~H_fifo_mutex & ~P_fifo_mutex)
				begin
					STATE 
				end
				// hoge
			end
			else if (STATE == S_HEADER)
			begin
				header_reg <= {header_reg[110:0], RXD};
				S_HEADER_cnt <= S_HEADER_cnt + 1'b1;
				if (S_HEADER_cnt == 7'd111) // TODO : check
					STATE <= S_BODY;
			end
			else if (STATE == S_BODY)
			begin
				S_BODY_cnt <= S_BODY_cnt + 1'b1;
				payload_reg <= {payload_reg[6:0], RXD};
				if (S_BODY_cnt[2:0] == 3'd7)
				begin
					// TODO : write payload_reg to P_fifo
					if (S_BODY_cnt >> 3 == MTU)
						STATE <= S_BODY;
				end
				// if detect FCS, go to S_END
				if (seq[31:0] == /* FCS */)
					STATE <= S_END;
			end
			else if (STATE == S_END)
			begin
				// TODO : write preamble_reg to H_fifo
			end

			// if detect preamble, go to S_HEADER @ any STATE
			if (seq[7:0] == 8'hAB) // SFD
				STATE = S_HEADER;
			end
		end
	end
endmodule
