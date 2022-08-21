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
		#10 clk <= 1'b1;
		#10 clk <= 1'b0;
	end

	reg [127:0] h_fifo_dout;

	initial
	begin
		h_fifo_dout <= {12'b0, };
	end

    MAC_SWITCH mac_switch(
		.clk(clk),
		.arst_n(arst_n),
		
		/* INPUT : Header FIFO */
		.h_fifo_dout(h_fifo_dout),
		.h_fifo_rden(),
		.h_fifo_empty(1'b0)
	);

endmodule
