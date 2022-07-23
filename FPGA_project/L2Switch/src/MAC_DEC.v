// Decode PHY_FIFO data & store HEADER, PAYLOAD to DISTINCT FIFO

module MAC_DEC(
	clk,
	arst_n,
	
	// PHY0-FIFO
	i0_fifo_dout,
	i0_fifo_empty,
	i0_fifo_aempty,
	i0_fifo_rden,
	i0_fifo_del,

	// PHY1-FIFO	
	i1_fifo_dout,
	i1_fifo_empty,
	i1_fifo_aempty,
	i1_fifo_rden,
	i1_fifo_del,

	// PHY2-FIFO
	i2_fifo_dout,
	i2_fifo_empty,
	i2_fifo_aempty,
	i2_fifo_rden,
	i2_fifo_del,

	// PHY3-FIFO
	i3_fifo_dout,
	i3_fifo_empty,
	i3_fifo_aempty,
	i3_fifo_rden,
	i3_fifo_del,	
			
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
 	
 	// PHY0-FIFO
	input wire [7:0] i0_fifo_dout;
	input wire i0_fifo_empty;
	input wire i0_fifo_aempty;
	output reg i0_fifo_rden;
	input wire i0_fifo_del;

 	// PHY1-FIFO	
	input wire [7:0] i1_fifo_dout;
	input wire i1_fifo_empty;
	input wire i1_fifo_aempty;
	output reg i1_fifo_rden;
	input wire i1_fifo_del;	

 	// PHY2-FIFO	
	input wire [7:0] i2_fifo_dout;
	input wire i2_fifo_empty;
	input wire i2_fifo_aempty;
	output reg i2_fifo_rden;
	input wire i2_fifo_del;

 	// PHY3-FIFO	
	input wire [7:0] i3_fifo_dout;
	input wire i3_fifo_empty;
	input wire i3_fifo_aempty;
	output reg i3_fifo_rden;
	input wire i3_fifo_del;
	
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

	// schedular depend on i_fifo_aempty
	wire [3:0] i_fifo_aempty;
	assign i_fifo_afull = {i0_fifo_aempty, i1_fifo_aempty, i2_fifo_aempty, i3_fifo_aempty};
	
	// select id by schedular
	reg [1:0] phy_id_reg;
	
	// signal MUX by phy_id_reg
	wire [7:0] i_fifo_dout;
	assign i_fifo_dout = (phy_id_reg == 2'b00) ? i0_fifo_dout :
							(phy_id_reg == 2'b01) ? i1_fifo_dout : 
							(phy_id_reg == 2'b10) ? i2_fifo_dout :
							(phy_id_reg == 2'b11) ? i3_fifo_dout : 2'bzz;
	wire i_fifo_empty;	
	assign i_fifo_empty  = (phy_id_reg == 2'b00) ? i0_fifo_empty :
						   (phy_id_reg == 2'b01) ? i1_fifo_empty : 
						   (phy_id_reg == 2'b10) ? i2_fifo_empty :
						   (phy_id_reg == 2'b11) ? i3_fifo_empty : 1'bz;
	wire i_fifo_del;
	assign i_fifo_del    = (phy_id_reg == 2'b00) ? i0_fifo_del :
						   (phy_id_reg == 2'b01) ? i1_fifo_del : 
						   (phy_id_reg == 2'b10) ? i2_fifo_del :
						   (phy_id_reg == 2'b11) ? i3_fifo_del : 1'bz;
	// DEMUX
	wire i_fifo_rden;
	assign i_fifo_rden = i_fifo_rden_reg;
	always @*
	begin
		case (phy_id_reg)
			2'b00 : i0_fifo_rden = i_fifo_rden;
			2'b01 : i1_fifo_rden = i_fifo_rden;
			2'b10 : i2_fifo_rden = i_fifo_rden;
			2'b11 : i3_fifo_rden = i_fifo_rden;
			default : ;
		endcase		
	end

	always @(posedge clk or negedge arst_n)
	begin
		if (arst_n == 1'b0)
		begin
			STATE   <= S_IDLE;
			cnt_reg <= 4'b0;
			phy_id_reg <= 2'b00;
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
				if (~h_fifo_full & ~b_fifo_afull)
				begin
				 	STATE <= S_HEADER;
					casex (~i_fifo_aempty) // simple schedular
						4'bxxx1 : phy_id_reg <= 2'b00;
						4'bxx1x : phy_id_reg <= 2'b01;
						4'bx1xx : phy_id_reg <= 2'b10;
						4'b1xxx : phy_id_reg <= 2'b11;
						default : STATE <= S_IDLE;
					endcase
				end					
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
					else // data has provided, store HEADER to h_fifo.
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
