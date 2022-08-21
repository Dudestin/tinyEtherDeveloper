module tb_mutex (
);
    reg clk;
    reg arst_n;
    
    initial
    begin
        $dumpfile("./vcd/tb_mutex.vcd");
        $dumpvars(0, mutex_impl);
		arst_n <= 1'b0;
		#100  arst_n <= 1'b1;
		
		#6000 $finish;
    end

	always
	begin
		#10 clk <= 1'b1;
		#10 clk <= 1'b0;
	end

	reg req_0;
	reg req_1;
	initial
	begin
		req_0 <= 1'b0;
		req_1 <= 1'b0;

		#400
		req_0 <= 1'b1;
		#100
		req_1 <= 1'b1;
		#200
		req_0 <= 1'b0;
		#200
		req_0 <= 1'b1;
		#200
		req_0 <= 1'b0;
		req_1 <= 1'b0;
		#200
		req_0 <= 1'b1;
		req_1 <= 1'b1;
		#100
		req_0 <= 1'b0;
	end

    mutex mutex_impl(
		.clk(clk),
		.arst_n(arst_n),
		
		.req_0(req_0),
		.req_1(req_1),

		.val_0(),
		.val_1()
	);

endmodule
