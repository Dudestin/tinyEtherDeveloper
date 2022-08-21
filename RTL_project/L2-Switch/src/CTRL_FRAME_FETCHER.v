/* fetch control frame only from H_FIFO & B_FIFO */
/* Only 64 Byte Frame fetch unit, able to store 32 frames */

module CTRL_FRAME_FETCHER #(
	parameter HEADER_DWIDTH = 128
)( 
	clk,
	arst_n,
	
	/* INPUT : Header FIFO */
	h_fifo_dout,
	h_fifo_rden,
	h_fifo_empty,

	/* INPUT : Body FIFO */
	b_fifo_dout,
	b_fifo_rden,
	b_fifo_empty,
	b_fifo_del,
	
	/* picosoc IO interface */
	iomem_valid,
	iomem_ready,
	iomem_wstrb,
	iomem_addr,
	iomem_wdata,
	iomem_rdata
);

	input wire clk;
	input wire arst_n;

	// HEADER_FIFO
	input  wire [HEADER_DWIDTH-1:0] h_fifo_dout;
	reg h_fifo_rden_reg;
	output wire h_fifo_rden;
	assign h_fifo_rden = h_fifo_rden_reg;
	input  wire h_fifo_empty;

	// PAYLOAD_FIFO
	input  wire [7:0] b_fifo_dout;	
	reg b_fifo_rden_reg;
	output wire b_fifo_rden;
	assign b_fifo_rden = b_fifo_rden_reg;
	input  wire b_fifo_empty;
	input  wire b_fifo_del; // delimiter

	/* picosoc IO interface */
	input         iomem_valid; // not used (because Read Only Interface)
	output  reg   iomem_ready;
	input  [ 3:0] iomem_wstrb; // not used (because Read Only Interface)
	input  [31:0] iomem_addr;
	input  [31:0] iomem_wdata; // not used (because Read Only Interface)
	output reg [31:0] iomem_rdata;
	
	wire [31:0] cfg_do;
	/* Config */
	wire config_frame_valid = ~fifo_empty;   // indicates valid data is provided
	reg config_get_next_data; // get next data
	reg config_ignore_bpds;   // ignore BPDS frame  (used in STP) 
	reg config_ignore_pause;  // ignore PAUSE frame (used in Flow-Control)

	assign cfg_do[31] = config_frame_valid;
	assign cfg_do[30] = config_get_next_data;
	assign cfg_do[29] = config_ignore_bpds;
	assign cfg_do[28] = config_ignore_pause;
	assign cfg_do[27:0] = 28'b0;
	
	/* Memory Interface */
	reg [5+1:0] wr_ptr1;
	reg [  3:0] wr_ptr2;
	reg [5+1:0] rd_ptr;
	reg destroy;
	wire fifo_empty = (wr_ptr1 == rd_ptr);
	wire fifo_full  = (wr_ptr1 == {~rd_ptr[6], rd_ptr[5:0]});
	reg ram_wen;
	reg  [31:0] wr_word_reg;
	wire [31:0] raw_ram_dout;

	/* TODO [] : check BRAM latency */
	CTRL_FRAME_RAM ctrl_frame_ram_impl ( 
		.doa(), .dia(wr_word_reg), .addra({wr_ptr1[5:0], wr_ptr2}), .clka(clk), .wea(ram_wen & {4{~destroy}}), .rsta(1'b0), 
		.dob(raw_ram_dout), .dib(32'bz), .addrb({rd_ptr[5:0], iomem_addr[3:0]}), .clkb(clk), .web(4'b0), .rstb(1'b0)
	);
	
	always @(posedge clk or negedge arst_n)
	begin
		if (~arst_n)
		begin
			iomem_ready <=  1'b0;
			iomem_rdata <= 32'b0;
			/* config interface */
			config_get_next_data <= 1'b0;
			config_ignore_bpds   <= 1'b0;
			config_ignore_pause  <= 1'b0;
		end
		else
		begin
			iomem_ready <= 1'b0;
			
			/* Config Interface */			
			if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h14)
			begin
				iomem_ready <= 1'b1;
				/* read from config register*/
				iomem_rdata <= cfg_do;	
				/* write data */
				if (iomem_wstrb[3])
				begin
					config_get_next_data <= iomem_wdata[30];
					config_ignore_bpds   <= iomem_wdata[29];
					config_ignore_pause  <= iomem_wdata[28];
				end
				else
				begin
					config_get_next_data <= 1'b0;
				end
			end	
			
			/* Data Transfer Interface */
			if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h04)
			begin
				iomem_ready <= 1'b1;
				/* read from RAM */
				iomem_rdata <= raw_ram_dout;
				/* read only, so no write interface there */
			end
		end
	end

	/* increment read pointer */
	always @(posedge clk or negedge arst_n)
	begin
		if (~arst_n)
		begin
			rd_ptr <= 7'b0;
		end
		else
		begin
			if (config_get_next_data & ~fifo_empty)
			begin
				rd_ptr <= rd_ptr + 1'b1;
			end
		end
	end
	
	/* write to RAM */
	/* Fetch State-machine */
	reg [1:0] STATE;
	localparam S_IDLE = 2'd0,
		S_HEADER = 2'd1,
		S_BODY   = 2'd2,
		S_END    = 2'd3;
		
	/* local signal */
	reg  [10:0] cnt_reg; // 2^11 = 2048
	wire [47:0] dst_mac = h_fifo_dout[111:64];
	wire is_bpds_frame  = (dst_mac[7:0] == 8'h00); 
	wire is_pause_frame = (dst_mac[7:0] == 8'h01);
	
	// convert endian, because riscv support little-endian, 
	// but ethernet frame follow big endian
	function [31:0] endian_conv (input [31:0] din);
	begin
		endian_conv[ 7: 0] = din[31:24];
		endian_conv[15: 8] = din[23:16];
		endian_conv[23:16] = din[15: 8];
		endian_conv[31:24] = din[7 : 0];
	end
	endfunction
	
	always @(posedge clk or negedge arst_n)
	begin
		if (~arst_n)
		begin
			STATE   <= S_IDLE;
			cnt_reg <= 11'b0;
			wr_ptr1 <= 7'b0;
			wr_ptr2 <= 4'b0;
			destroy <= 1'b0;
			wr_word_reg <= 32'b0;
		end
		else
		begin
			/* default value */
			h_fifo_rden_reg <= 1'b0;
			b_fifo_rden_reg <= 1'b0;
			ram_wen <= 1'b0;
			
			case (STATE)
				S_IDLE :
				begin
					if (~h_fifo_empty & h_fifo_dout[114]) // control frame is provided
					begin
						STATE <= S_HEADER;
					 	// if full or FCS invalid , don't write to RAM. but read from FIFOs to avoid stall 	
						if (fifo_full | ~h_fifo_dout[115])
							destroy <= 1'b1;
						else
							destroy <= 1'b0;
					end
				end
				
				S_HEADER :
				begin
					cnt_reg <= cnt_reg + 1'b1;
					wr_ptr2 <= wr_ptr2 + 1'b1;
					ram_wen <= 1'b1;
					case (cnt_reg)
						11'd0  : wr_word_reg <= endian_conv(h_fifo_dout[127:96]);
						11'd1  : wr_word_reg <= endian_conv(h_fifo_dout[ 95:64]);
						11'd2  : wr_word_reg <= endian_conv(h_fifo_dout[ 63:32]);
						11'd3  :
						begin 
							wr_word_reg <= endian_conv(h_fifo_dout[ 31: 0]);
							STATE <= S_BODY;							
						end
						default : ;
					endcase
				end
				
				S_BODY : 
				begin
					cnt_reg <= cnt_reg + 1'b1;
					b_fifo_rden_reg <= 1'b1;  // read from B-FIFO each Byte
					wr_word_reg <= {b_fifo_dout, wr_word_reg[31:8]}; // little-endian layout
					
					if (cnt_reg[1:0] == 2'd3) // write to RAM each 4 Byte (1-Word)
					begin
						wr_ptr2 <= wr_ptr2 + 1'b1;
						ram_wen <= 1'b1;
					end
					else
					begin
						wr_ptr2 <= wr_ptr2;
						ram_wen <= 1'b0;
					end
					
					// if exceed 64 Byte, ignore later bytes.
					if (cnt_reg > 11'd63)
						ram_wen <= 1'b0;
					// if reach end of frame (delimiter), don't read more & go to S_END
					if (b_fifo_del) // tail of the frame 
					begin
						b_fifo_rden_reg <= 1'b0;
						STATE <= S_END;
					end
				end
				
				S_END : 
				begin
					cnt_reg <= 11'b0;
					wr_ptr1 <= wr_ptr1 + 1'b1;
					wr_ptr2 <= 4'b0;
					wr_word_reg <= 32'b0;
					h_fifo_rden_reg <= 1'b1; // pop-out from header fifo
					destroy <= 1'b0;
					STATE <= S_IDLE;
				end
				
				default :
				begin
					STATE <= S_END;
				end
			endcase
		end
	end

endmodule
