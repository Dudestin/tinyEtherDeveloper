/* Push frame to PHY-FIFO */
/* up to 64 Byte (16-word) */

/* TODO [x] : impl. PHY-FIFO mutex system */

module CTRL_FRAME_ISSUER (
	clk,
	arst_n,
	
	/* OUTPUT : PHY-TX FIFO */
	o_fifo_din, // common for all PHY-TX FIFO
	o_fifo_del, // common for all PHY-TX FIFO
	p0_fifo_afull,
	p0_fifo_wren,
	p1_fifo_afull,
	p1_fifo_wren,
	p2_fifo_afull,
	p2_fifo_wren,
	p3_fifo_afull,
	p3_fifo_wren,
	
	mutex_req,
	mutex_val,

	/* picosoc IO interface */
	iomem_valid,
	iomem_ready,
	iomem_wstrb,
	iomem_addr,
	iomem_wdata,
	iomem_rdata,
	
	/* Config signal */
	cfg_we,
	cfg_di,
	cfg_do
);

	input wire clk;
	input wire arst_n;

	input         iomem_valid;
	output  reg   iomem_ready;
	input  [ 3:0] iomem_wstrb;
	input  [31:0] iomem_addr;
	input  [31:0] iomem_wdata;
	output reg [31:0] iomem_rdata;
	
	output wire [7:0] o_fifo_din;
	output wire o_fifo_del;
	output wire p0_fifo_afull;
	output wire p0_fifo_wren;
	output wire p1_fifo_afull;
	output wire p1_fifo_wren;
	output wire p2_fifo_afull;
	output wire p2_fifo_wren;
	output wire p3_fifo_afull;
	output wire p3_fifo_wren;
	
	// Exclusive Control
	output reg  [3:0] mutex_req; // Index corresoponding to PHY_ID
	input  wire [3:0] mutex_val;

	input  wire [ 3:0] cfg_we;
	input  wire [31:0] cfg_di;
	output wire [31:0] cfg_do;
	
	/* Config Interface */
	reg  config_tx;    // [31:31], RW, transmit frame now. be sure to don't assert when not ready.
	reg config_busy;  // [29:29], R , 1 indicates busy.
	wire config_ready = ~config_busy; // [30:30], R , ready to fetch data (now, ~busy's alias).
	reg config_abort; // [28:28], RW, abort TX, valid when busy state.
	reg config_port;  // [27:24], RW, one-hot, transmit port.
	reg config_frame_byte_len; // [23:14], RW, transmit frame Byte length (1(0) to 64(63) Byte).
 	// read config	
	assign cfg_do[31] = config_tx;
	assign cfg_do[30] = config_ready;
	assign cfg_do[29] = config_busy;
	assign cfg_do[28] = config_abort;
	assign cfg_do[27:24] = config_port;
	assign cfg_do[23:14] = config_frame_byte_len;

	always @(posedge clk or negedge arst_n)
	begin
		if (~arst_n)
		begin
			config_tx   <= 1'b0;
			config_busy <= 1'b0;
			config_abort<= 1'b0;
			config_port <= 4'b0;
			config_frame_byte_len <= 10'b0;
		end
		else
		begin
			// write config
			if (cfg_we[3])
			begin
				config_tx       <= cfg_di[31];
				config_abort    <= cfg_di[28];
				config_port     <= cfg_di[27:24];
			end

			if (cfg_we[2])
				config_frame_byte_len <= cfg_di[23:16];

			if (cfg_we[1])
			begin
				config_frame_byte_len <= cfg_di[15:14];
			end
			
		end
	end

	/* Memory Access Interface */
	reg [31:0] frame_ram [0:15]; // 32(width)x16(depth) = 512-bit = 64 
	
	integer i;
	always @(posedge clk or negedge arst_n)
	begin
		if (~arst_n)
		begin
			iomem_ready <=  1'b0;
			iomem_rdata <= 32'b0;
			for (i = 0; i < 16; i = i + 1) // reset RAM
				frame_ram[i] <= 32'b0;
		end
		else
		begin
			iomem_ready <= 1'b0;
			if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h05)
			begin
				iomem_ready <= 1'b1;
				/* read from RAM */
				iomem_rdata <= frame_ram [iomem_addr[3:0]];	
				/* write to RAM */
				if (iomem_wstrb[3])
					frame_ram [iomem_addr[3:0]] [31:24] <= iomem_wdata[31:24];
				if (iomem_wstrb[2])
					frame_ram [iomem_addr[3:0]] [23:16] <= iomem_wdata[23:16];
				if (iomem_wstrb[1])
					frame_ram [iomem_addr[3:0]] [15: 8] <= iomem_wdata[15: 8];
				if (iomem_wstrb[0])
					frame_ram [iomem_addr[3:0]] [ 7: 0] <= iomem_wdata[ 7: 0];
			end
		end
	end
	
	/* TX frame interface */
	reg [1:0] STATE;
	localparam S_IDLE = 2'd0,
		S_WAIT = 2'd1, // wait PHY fifo ready.
		S_TX   = 2'd2,
		S_END  = 2'd3;

	/* local signal */
	reg [3:0] latched_config_port;
	reg [9:0] latched_config_frame_byte_len;
	reg [31:0] wr_word_reg;	
	reg [7:0] cnt_reg;
		
	assign o_fifo_din = wr_word_reg; // common for all PHY-TX FIFO
	assign o_fifo_del = (cnt_reg == latched_config_frame_byte_len); // common for all PHY-TX FIFO

	wire phy_fifo_ready = ~|({p3_fifo_afull, p2_fifo_afull, p1_fifo_afull, p0_fifo_afull} & latched_config_port);
	reg [3:0] port_wren;
	assign p0_fifo_wren = port_wren[0];
	assign p1_fifo_wren = port_wren[1];
	assign p2_fifo_wren = port_wren[2];
	assign p3_fifo_wren = port_wren[3];
	
	always @(posedge clk or negedge arst_n)
	begin
		if (~arst_n)
		begin
			STATE <= S_IDLE;
			latched_config_port <= 4'b0;
			latched_config_frame_byte_len <= 10'b0;
			cnt_reg   <= 8'b0;
			port_wren <= 4'b0;
			mutex_req <= 4'b0;
		end
		else
		begin
			case (STATE)
				S_IDLE : 
				begin
					if (config_tx)
					begin
						config_tx   <= 1'b0;
						config_busy <= 1'b1;
						latched_config_port <= config_port;
						mutex_req <= config_port; // Aquire mutex 
						latched_config_frame_byte_len <= config_frame_byte_len;
						STATE <= S_WAIT;
					end
				end
				
				S_WAIT :
				begin
					if (phy_fifo_ready && (mutex_req == mutex_val)) // await aquiring mutex & FIFO have a space.
						STATE <= S_TX;
				end

				S_TX :
				begin
					port_wren<= latched_config_port;
					cnt_reg  <= cnt_reg + 1'b1;
					case (cnt_reg[1:0])
						2'd0: wr_word_reg <= frame_ram [cnt_reg[7:2]] [ 7: 0]; // little endian to big endian.
						2'd1: wr_word_reg <= frame_ram [cnt_reg[7:2]] [15: 8];
						2'd2: wr_word_reg <= frame_ram [cnt_reg[7:2]] [23:16];
						2'd3: wr_word_reg <= frame_ram [cnt_reg[7:2]] [31:24];
						default : wr_word_reg <= 8'b0;
					endcase

					if (cnt_reg == latched_config_frame_byte_len) // reach tail of frame.
					begin
						port_wren <= 4'b0;
						STATE     <= S_END;	
					end
				end
				
				S_END : 
				begin
					config_busy <= 1'b0;
					mutex_req   <= 4'b0; // release PHY-FIFO
					STATE <= S_IDLE;
				end
			endcase
			
			/* abort transmit */ 
			if (config_abort&& (STATE == S_END || STATE == S_IDLE))
			begin
				port_wren    <= 4'b0;
				mutex_req    <= 4'b0;  // release PHY-FIFO
				config_abort <= 1'b0;
				STATE <= S_END;
			end
		end
	end

endmodule
