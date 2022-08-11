/* fetch control frame only from H_FIFO & B_FIFO */
/* have receive buffer able to store 32 frames */

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
	iomem_rdata,
	
	// config signal
	cfg_we,
	cfg_di,
	cfg_do
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
	input         iomem_valid;
	output        iomem_ready;
	input  [ 3:0] iomem_wstrb;
	input  [31:0] iomem_addr;
	input  [31:0] iomem_wdata;
	output [31:0] iomem_rdata;
	
	input  wire cfg_we;
	input  wire [31:0] cfg_di;
	output wire [31:0] cfg_do;
	
	/* Config */
	reg config_frame_valid;   // indicates valid data is provided
	reg config_get_next_data; // get next data
	reg config_ignore_bpds;   // ignore BPDS frame  (used in STP) 
	reg config_ignore_pause;  // ignore PAUSE frame (used in Flow-Control)

	assign cfg_do[31] = config_frame_valid;
	assign cfg_do[30] = config_get_next_data;
	assign cfg_do[29] = config_ignore_bpds;
	assign cfg_do[28] = config_ignore_pause;
	
	always @(posedge clk or negedge arst_n)
	begin
		if (~arst_n)
		begin
			config_frame_valid  <= 1'b0; // 32bit, read only
			config_get_next_data<= 1'b0; // 31bit, write & read
			config_ignore_bpds  <= 1'b0; // 30bit, write & read
			config_ignore_pause <= 1'b0; // 29bit, write & read
		end
		else
		begin
			/* write data */
			if (cfg_we[3])
			begin
				config_get_next_data <= cfg_din[30];
				config_ignore_bpds   <= cfg_din[29];
				config_ignore_pause  <= cfg_din[28];
			end

			/* read only data */
			if (config_frame_valid) 
				config_frame_valid <= ~fifo_empty;
		end
	end	
	
	/* read from RAM */
	reg [4+1:0] wr_ptr1;
	reg [  3:0] wr_ptr2;
	reg [4+1:0] rd_ptr;
	reg destroy;
	wire fifo_empty = (wr_ptr1 == rd_ptr);
	wire fifo_full  = (wr_ptr1 == {~rd_ptr[5], rd_ptr[4:0]});
	reg ram_wen;
	reg [127:0] wr_word_reg;

	CTRL_FRAME_RAM ctrl_frame_ram_impl ( 
		.doa(), .dia(wr_word_reg), .addra({wr_ptr1[4:0], wr_ptr2}), .clka(clk), .wea(ram_wen & ~destroy), .rsta(), 
		.dob(iomem_rdata), .dib(32'bz), .addrb({rd_ptr[4:0], iomem_addr[3:0]}), .clkb(clk), .web(1'b0), .rstb()
	);

	always @(posedge clk or negedge arst_n)
	begin
		if (~arst_n)
		begin
			rd_ptr <= 6'b0;
		end
		else
		begin
			if (config_get_next_data & ~fifo_empty)
			begin
				config_get_next_data <= 1'b0;
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
	reg [5:0] cnt_reg;
	wire [47:0] dst_mac = h_fifo_din[111:64];
	wire is_bpds_frame  = (dst_mac == 48'h01_80_C2_00_00_00); 
	wire is_pause_frame = (dst_mac == 48'h01_80_C2_00_00_01);
	
	always @(posedge clk or negedge arst_n)
	begin
		if (~arst_n)
		begin
			STATE   <= S_IDLE;
			cnt_reg <= 6'b0;
			wr_ptr1 <= 6'b0;
			wr_ptr2 <= 4'b0;
			destroy <= 1'b0;
			wr_word_reg <= 128'b0;
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
					 	// if full, don't write to RAM. but read from FIFOs to avoid stall 	
						if (fifo_full)
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
						6'd0  : wr_word_reg <= h_fifo_dout[127:96];
						6'd1  : wr_word_reg <= h_fifo_dout[ 95:64];
						6'd2  : wr_word_reg <= h_fifo_dout[ 63:32];
						6'd3  :
						begin 
							wr_word_reg <= h_fifo_dout[ 31: 0];
							STATE <= S_BODY;							
						end
						default : ;
					endcase
				end
				
				S_BODY : 
				begin
					cnt_reg <= cnt_reg + 1'b1;
					b_fifo_rden_reg <= 1'b1; // read from B-FIFO each Byte
					wr_word_reg <= {wr_word_reg[23:0], b_fifo_dout};		
					
					if (cnt_reg[1:0] == 2'd3) // write to RAM each 4-Byte
					begin
						wr_ptr2 <= wr_ptr2 + 1'b1;
						ram_wen <= 1'b1;
					end
					else
					begin
						wr_ptr2 <= wr_ptr2;
						ram_wen <= 1'b0;
					end
					
					if (b_fifo_del || cnt_reg[5:2] == 4'hF) // tail of the frame
					begin
						STATE <= S_END;
						b_fifo_rden_reg <= 1'b0;
					end
					else
						STATE <= S_BODY;
				end
				
				S_END : 
				begin
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
