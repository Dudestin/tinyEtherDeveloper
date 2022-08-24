/* Push frame to PHY-FIFO */
/* Only 64 (include hardware calculated 4-Byte FCS section) Byte Frame Transmitter (16-word) */

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
			iomem_rdata
		);

		input wire clk;
		input wire arst_n;

		input         iomem_valid;
		output  reg   iomem_ready;
		input  [ 3:0] iomem_wstrb;
		input  [31:0] iomem_addr;
		input  [31:0] iomem_wdata;
		output reg [31:0] iomem_rdata;

		output reg [7:0] o_fifo_din;
		output reg  o_fifo_del;
		input  wire p0_fifo_afull;
		output wire p0_fifo_wren;
		input  wire p1_fifo_afull;
		output wire p1_fifo_wren;
		input  wire p2_fifo_afull;
		output wire p2_fifo_wren;
		input  wire p3_fifo_afull;
		output wire p3_fifo_wren;

		/* TX frame statemachine */
		reg [2:0] STATE;
		localparam S_IDLE = 3'd0,
			S_WAIT = 3'd1, // wait PHY fifo ready.
			S_TX   = 3'd2,
            S_FCS  = 3'd3,
			S_END  = 3'd4;

		// Exclusive Control
		output reg  [3:0] mutex_req; // Index corresoponding to PHY_ID
		input  wire [3:0] mutex_val;

		wire [31:0] cfg_do;

		/* Config Interface */
		reg  config_tx;    // [31:31], RW, transmit frame now. be sure to don't assert when not ready.
		wire config_ready = (STATE == S_IDLE); // [30:30], R , ready to fetch data.
		wire config_busy  = ~(config_ready);  //  [29:29], R , 1 indicates busy.
		reg  config_abort; // [28:28], RW, abort TX, valid when busy state.
		reg  config_port;  // [27:24], RW, one-hot, transmit port.
		// read config	
		assign cfg_do[31] = config_tx;
		assign cfg_do[30] = config_ready;
		assign cfg_do[29] = config_busy;
		assign cfg_do[28] = config_abort;
		assign cfg_do[27:24] = config_port;
		assign cfg_do[23:0] = 24'b0;	

		/* Memory Tramsfer Interface */
		reg [31:0] frame_ram [0:15]; // 32(width)x16(depth) = 512-bit = 64 

		integer i;
		always @(posedge clk or negedge arst_n)
		begin
			if (~arst_n)
			begin
				iomem_ready <=  1'b0;
				iomem_rdata <= 32'b0;
				/* Config Interface */
				config_tx   <= 1'b0;
				config_abort<= 1'b0;
				config_port <= 4'b0;	
				/* Data transfer interface */
				for (i = 0; i < 16; i = i + 1) // reset RAM
					frame_ram[i] <= 32'b0;
			end
			else
			begin
				iomem_ready <= 1'b0;

				/* Config Interface */			
				if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h15)
				begin
					iomem_ready <= 1'b1;
					/* read from config register */
					iomem_rdata <= cfg_do;
					/* write to config register */
					if (iomem_wstrb[3])
					begin
						config_tx       <= iomem_wdata[31];
						config_abort    <= iomem_wdata[28];
						config_port     <= iomem_wdata[27:24];
					end
					else
					begin
						config_tx    <= 1'b0;
						config_abort <= 1'b0;
					end
				end

				/* Data Transfer Interface */
				if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h05)
				begin
					iomem_ready <= 1'b1;
					/* read from RAM */
					iomem_rdata <= frame_ram [iomem_addr[5:2]];	
					/* write to RAM */
					if (iomem_wstrb[3])
						frame_ram [iomem_addr[5:2]] [31:24] <= iomem_wdata[31:24];
					if (iomem_wstrb[2])
						frame_ram [iomem_addr[5:2]] [23:16] <= iomem_wdata[23:16];
					if (iomem_wstrb[1])
						frame_ram [iomem_addr[5:2]] [15: 8] <= iomem_wdata[15: 8];
					if (iomem_wstrb[0])
						frame_ram [iomem_addr[5:2]] [ 7: 0] <= iomem_wdata[ 7: 0];
				end
			end
		end

		/* TX frame interface */

		/* FCS calculation */
		wire [31:0] crc_out;
        reg  crc_en;
        reg  crc_rst;
		crc crc_impl (.data_in(o_fifo_din), .crc_en(crc_en), .crc_out(crc_out), .rst(~arst_n | crc_rst), .clk(clk));

		/* local signal */
		reg [3:0] latched_config_port;
		reg [7:0] cnt_reg;

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
                crc_en  <= 1'b0;
                crc_rst <= 1'b0;
				latched_config_port <= 4'b0;
				cnt_reg   <= 8'b0;
				port_wren <= 4'b0;
				mutex_req <= 4'b0;
			end
			else
			begin
				/* default value */
                crc_en <= 1'b0;
                crc_rst <= 1'b0;
				port_wren <= 4'b0;

				case (STATE)
					S_IDLE : 
					begin
						if (config_tx)
						begin
							latched_config_port <= config_port;
							mutex_req <= config_port; // Aquire mutex 
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
                        crc_en   <= 1'b1;
						port_wren<= latched_config_port;
						cnt_reg  <= cnt_reg + 1'b1;
						case (cnt_reg[1:0])
							2'd0: o_fifo_din <= frame_ram [cnt_reg[5:2]] [ 7: 0]; // little endian to big endian.
							2'd1: o_fifo_din <= frame_ram [cnt_reg[5:2]] [15: 8];
							2'd2: o_fifo_din <= frame_ram [cnt_reg[5:2]] [23:16];
							2'd3: o_fifo_din <= frame_ram [cnt_reg[5:2]] [31:24];
							default : o_fifo_din <= 8'b0;
						endcase

                        if (cnt_reg == 8'd59) // reach tail of frame.
                        begin
                            cnt_reg    <= 8'b0;
                            STATE      <= S_FCS;	
                        end
                    end
   
                    S_FCS :
                    begin
						port_wren<= latched_config_port;
                        cnt_reg <= cnt_reg + 1'b1;
                        case (cnt_reg[1:0])
							2'd0: o_fifo_din <= crc_out[31:24];
							2'd1: o_fifo_din <= crc_out[23:16];
							2'd2: o_fifo_din <= crc_out[15: 8];
							2'd3: 
                            begin
                                o_fifo_din <= crc_out[ 7: 0];
                                o_fifo_del <= 1'b1;
                                STATE <= S_END;
                            end
							default : o_fifo_din <= 8'b0;
                        endcase
                    end

                    S_END : 
                    begin
                        crc_rst <= 1'b1;     // reset CRC state
                        cnt_reg <= 8'd0;
                        mutex_req   <= 4'b0; // release PHY-FIFO
                        STATE <= S_IDLE;
                    end
                endcase
      

                /* abort transmit */ 
                if (config_abort && (STATE == S_END || STATE == S_IDLE))
                begin
                    port_wren    <= 4'b0;
                    mutex_req    <= 4'b0;  // release PHY-FIFO
                    STATE <= S_END;
                end
            end
        end
endmodule