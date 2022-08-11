// Decode PHY_FIFO data & store HEADER, PAYLOAD to DISTINCT FIFO
// TODO [x] : CRC check 

module MAC_DEC #(
	parameter HEADER_DWIDTH = 128
)(
	clk,
	arst_n,
	
	// INBOUND : PHY0-FIFO
	i0_fifo_dout,
	i0_fifo_empty,
	i0_fifo_aempty,
	i0_fifo_afull,
	i0_fifo_rden,
	i0_fifo_del,

	// INBOUND : PHY1-FIFO	
	i1_fifo_dout,
	i1_fifo_empty,
	i1_fifo_aempty,
	i1_fifo_afull,	
	i1_fifo_rden,
	i1_fifo_del,

	// INBOUND : PHY2-FIFO
	i2_fifo_dout,
	i2_fifo_empty,
	i2_fifo_aempty,
	i2_fifo_afull,	
	i2_fifo_rden,
	i2_fifo_del,

	// INBOUND : PHY3-FIFO
	i3_fifo_dout,
	i3_fifo_empty,
	i3_fifo_aempty,
	i3_fifo_afull,	
	i3_fifo_rden,
	i3_fifo_del,
			
	// OUTBOUND : HEADER_FIFO	
	h_fifo_din,
	h_fifo_full,
	h_fifo_wren,
	
	// OUTBOUND : BODY_FIFO 
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
	input wire i0_fifo_afull;	
	output reg i0_fifo_rden;
	input wire i0_fifo_del;

 	// PHY1-FIFO	
	input wire [7:0] i1_fifo_dout;
	input wire i1_fifo_empty;
	input wire i1_fifo_aempty;
	input wire i1_fifo_afull;	
	output reg i1_fifo_rden;
	input wire i1_fifo_del;	

 	// PHY2-FIFO	
	input wire [7:0] i2_fifo_dout;
	input wire i2_fifo_empty;
	input wire i2_fifo_aempty;
	input wire i2_fifo_afull;	
	output reg i2_fifo_rden;
	input wire i2_fifo_del;

 	// PHY3-FIFO	
	input wire [7:0] i3_fifo_dout;
	input wire i3_fifo_empty;
	input wire i3_fifo_aempty;
	input wire i3_fifo_afull;
	output reg i3_fifo_rden;
	input wire i3_fifo_del;
	
	// select phy id by schedular
	reg [1:0] phy_id_reg;

	// FCS section is valid
	reg fcs_correct_reg;

	// HEADER-FIFO
	// h_fifo_din[HEADER_DWIDTH-1:0] = {RESERVED[11:0], FCS_CORRECT[0:0], is_CTRL_FRAME[0:0], PORT[1:0], SRC_MAC[47:0], DST_MAC[47:0], TYPE[15:0]}
	output wire [HEADER_DWIDTH-1:0] h_fifo_din;	
	input  wire h_fifo_full;
	output wire h_fifo_wren;	
	reg [111:0] h_fifo_din_reg;
	reg h_fifo_wren_reg;
	// ctrl frame should be processed by CPU.
	localparam integer BPDS_ADDR  = 48'h01_80_C2_00_00_00;
	localparam integer PAUSE_ADDR = 48'h01_80_C2_00_00_01;
	wire is_ctrl_frame = (h_fifo_din_reg[63:16] == BPDS_ADDR)? 1'b1 : 
					     (h_fifo_din_reg[63:16] == PAUSE_ADDR) ? 1'b1 : 1'b0;
	assign h_fifo_din = {12'b0, fcs_correct_reg, is_ctrl_frame, phy_id_reg, h_fifo_din_reg};	
	assign h_fifo_wren= h_fifo_wren_reg;
			
	// BODY-FIFO
	output wire [7:0] b_fifo_din;
	input  wire b_fifo_afull;
	output wire b_fifo_wren;
	output wire b_fifo_del;
	reg [7:0] b_fifo_din_reg;
	reg b_fifo_wren_reg;	
	reg b_fifo_del_reg;
	assign b_fifo_din = b_fifo_din_reg;
	assign b_fifo_wren= b_fifo_wren_reg;
	assign b_fifo_del = b_fifo_del_reg;	

	// STATE MACHINE
	reg [2:0] STATE;
	localparam S_IDLE = 3'b000,
    	  S_HEADER  = 3'b001,
    	  S_PAYLOAD = 3'b010,
    	  S_FCS     = 3'b011,
    	  S_END     = 3'b100;		

	// general purpose counter
	reg [3:0] cnt_reg;

	wire [3:0] i_fifo_aempty;
	assign i_fifo_aempty = {i3_fifo_aempty, i2_fifo_aempty, i1_fifo_aempty, i0_fifo_aempty};
	
	wire [3:0] i_fifo_afull;
	assign i_fifo_afull  = {i3_fifo_afull , i2_fifo_afull , i1_fifo_afull , i0_fifo_afull };
	
	// MUX by phy_id_reg
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
						   
	// DEMUX input fifo read_enable by phy_id_reg
	wire i_fifo_rden;
	reg  i_fifo_rden_reg;
	assign i_fifo_rden = i_fifo_rden_reg;
	always @*
	begin
		case (phy_id_reg)
			2'b00 : 
				begin				
					i0_fifo_rden = i_fifo_rden;
					i1_fifo_rden = 1'b0;
					i2_fifo_rden = 1'b0;
					i3_fifo_rden = 1'b0;
				end
			2'b01 : 
				begin
					i0_fifo_rden = 1'b0;
					i1_fifo_rden = i_fifo_rden;
					i2_fifo_rden = 1'b0;
					i3_fifo_rden = 1'b0;
				end
			2'b10 :
				begin
					i0_fifo_rden = 1'b0;
					i1_fifo_rden = 1'b0;
					i2_fifo_rden = i_fifo_rden;
					i3_fifo_rden = 1'b0;
				end
			2'b11 :
				begin
					i0_fifo_rden = 1'b0;
					i1_fifo_rden = 1'b0;
					i2_fifo_rden = 1'b0;
					i3_fifo_rden = i_fifo_rden;
				end
			default : 
				begin
					i0_fifo_rden = 1'b0;
					i1_fifo_rden = 1'b0;
					i2_fifo_rden = 1'b0;
					i3_fifo_rden = 1'b0;				
				end
		endcase		
	end

	// FCS-Checker
	wire [7:0] crc_data_in;
	assign crc_data_in = i_fifo_dout;
	reg crc_en_reg;
	wire [31:0] crc_out;
	reg crc_rst_reg;
	crc crc_impl(.data_in(crc_data_in),
  				.crc_en(crc_en_reg),
  				.crc_out(crc_out),
 				.rst(~arst_n | crc_rst_reg),
  				.clk(clk));	

	always @(posedge clk or negedge arst_n)
	begin
		if (arst_n == 1'b0)
		begin
			cnt_reg     <= 4'b0;
			crc_rst_reg <= 1'b0;
			crc_en_reg  <= 1'b0;
			phy_id_reg  <= 2'b00;
			i_fifo_rden_reg <= 1'b0;
			b_fifo_wren_reg <= 1'b0;
			b_fifo_din_reg  <= 8'b0;
			b_fifo_del_reg  <= 1'b0;
			h_fifo_wren_reg <= 1'b0;
			h_fifo_din_reg  <= 112'b0;
			fcs_correct_reg <= 1'b0;
			STATE   <= S_IDLE;			
		end
		else
		begin
			i_fifo_rden_reg <= 1'b0;
			crc_en_reg      <= 1'b0;

			if (STATE == S_IDLE)
			begin
				crc_rst_reg <= 1'b1;
				// Require h_fifo has space & b_fifo_afull has space able to store 1,514B
				// This assumption will achieve circuit simplicity.
				if (~h_fifo_full & ~b_fifo_afull)
				begin
				 	STATE <= S_HEADER;
				 	/* simple scheduler 
				 	   a PHY-RX FIFO is also full, it has high priority in ascending order on phy_id */
					casex (~i_fifo_aempty)
						4'bxxx1 : phy_id_reg <= 2'd0;
						4'bxx10 : phy_id_reg <= 2'd1;
						4'bx100 : phy_id_reg <= 2'd2;
						4'b1000 : phy_id_reg <= 2'd3;
						default : ;
					endcase
					
					casex (i_fifo_afull)
						4'bxxx1 : phy_id_reg <= 2'd0;
						4'bxx10 : phy_id_reg <= 2'd1;
						4'bx100 : phy_id_reg <= 2'd2;
						4'b1000 : phy_id_reg <= 2'd3;
						default : STATE <= S_IDLE; // if no one is selectable, stay IDLE;
					endcase
				end					
			end
			
			else if (STATE == S_HEADER)
			begin
				crc_rst_reg <= 1'b0;
				// TODO[x] : if reach DELIMITER, GO TO S_END
				// TODO[x] : if i_fifo EMPTY, STOLE & wait
				if (i_fifo_del == 1'b1) // end of FRAME, something wrong happend, go to S_END
				begin				
					i_fifo_rden_reg <= 1'b1;
					STATE <= S_END;
				end
				else if (i_fifo_empty) 
				begin
					/* stole */
					i_fifo_rden_reg <= 1'b0;
				end
				else // data has provided, store HEADER to h_fifo.
				begin
					cnt_reg         <= cnt_reg + 1'b1;
					crc_en_reg      <= 1'b1;
					i_fifo_rden_reg <= 1'b1;
					h_fifo_din_reg  <= {h_fifo_din_reg[103:0], i_fifo_dout};
					if (cnt_reg == 4'd13) // end of HEADER, go to S_PAYLOAD
						STATE <= S_PAYLOAD;
				end
			end
			
			else if (STATE == S_PAYLOAD)
			begin
				if (i_fifo_empty)
				begin
					/* stole */ 
					crc_en_reg      <= 1'b0;
					i_fifo_rden_reg <= 1'b0;
					b_fifo_wren_reg <= 1'b0;
				end
				else    // if data has provided, store to b_fifo.
				begin
					crc_en_reg      <= 1'b1;
					i_fifo_rden_reg <= 1'b1;
					b_fifo_wren_reg <= 1'b1;
					b_fifo_din_reg  <= i_fifo_dout;
					if (i_fifo_del == 1'b1) // end of frame
					begin
						b_fifo_del_reg  <= 1'b1;  // write delimiter to body FIFO
						STATE           <= S_FCS;
					end
				end
			end
			
			else if (STATE == S_FCS) // check FCS section
			begin
				h_fifo_wren_reg <= 1'b1;  // write to header FIFO
				b_fifo_wren_reg <= 1'b0;
				b_fifo_del_reg  <= 1'b0;
				crc_en_reg      <= 1'b0;
				fcs_correct_reg <= (crc_out == 32'hC704_DD7B) ? 1'b1 : 1'b0;	
				STATE           <= S_END;
			end
			
			else if (STATE == S_END)
			begin
				cnt_reg         <= 4'b0;
				crc_rst_reg     <= 1'b1;
				crc_en_reg      <= 1'b0;
				phy_id_reg      <= 1'b0;
				i_fifo_rden_reg <= 1'b0;
				b_fifo_wren_reg <= 1'b0;
				b_fifo_din_reg  <= 8'b0;
				b_fifo_del_reg  <= 1'b0;
				h_fifo_wren_reg <= 1'b0;
				h_fifo_din_reg  <= 112'b0;
				fcs_correct_reg <= 1'b0;
				STATE           <= S_IDLE;
			end
			
			else // UNDEFINED STATE
			begin
				STATE <= S_END;
			end
		end
	end

endmodule
