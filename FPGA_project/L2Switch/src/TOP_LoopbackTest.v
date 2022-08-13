// Repeater Test
// Repeat frame PHY1 -> PHY3
// RX : PHY1, TX : PHY3

module TOP_LoopbackTest(
	input wire clk,
	input wire arst_n,
	output wire [2:0] RGB_LED,
		
	// PHY1 
	output wire PHY1_RST,
	output wire PHY1_TXEN,
	output wire PHY1_TXD,
	input  wire PHY1_TXC,
	input  wire PHY1_RXD,
	input  wire PHY1_RXC,
	input  wire PHY1_CRS,
	input  wire PHY1_COL,
	
	// PHY2	
	output wire PHY2_RST,
	output wire PHY2_TXEN,
	output wire PHY2_TXD,
	output wire PHY2_TXC,
	input  wire PHY2_RXD,
	input  wire PHY2_RXC,
	input  wire PHY2_CRS,
	input  wire PHY2_COL,
	
	output wire PHY3_RST,
	output wire PHY3_TXEN,
	output wire PHY3_TXD,
	input  wire PHY3_TXC,
	input  wire PHY3_RXD,
	input  wire PHY3_RXC,
	input  wire PHY3_CRS,
	input  wire PHY3_COL
);
	assign RGB_LED[2] = 1'b0; // B
	assign RGB_LED[1] = 1'b0; // G
	assign RGB_LED[0] = fifo_empty; // ao
	
	assign PHY1_RST = RST_N;
	assign PHY2_RST = RST_N;
	assign PHY3_RST = RST_N;

	wire [7:0] fifo_din;
	wire fifo_afull;
	wire fifo_wren;
	wire fifo_EOD_in;
	SNI_RX phy_rx (
		.arst_n(RST_N),
		// FIFO Signal
		.fifo_afull(fifo_afull), .fifo_din(fifo_din), .fifo_wren(fifo_wren),
		// Original FIFO Signal
		.fifo_EOD_in(fifo_EOD_in),
		// SNI signal
		.RXC(PHY1_RXC), .CRS(PHY1_CRS), .RXD(PHY1_RXD)	);

	
	wire [7:0] fifo_dout;
	wire fifo_aempty;
	wire fifo_empty;
	wire fifo_rden;
	wire fifo_EOD_out;

	PACKET_FIFO phy_fifo (
		.rst(~RST_N), // FIFO use ACTIVE-HIGH Reset !!
		.di(fifo_din), .clkw(PHY1_RXC), .we(fifo_wren),
		.do(fifo_dout),.clkr(PHY3_TXC), .re(fifo_rden),
		.empty_flag(fifo_empty), .aempty_flag(fifo_aempty),
		.full_flag(), .afull_flag(fifo_afull), 
		// my original signal
		.EOD_in(fifo_EOD_in), .EOD_out(fifo_EOD_out)
	);
	
	SNI_TX phy_tx (
		.arst_n(RST_N),
		// FIFO signal
		.fifo_aempty(fifo_aempty), .fifo_dout(fifo_dout), .fifo_empty(fifo_empty), .fifo_rden(fifo_rden),
		// Original FIFO signal
		.fifo_EOD_out(fifo_EOD_out),
		// SNI signal
		.TXC(PHY3_TXC), .COL(PHY3_COL), .CRS(PHY3_CRS), .TXD(PHY3_TXD), .TXEN(PHY3_TXEN)
	);
	
endmodule
