module tb_rmii_tx (
);

	reg clk;
	reg arst_n;
	
	initial
	begin
        $dumpfile("./vcd/tb_rmii_tx.vcd");
        $dumpvars(0, rmii_tx);
        $dumpvars(0, rmii_rx);
		clk <= 0;
		arst_n <= 0;
		#100 
		arst_n <= 1;
	end

	always
	begin
		#10 clk <= 1;
		#10 clk <= 0;
	end

	reg [7:0] fifo_dout;
	reg fifo_EOD_out;
	reg fifo_aempty;
	reg fifo_empty;

	initial
	begin
		fifo_aempty <= 1'b1;
		fifo_dout   <= 8'd9;
		fifo_empty  <= 1'b0;
		fifo_EOD_out <= 1'b0;
		
		// Start TX
		#300
		fifo_aempty <= 1'b0;
	
		// End TX
		#2000
		fifo_EOD_out <= 1'b1;
		fifo_empty   <= 1'b1;
		fifo_aempty   <= 1'b1;
		#2000
		$finish;
	end

	wire TXD0;
	wire TXD1;
	wire TX_EN;
	RMII_TX rmii_tx (
		.arst_n(arst_n),
		.fifo_aempty(fifo_aempty),
		.fifo_dout(fifo_dout),
		.fifo_empty(fifo_empty),
		.fifo_rden(),
		.fifo_EOD_out(fifo_EOD_out),

		.REF_CLK(clk),
		.TXD0(TXD0),
		.TXD1(TXD1),
		.TX_EN(TX_EN),
		.CRS(1'b0),
		
		// config
		.duplex_mode(1'b1) // 1 means full-duplex, 0 means half-duplex
	);

	wire [7:0] rx_fifo_din;
	wire rx_fifo_wren;
	wire rx_fifo_EOD_in;
	RMII_RX rmii_rx ( 
		.arst_n(arst_n),
		.fifo_afull(1'b0),
		.fifo_din(rx_fifo_din),
		.fifo_wren(rx_fifo_wren),
		// Original FIFO Signal
		.fifo_EOD_in(rx_fifo_EOD_in),
		// RMII signal
		.REF_CLK(clk), .CRS(TX_EN), .RXD0(TXD0), .RXD1(TXD1)
	);
	
endmodule
