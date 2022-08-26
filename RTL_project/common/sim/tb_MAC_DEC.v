module tb_MAC_DEC (
);
	reg clk;
	reg arst_n;
	
	initial
	begin
        $dumpfile("./vcd/tb_MAC_DEC.vcd");
        $dumpvars(0, mac_dec);
		clk <= 1;
		arst_n <= 0;
		#100 
		arst_n <= 1;
		#10000
		$finish;
	end

	always
	begin
		clk <= 1;
		#10;
		clk <= 0;
		#10;
	end
   
    reg [7:0] i0_fifo_dout_reg;
    reg [7:0] i1_fifo_dout_reg;
    reg [7:0] i2_fifo_dout_reg;
    reg [7:0] i3_fifo_dout_reg;
    reg i0_fifo_del_reg;
    reg i1_fifo_del_reg;

    reg h_fifo_full;
    reg b_fifo_afull;

    integer i;
    initial
    begin
        i0_fifo_dout_reg <= 2;
        i1_fifo_dout_reg <= 2;
        i2_fifo_dout_reg <= 2;
        i3_fifo_dout_reg <= 2;
        i0_fifo_del_reg <= 1'b0;
        i1_fifo_del_reg <= 1'b0;
        h_fifo_full <= 1'b1;
        b_fifo_afull <= 1'b1;
        #1000
        h_fifo_full <= 1'b0;
        b_fifo_afull <= 1'b0;
    end

    wire i0_fifo_rden;
    wire i1_fifo_rden;
    wire i2_fifo_rden;
    wire i3_fifo_rden;

    always @(posedge clk)
    begin
        if (i0_fifo_rden == 1'b1)
            i0_fifo_dout_reg <= i0_fifo_dout_reg + 1'b1;
        if (i1_fifo_rden == 1'b1)
            i1_fifo_dout_reg <= i1_fifo_dout_reg + 1'b1;
        if (i2_fifo_rden == 1'b1)
            i2_fifo_dout_reg <= i2_fifo_dout_reg + 1'b1;
        if (i3_fifo_rden == 1'b1)
            i3_fifo_dout_reg <= i3_fifo_dout_reg + 1'b1;
        if (i0_fifo_dout_reg == 8'hff)
            i0_fifo_del_reg <= 1'b1;
        else
            i0_fifo_del_reg <= 1'b0;
        if (i1_fifo_dout_reg == 8'hff)
            i1_fifo_del_reg <= 1'b1;
        else
            i1_fifo_del_reg <= 1'b0;
    end


	MAC_DEC mac_dec ( 
        .clk(clk),
		.arst_n(arst_n),
        // INBOUND : PHY0-FIFO i0_fifo_dout,
        .i0_fifo_dout(i0_fifo_dout_reg),
        .i0_fifo_empty(1'b0),
        // .i0_fifo_aempty(1'b1),
        .i0_fifo_afull(1'b0),  // need to be synchronize !!
        .i0_fifo_half(1'b0),   // need to be synchronize !!
        .i0_fifo_frame_exist(1'b0),
        .i0_fifo_rden(i0_fifo_rden),
        .i0_fifo_del(i0_fifo_del_reg),

        // INBOUND : PHY1-FIFO  
        .i1_fifo_dout(i1_fifo_dout_reg),
        .i1_fifo_empty(1'b0),
        // .i1_fifo_aempty(),
        .i1_fifo_afull(1'b1),  // need to be synchronize !!
        .i1_fifo_half(1'b0),   // need to be synchronize !!
        .i1_fifo_frame_exist(1'b0),    
        .i1_fifo_rden(i1_fifo_rden),
        .i1_fifo_del(i1_fifo_del_reg),

        // INBOUND : PHY2-FIFO
        .i2_fifo_dout(i2_fifo_dout_reg),
        .i2_fifo_empty(1'b0),
        // .i2_fifo_aempty(),
        .i2_fifo_afull(1'b0),  // need to be synchronize !!
        .i2_fifo_half(1'b0),   // need to be synchronize !!
        .i2_fifo_frame_exist(1'b0),    
        .i2_fifo_rden(i2_fifo_rden),
        .i2_fifo_del(),

        // INBOUND : PHY3-FIFO
        .i3_fifo_dout(i3_fifo_dout_reg),
        .i3_fifo_empty(1'b0),
        // .i3_fifo_aempty(),
        .i3_fifo_afull(1'b0),  // need to be synchronize !!
        .i3_fifo_half(1'b0),   // need to be synchronize !!
        .i3_fifo_frame_exist(1'b0),    
        .i3_fifo_rden(i3_fifo_rden),
        .i3_fifo_del(),
            
        // OUTBOUND : HEADER_FIFO   
        .h_fifo_din(),
        .h_fifo_full(h_fifo_full),
        .h_fifo_wren(),

        // OUTBOUND : BODY_FIFO 
        .b_fifo_din(),
        .b_fifo_afull(b_fifo_afull),
        .b_fifo_wren(),
        .b_fifo_del()
	);

endmodule
