module tb_MAC_SWITCH (
);
    reg clk;
    reg arst_n;
    
    initial
    begin
        $dumpfile("./vcd/tb_switch.vcd");
        $dumpvars(0, mac_switch);
		arst_n <= 1'b0;
		#100  arst_n <= 1'b1;
		
		#10000 $finish;
    end

	always
	begin
		clk <= 1'b1;
        #10;
		clk <= 1'b0;
        #10;
	end

	reg [127:0] h_fifo_dout;
    wire h_fifo_rden;
    reg h_fifo_empty;

    reg [7:0] b_fifo_dout;
    wire b_fifo_rden;
    reg b_fifo_empty;
    reg b_fifo_del;

	initial
	begin
        h_fifo_empty <= 1'b1;
        h_fifo_dout <= {12'b0, 1'b1, 1'b0, 2'd2, 
            48'hFF_FF_FF_FF_FF_FF, 48'h0A_0B_0C_0D_0E, 16'h08_10};
        b_fifo_dout <= 8'h11;
        b_fifo_empty <= 1'b0;
        b_fifo_del  <= 1'b0;
        #1000;
        h_fifo_empty <= 1'b0;
	end

    always @(posedge clk)
    begin
        if (h_fifo_rden)
            h_fifo_dout <= h_fifo_dout + 1'b1;
        if (b_fifo_rden)
            b_fifo_dout <= b_fifo_dout + 1'b1;
        if (b_fifo_dout == 8'hFF)
            b_fifo_del <= 1'b1;
    end

    MAC_SWITCH mac_switch(
		.clk(clk),
		.arst_n(arst_n),
		
		/* INPUT : Header FIFO */
		.h_fifo_dout(h_fifo_dout),
		.h_fifo_rden(h_fifo_rden),
		.h_fifo_empty(h_fifo_empty),

        .b_fifo_dout(b_fifo_dout),
		.b_fifo_rden(b_fifo_rden),
		.b_fifo_empty(b_fifo_empty),
		.b_fifo_del(b_fifo_del),

		.p0_fifo_afull(1'b0),
		.p1_fifo_afull(1'b0),
		.p2_fifo_afull(1'b0),
		.p3_fifo_afull(1'b0),

        .mutex_req(),
        .mutex_val(4'b1111),

        .mask_port(4'b0000)
	);

endmodule
