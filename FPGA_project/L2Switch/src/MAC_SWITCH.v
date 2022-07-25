// MAC-Switch (Switching-Hub) using CAM Memory based MAC table

// TODO [x] : impl. reset unit process

module MAC_SWITCH #(
	// MAC table size 2^PORT_TABLE_SIZE each PORT
	parameter PORT_TABLE_ADDR_LEN = 3 
)(
	clk,
	arst_n,
	
	h_fifo_dout,
	h_fifo_rden,
	h_fifo_empty,
	
	b_fifo_dout,
	b_fifo_rden,
	b_fifo_empty,
	b_fifo_del,
	
	o_fifo_din,
	o_fifo_del,
	p0_fifo_afull,
	p0_fifo_wren,
	p1_fifo_afull,
	p1_fifo_wren,
	p2_fifo_afull,
	p2_fifo_wren,
	p3_fifo_afull,
	p3_fifo_wren
);
	localparam MAC_TABLE_ADDR_LEN = (PORT_TABLE_ADDR_LEN + 2);
	localparam MAC_TABLE_SIZE = 2**MAC_TABLE_ADDR_LEN;

	input wire clk;
	input wire arst_n;
	// sync reset
	wire rst_n;
	sync_2ff sync_2ff_rst_n (.clk(clk), .din(arst_n), .dout(rst_n));

	// HEADER_FIFO
	input  wire [114:0] h_fifo_dout;
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
	
	// OUTPUT FIFO
	output wire [7:0] o_fifo_din;
	reg [7:0] tx_word_reg;
	assign o_fifo_din = tx_word_reg;
	output wire o_fifo_del;
	reg o_fifo_del_reg;
	assign o_fifo_del = o_fifo_del_reg;
	
    /* fifo write enable signals */
    reg [3:0] o_fifo_wren_reg;
	output wire p0_fifo_wren;
    assign p0_fifo_wren = o_fifo_wren_reg[0];
	
	output wire p1_fifo_wren;
    assign p1_fifo_wren = o_fifo_wren_reg[1];
	
	output wire p2_fifo_wren;
    assign p2_fifo_wren = o_fifo_wren_reg[2];
	
	output wire p3_fifo_wren;
    assign p3_fifo_wren = o_fifo_wren_reg[3];

    /* fifo also full array */
	input  wire p0_fifo_afull;
	input  wire p1_fifo_afull;
	input  wire p2_fifo_afull;
	input  wire p3_fifo_afull;
	wire [3:0] fifo_afull_list;
	assign fifo_afull_list = {p0_fifo_afull, p1_fifo_afull, p2_fifo_afull, p3_fifo_afull};
	
	/* header signal assign */
	wire [0:0]  h_FRAME_VALID;
	assign h_FRAME_VALID = h_fifo_dout[114:114];	
	
	wire [1:0]  h_PORT;	
	assign h_PORT    = h_fifo_dout[113:112];
	
	wire [47:0] h_DST_MAC;
	assign h_DST_MAC = h_fifo_dout[111:64];
	
	wire [47:0] h_SRC_MAC;
	assign h_SRC_MAC = h_fifo_dout[63:16];
	
	wire [15:0] h_TYPE;
	assign h_TYPE    = h_fifo_dout[15:0];	
		
	/* STATE MACHINE */
	reg [2:0] STATE;
	localparam S_IDLE    = 3'b000,
    	  S_SRC_SEARCH   = 3'b001,
    	  S_SRC_REGISTER = 3'b010,
    	  S_DST_SEARCH   = 3'b011,
    	  S_TX_HEADER    = 3'b100,
    	  S_TX_PAYLOAD   = 3'b101,
    	  S_WAIT         = 3'b110, // not used
    	  S_END          = 3'b111;

	/* MAC Table implemented with CAM signal */
	wire [MAC_TABLE_ADDR_LEN-1:0] table_write_addr;
	reg  [MAC_TABLE_ADDR_LEN-1:0] table_write_addr_reg;
	assign table_write_addr = table_write_addr_reg;	
	
	wire [47:0] table_write_data;
	reg  [47:0] table_write_data_reg;
	assign table_write_data = table_write_data_reg;	
	
	wire table_write_delete;
	reg  table_write_delete_reg;
	assign table_write_delete = table_write_delete_reg;
	
	wire table_write_enable;
	reg  table_write_enable_reg;
	assign table_write_enable = table_write_enable_reg;
	
	wire table_write_busy;
	
	wire [47:0] table_compare_data;
	reg  [47:0] table_compare_data_reg;
	assign table_compare_data = table_compare_data_reg;
	
	wire [MAC_TABLE_SIZE-1:0] table_match_many;
	
	wire table_match;
	
	cam_bram # (
		.DATA_WIDTH(48), // MAC LENGTH
		.ADDR_WIDTH(MAC_TABLE_ADDR_LEN),  // 3(EACH PORT TABLE) + 2(PORT)
		// .CAM_STYLE("BRAM"),
		.SLICE_WIDTH(4)
	) MAC_cam (
		.clk(clk),
		.rst(~rst_n),
		
		.write_addr(table_write_addr),
		.write_data(table_write_data),
		.write_delete(table_write_delete),
		.write_enable(table_write_enable),
		.write_busy(table_write_busy),
		
		.compare_data(table_compare_data),
		.match_many(table_match_many),
		.match_single(),
		.match_addr(),
		.match(table_match)
	);
	
    /* one-hot code for match port */
	wire [3:0] match_port;
	reg [3:0] match_port_reg; 	
	assign match_port = table_match_many[3:0] | table_match_many[7:4] | 
	table_match_many[11:8] | table_match_many[15:12] | table_match_many[19:16] | 
	table_match_many[23:20] | table_match_many[27:24] | table_match_many[31:28];

	/* counter for each port */
	reg [PORT_TABLE_ADDR_LEN-1:0] port_cnt [0:3];
	
	/* general purpose counter */
	reg [3:0] cnt_reg;

    task reset_reg;
    begin
            STATE <= S_IDLE;
            h_fifo_rden_reg <= 1'b0;
	        b_fifo_rden_reg <= 1'b0;
	        tx_word_reg     <= 8'b0;
            o_fifo_wren_reg <= 4'b0;
	        table_write_addr_reg <= 1'b0;
		    table_write_data_reg <= 48'b0;
	        table_write_delete_reg <= 1'b0;
	        table_write_enable_reg <= 1'b0;
	        table_compare_data_reg <= 1'b0;
            match_port_reg <= 4'b0;
            cnt_reg  <= 4'b0;
    end
    endtask
	
	always @(posedge clk)
	begin
		if (rst_n == 1'b0)
		begin
            port_cnt[0] <= 5'b0;
            port_cnt[1] <= 5'b0;
            port_cnt[2] <= 5'b0;
            port_cnt[3] <= 5'b0; 
            reset_reg();
		end
		else
		begin
			if (STATE == S_IDLE)
			begin
				cnt_reg <= 4'b0;
				STATE <= S_SRC_SEARCH;
			end

			// search SRC_MAC from MAC table
			else if (STATE == S_SRC_SEARCH)
			begin
				table_compare_data_reg <= h_SRC_MAC;
				cnt_reg <= 4'b1;
				/* after 1 tick */
				if (cnt_reg)
				begin
					if (table_match)
						STATE <= S_DST_SEARCH;	
					else
						STATE <= S_SRC_REGISTER;
					cnt_reg <= 4'b0;
				end
			end			

			// register SRC_MAC to MAC table
			else if (STATE == S_SRC_REGISTER)
			begin
				port_cnt[h_PORT] 	   <= port_cnt[h_PORT] + 1'b1; // increment port counter
				table_write_addr_reg   <= {port_cnt[h_PORT], h_PORT};
				table_write_data_reg   <= h_SRC_MAC;
				table_write_enable_reg <= 1'b1;
				cnt_reg <= 4'b1;
				/* after 1 tick */
				if (~table_write_busy & cnt_reg) // write complete
				begin
					STATE <= S_DST_SEARCH;
					cnt_reg <= 4'b0;
				end
			end
			
			// search DST_MAC from MAC table
			else if (STATE == S_DST_SEARCH)
			begin
				table_compare_data_reg <= h_DST_MAC;
				cnt_reg <= 4'b1;
				/* after 1 tick */
				if (cnt_reg)
				begin
					if (h_FRAME_VALID)   // if frame is not broken.
					begin
						if (table_match) // if exists, cast the frame
							match_port_reg <= match_port & ~fifo_afull_list;
						else			 // if not found, broadcast the frame
							match_port_reg <= 4'b1111;
					end
					else
					begin // if frame is broken, destroy (don't send to any FIFO) the frame
						match_port_reg <= 4'b0000;
					end
					STATE   <= S_TX_HEADER;
					cnt_reg <= 4'b0;
				end
			end
			
			// send frame header
			else if (STATE == S_TX_HEADER)
			begin
				cnt_reg <= cnt_reg + 1'b1;
				if (cnt_reg == 4'b0)
                    o_fifo_wren_reg <= match_port_reg;

                case (cnt_reg)
				    // send Destination MAC Address Section
                    4'd0  : tx_word_reg <= h_DST_MAC[47:40];
                    4'd1  : tx_word_reg <= h_DST_MAC[39:32];
                    4'd2  : tx_word_reg <= h_DST_MAC[31:24];
                    4'd3  : tx_word_reg <= h_DST_MAC[23:16];
                    4'd4  : tx_word_reg <= h_DST_MAC[15:8];
                    4'd5  : tx_word_reg <= h_DST_MAC[7:0];
				    // send Source MAC Address Section
                    4'd6  : tx_word_reg <= h_SRC_MAC[47:40];
                    4'd7  : tx_word_reg <= h_SRC_MAC[39:32];
                    4'd8  : tx_word_reg <= h_SRC_MAC[31:24];
                    4'd9  : tx_word_reg <= h_SRC_MAC[23:16];
                    4'd10 : tx_word_reg <= h_SRC_MAC[15:8];
                    4'd11 : tx_word_reg <= h_SRC_MAC[7:0];
                    // send TYPE Section
                    4'd12 : tx_word_reg <= h_TYPE[15:8];
                    4'd13 : tx_word_reg <= h_TYPE[7:0];
                    default : 
                    begin
                        o_fifo_wren_reg <= 4'b0;
                        STATE <= S_TX_PAYLOAD;
                        cnt_reg <= 4'b0;
                    end
                endcase
			end
			
			// send frame payload	
			else if (STATE == S_TX_PAYLOAD)
			begin		
				if (b_fifo_del) // reach tail of frame
				begin
                    o_fifo_wren_reg <= 4'b0;
                    o_fifo_del_reg  <= 1'b1;
                    b_fifo_rden_reg  <= 1'b0;
                    STATE <= S_END;
                end
                else if (b_fifo_empty) // if fifo is empty, stole process
                begin
                    o_fifo_wren_reg <= 4'b0;
                    b_fifo_rden_reg  <= 1'b0;				
                end	
                else
                begin
                    // TODO [x] : tx payload
                    o_fifo_wren_reg <= match_port_reg;
                    b_fifo_rden_reg  <= 1'b1;
                    tx_word_reg      <= b_fifo_dout;					
                end
            end			

            // terminate
            else if (STATE == S_END)
            begin
            	o_fifo_del_reg <= 1'b0;
                // pop-out header fifo
                cnt_reg <= 4'b1; 
                if (cnt_reg)
                begin
                    // TODO [x] : Reset registers.
                    reset_reg();
                    h_fifo_rden_reg <= 1'b0;
                    STATE <= S_IDLE;
                end
                else
                    h_fifo_rden_reg <= 1'b1;
            end

            // UNDEFINED STATE
            else
            begin
                STATE <= S_END;
            end
        end
    end	

endmodule
