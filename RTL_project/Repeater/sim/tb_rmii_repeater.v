`timescale 1ns / 1ps

module tb_rmii_loopback (
);
	reg arst_n;

	reg PHY0_REF_CLK;
	reg PHY1_REF_CLK;
	
	initial
	begin
        $dumpfile("./vcd/tb_rmii_repeater.vcd");
        $dumpvars(0, rmii_repeater);
		PHY0_REF_CLK <= 1'b0;
		PHY1_REF_CLK <= 1'b0;
		arst_n <= 1;
		#100 
		arst_n <= 0;
		#100 
		arst_n <= 1;
		#200000
		$finish;
	end

	always
	begin
		#10 PHY0_REF_CLK <= 1;
		#10 PHY0_REF_CLK <= 0;
	end

	always
	begin
		#10 PHY1_REF_CLK <= 1;
		#10 PHY1_REF_CLK <= 0;
	end

	reg PHY0_CRS;
	reg PHY0_RXD0;
	reg PHY0_RXD1;

	task preamble;
	begin
		PHY0_RXD0 <= 1'b1;
		PHY0_RXD1 <= 1'b0;
		#20 
		PHY0_RXD0 <= 1'b1;
		PHY0_RXD1 <= 1'b0;
		#20 
		PHY0_RXD0 <= 1'b1;
		PHY0_RXD1 <= 1'b0;
		#20
		PHY0_RXD0 <= 1'b1;
		PHY0_RXD1 <= 1'b1;
		#20;
	end
	endtask

	initial
	begin
		PHY0_CRS <= 1'b0;
		PHY0_RXD0 <= 1'b0;
		PHY0_RXD1 <= 1'b0;
		#1000
		PHY0_CRS <= 1'b1;
		preamble();
		PHY0_RXD0 <= 1'b1;
		PHY0_RXD1 <= 1'b0;
		#100000
		PHY0_CRS <= 1'b0;
	end
	
	TOP_RMII_repeater rmii_repeater (
		.arst_n(arst_n),
		
		/* PHY0 */
		.PHY0_RST(PHY0_RST),
		.PHY0_TX_EN(PHY0_TX_EN),
		.PHY0_TXD0(PHY0_TXD0),
		.PHY0_TXD1(PHY0_TXD1),
		.PHY0_CRS(PHY0_CRS),
		.PHY0_RXD0(PHY0_RXD0),
		.PHY0_RXD1(PHY0_RXD1),
		.PHY0_REF_CLK(PHY0_REF_CLK),

		/* PHY1 */
		.PHY1_RST(PHY1_RST),
		.PHY1_TX_EN(PHY1_TX_EN),
		.PHY1_TXD0(PHY1_TXD0),
		.PHY1_TXD1(PHY1_TXD1),
		.PHY1_CRS(PHY1_CRS),
		.PHY1_RXD0(PHY1_RXD0),
		.PHY1_RXD1(PHY1_RXD1),
		.PHY1_REF_CLK(PHY1_REF_CLK)
	);
	
endmodule
