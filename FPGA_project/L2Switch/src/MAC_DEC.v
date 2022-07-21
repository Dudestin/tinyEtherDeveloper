// Decode PHY_FIFO data & store HEADER, PAYLOAD to DISTINCT FIFO

module MAC_DEC(
	clk,
	arst_n,
	
	// PHY-FIFO
	i_fifo_dout,
	i_fifo_empty,
	i_fifo_aempty,
	i_fifo_rden,
	i_fifo_del,
	
	// HEADER-FIFO	
	h_fifo_din,
	h_fifo_full,
	h_fifo_wren,
	
	// BODY-FIFO 
 	b_fifo_din,
 	b_fifo_afull,
 	b_fifo_wren,
 	b_fifo_del
 );
 	input wire clk;
 	input wire arst_n;
 	
 	// PHY-FIFO
	input wire i_fifo_dout;
	input wire i_fifo_empty;
	input wire i_fifo_aempty;
	output wire i_fifo_rden;
	input wire i_fifo_del;
	
	// HEADER-FIFO
	output wire [111:0] h_fifo_din;
	input  wire h_fifo_full;
	output wire h_fifo_wren;
	
	// BODY-FIFO
	output wire [7:0] b_fifo_din;
	input  wire b_fifo_afull;
	output wire b_fifo_wren;
	output wire b_fifo_del;

	// STATE MACHINE
	reg [1:0] STATE;
	localparam S_IDLE = 2'b00,
    	  S_HEADER = 2'b01,
    	  S_PAYLOAD = 2'b10,
    	  S_END      = 2'b11;		

	reg [3:0] cnt_reg;	
	
	reg i_fifo_rden_reg;
	
	reg b_fifo_wren_reg;
	reg [7:0] b_fifo_din_reg;
	reg h_fifo_wren_reg;	
	reg [111:0] h_fifo_din_reg;

	assign b_fifo_wren= b_fifo_wren_reg;
	assign b_fifo_din = b_fifo_din_reg;
	assign h_fifo_wren= h_fifo_wren_reg;
	assign h_fifo_din = h_fifo_din_reg;
	
	always @(posedge clk or negedge arst_n)
	begin
		if (arst_n == 1'b0)
		begin
			STATE   <= S_IDLE;
			cnt_reg <= 4'b0;
			i_fifo_rden_reg <= 1'b0;
			b_fifo_wren_reg <= 1'b0;
			b_fifo_din_reg  <= 8'b0;
			h_fifo_wren_reg <= 1'b0;
			h_fifo_din_reg  <= 111'b0;
		end
		else
		begin
			if (STATE == S_IDLE)
			begin
				// Require h_fifo has space & b_fifo_afull has space able to store 1,514B
				// This assumption will achieve circuit simplicity.
				if (~i_fifo_aempty & ~h_fifo_full & ~b_fifo_afull)
					STATE <= S_HEADER;
			end
			
			else if (STATE == S_HEADER)
			begin
				// TODO[x] : if reach DELIMITER, GO TO S_END
				// TODO[x] : if i_fifo EMPTY, STOLE & wait
				if (i_fifo_del == 1'b1) // end of FRAME, something wrong happend, go to S_END
				begin
					i_fifo_rden_reg <= 1'b0;
					STATE <= S_END; 
				end
				else
				begin
					if (cnt_reg == 4'd13) // end of HEADER, go to S_PAYLOAD
					begin
						i_fifo_rden_reg <= 1'b0;
						STATE   <= S_PAYLOAD;
					end	
					else if (i_fifo_empty) // stole
					begin
					
					end
					else // if data has provided, store HEADER to h_fifo.
					begin
						cnt_reg <= cnt_reg + 1'b1;
						i_fifo_rden_reg <= 1'b1;
						h_fifo_din_reg  <= {h_fifo_din_reg[103:0], i_fifo_dout};
					end
				end
			end
			
			else if (STATE == S_PAYLOAD)
			begin
				if (i_fifo_del == 1'b1) // end of FRAME, go to S_END
				begin
					i_fifo_rden_reg <= 1'b0;
					b_fifo_wren_reg <= 1'b0;
					h_fifo_wren_reg <= 1'b1;
					STATE <= S_END;				
				end
				else
				begin
					if (i_fifo_empty) // stole
					begin
						b_fifo_wren_reg <= 1'b0;
					end
					else // if data has provided, store to b_fifo.
					begin
						i_fifo_rden_reg <= 1'b1;
						b_fifo_wren_reg <= 1'b1;
						b_fifo_din_reg  <= i_fifo_dout;
					end
				end
			end
			
			else if (STATE == S_END)
			begin
				STATE   <= S_IDLE;
				cnt_reg <= 4'b0;
				i_fifo_rden_reg <= 1'b0;
				b_fifo_wren_reg <= 1'b0;
				b_fifo_din_reg  <= 8'b0;
				h_fifo_wren_reg <= 1'b0;
				h_fifo_din_reg  <= 111'b0;
			end
			
			else // UNDEFINED STATE
			begin
				STATE <= S_END;
			end
		end
	end

endmodule
