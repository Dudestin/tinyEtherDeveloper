module TOP_L2_SWITCH(
	CLK_IN,
	arst_n,
	
	/* PHY0 */
	PHY0_RST,
	PHY0_TXEN,
	PHY0_TXD,
	PHY0_TXC,
	PHY0_RXD,
	PHY0_RXC,
	PHY0_CRS,
	PHY0_COL,

	/* PHY1 */	
	PHY1_RST,
	PHY1_TXEN,
	PHY1_TXD,
	PHY1_TXC,
	PHY1_RXD,
	PHY1_RXC,
	PHY1_CRS,
	PHY1_COL,

	/* PHY2 */	
	PHY2_RST,
	PHY2_TXEN,
	PHY2_TXD,
	PHY2_TXC,
	PHY2_RXD,
	PHY2_RXC,
	PHY2_CRS,
	PHY2_COL,

	/* PHY3 */	
	PHY3_RST,
	PHY3_TXEN,
	PHY3_TXD,
	PHY3_TXC,
	PHY3_RXD,
	PHY3_RXC,
	PHY3_CRS,
	PHY3_COL			
);
	parameter PHY_NUM = 4;
	
	input wire CLK_IN; // 24 MHz
	input wire arst_n;	
	wire clk;
	
	// Sync Reset
	wire rst_n;
	wire rst = ~rst_n;
	sync_2ff sync_2ff_impl (.clk(clk), .din(arst_n), .dout(rst_n));	

	// 100 MHz system clock
	// TODO [] : check
	wire raw_clk;
	pll_clk100M pll_clk100M_impl(
		.refclk(CLK_IN),
		.reset(rst),
		.dclk(),
		.dcs(),
		.dwe(),
		.di(),
		.daddr(),
		.extlock(),
		.do(),
		.clk0_out(raw_clk)
	);
	clk_bufg clk_bufg_impl (.i(raw_clk), .o(clk));

	/* PHY0 */
	output wire PHY0_RST;
	output wire PHY0_TXEN;
	output wire PHY0_TXD;
	input  wire PHY0_TXC;
	input  wire PHY0_RXD;
	input  wire PHY0_RXC;
	input  wire PHY0_CRS;
	input  wire PHY0_COL;
	
	/* PHY1 */
	output wire PHY1_RST;
	output wire PHY1_TXEN;
	output wire PHY1_TXD;
	input  wire PHY1_TXC;
	input  wire PHY1_RXD;
	input  wire PHY1_RXC;
	input  wire PHY1_CRS;
	input  wire PHY1_COL;
	
	/* PHY2 */		
	output wire PHY2_RST;
	output wire PHY2_TXEN;
	output wire PHY2_TXD;
	input  wire PHY2_TXC;
	input  wire PHY2_RXD;
	input  wire PHY2_RXC;
	input  wire PHY2_CRS;
	input  wire PHY2_COL;
	
	/* PHY3 */
	output wire PHY3_RST;
	output wire PHY3_TXEN;
	output wire PHY3_TXD;
	input  wire PHY3_TXC;
	input  wire PHY3_RXD;
	input  wire PHY3_RXC;
	input  wire PHY3_CRS;
	input  wire PHY3_COL;		
	
	wire [3:0] PHY_RST  = {PHY3_RST, PHY2_RST, PHY1_RST, PHY0_RST};
	wire [3:0] PHY_TXEN = {PHY3_TXEN, PHY2_TXEN, PHY1_TXEN, PHY0_TXEN};		
	wire [3:0] PHY_TXD  = {PHY3_TXD, PHY2_TXD, PHY1_TXD, PHY0_TXD};	
	wire [3:0] PHY_TXC  = {PHY3_TXC, PHY2_TXC, PHY1_TXC, PHY0_TXC};	
	wire [3:0] PHY_RXD  = {PHY3_RXD, PHY2_RXD, PHY1_RXD, PHY0_RXD};	
	wire [3:0] PHY_RXC  = {PHY3_RXC, PHY2_RXC, PHY1_RXC, PHY0_RXC};		
	wire [3:0] PHY_CRS  = {PHY3_CRS, PHY2_CRS, PHY1_CRS, PHY0_CRS};	
	wire [3:0] PHY_COL  = {PHY3_COL, PHY2_COL, PHY1_COL, PHY0_COL};		
					
	// generate PHY-RX module & FIFO 
	wire [7:0] frame_fifo_rx_fifo_din [0:3];
	wire [3:0] frame_fifo_rx_fifo_wren;
	wire [7:0] frame_fifo_rx_fifo_dout [0:3] ;
	wire [3:0] frame_fifo_rx_fifo_rden;
	wire [3:0] frame_fifo_rx_empty_flag;
	wire [3:0] frame_fifo_rx_aempty_flag;
	wire [3:0] frame_fifo_rx_full_flag;
	wire [3:0] frame_fifo_rx_afull_flag;
	wire [3:0] frame_fifo_rx_EOD_in;
	wire [3:0] frame_fifo_rx_EOD_out;
	genvar i;
	generate
		for (i = 0; i < PHY_NUM; i = i + 1)
		begin : PHY_RX_INTERFACE
		PHY_RX phy_rx (
			.arst_n(arst_n),
			.fifo_afull(frame_fifo_rx_afull_flag[i]),
			.fifo_din(frame_fifo_rx_fifo_din[i]),
			.fifo_wren(frame_fifo_rx_fifo_wren[i]),
			// Original FIFO Signal
			.fifo_EOD_in(frame_fifo_rx_EOD_in[i]),
			// SNI signal
			.RXC(PHY_RXC[i]),
			.CRS(PHY_CRS[i]),
			.RXD(PHY_RXD[i])	
		);
		PACKET_FIFO frame_fifo_rx(
			.rst(rst),
			.di(frame_fifo_rx_fifo_din[i]),
			.clkw(PHY_RXC[i]),
			.we(frame_fifo_rx_fifo_wren[i]),
			.do(frame_fifo_rx_fifo_dout[i]),
			.clkr(clk),
			.re(frame_fifo_rx_fifo_rden[i]),
			.empty_flag(frame_fifo_rx_empty_flag[i]),
			.aempty_flag(frame_fifo_rx_aempty_flag[i]),
			.full_flag(frame_fifo_rx_full_flag[i]),
			.afull_flag(frame_fifo_rx_afull_flag[i]), 
			// my original signal
			.EOD_in(frame_fifo_rx_EOD_in[i]),
			.EOD_out(frame_fifo_rx_EOD_out[i])	
		);
		end
	endgenerate

	/* MAC Decoder */
	/* Header FIFO signal */
	wire [111:0] h_fifo_din; // TODO [] : check bit width
	wire h_fifo_full; 
	wire h_fifo_wren;
	/* Body FIFO signal */	
	wire [7:0] b_fifo_din;
	wire b_fifo_afull;
	wire b_fifo_wren;
	wire b_fifo_del;
	MAC_DEC mac_dec (
		.clk(clk),
		.arst_n(arst_n),

		// PHY0-FIFO
		.i0_fifo_dout(frame_fifo_rx_fifo_dout[0]),
		.i0_fifo_empty(frame_fifo_rx_empty_flag[0]),
		.i0_fifo_aempty(frame_fifo_rx_aempty_flag[0]),
		.i0_fifo_rden(frame_fifo_rx_fifo_rden[0]),
		.i0_fifo_del(frame_fifo_rx_EOD_out[0]),

		// PHY1-FIFO	
		.i1_fifo_dout(frame_fifo_rx_fifo_dout[1]),
		.i1_fifo_empty(frame_fifo_rx_empty_flag[1]),
		.i1_fifo_aempty(frame_fifo_rx_aempty_flag[1]),
		.i1_fifo_rden(frame_fifo_rx_fifo_rden[1]),
		.i1_fifo_del(frame_fifo_rx_EOD_out[1]),

		// PHY2-FIFO
		.i2_fifo_dout(frame_fifo_rx_fifo_dout[2]),
		.i2_fifo_empty(frame_fifo_rx_empty_flag[2]),
		.i2_fifo_aempty(frame_fifo_rx_aempty_flag[2]),
		.i2_fifo_rden(frame_fifo_rx_fifo_rden[2]),
		.i2_fifo_del(frame_fifo_rx_EOD_out[2]),

		// PHY3-FIFO
		.i3_fifo_dout(frame_fifo_rx_fifo_dout[3]),
		.i3_fifo_empty(frame_fifo_rx_empty_flag[3]),
		.i3_fifo_aempty(frame_fifo_rx_aempty_flag[3]),
		.i3_fifo_rden(frame_fifo_rx_fifo_rden[3]),
		.i3_fifo_del(frame_fifo_rx_EOD_out[3]),
			
		// HEADER-FIFO	
		.h_fifo_din(h_fifo_din),
		.h_fifo_full(h_fifo_full),
		.h_fifo_wren(h_fifo_wren),
	
		// BODY-FIFO 
 		.b_fifo_din(b_fifo_din),
 		.b_fifo_afull(b_fifo_afull),
 		.b_fifo_wren(b_fifo_wren),
 		.b_fifo_del(b_fifo_del)
	);
	
	/* Header-FIFO */
	// TODO [] : implement header fifo
	
	/* Body-FIFO */
	wire [7:0] frame_fifo_mac_b_fifo_do;
	wire frame_fifo_mac_b_fifo_re;
	wire frame_fifo_mac_b_empty_flag;
	wire frame_fifo_mac_b_EOD_out;
	PACKET_FIFO frame_fifo_mac_b_fifo(
		.rst(rst),
		.di(b_fifo_din),
		.clkw(clk),
		.we(b_fifo_wren),
		.do(frame_fifo_mac_b_fifo_do),
		.clkr(clk),
		.re(frame_fifo_mac_b_fifo_re),
		.empty_flag(frame_fifo_mac_b_empty_flag),
		.aempty_flag(), // not used here
		.full_flag(),   // not used here
		.afull_flag(b_fifo_afull), 
		// my original signal
		.EOD_in(b_fifo_del),
		.EOD_out(frame_fifo_mac_b_EOD_out)	
	);	
	
	/* MAC Switch (L2-Switch) */
	wire [7:0] frame_fifo_tx_di;         // common
	wire frame_fifo_del;                 // common
	wire [3:0] frame_fifo_tx_afull_flag; // distinct
	wire [3:0] frame_fifo_tx_we;	     // distinct
	MAC_SWITCH
	#(
		.PORT_TABLE_ADDR_LEN(3)
	) mac_switch (
		.clk(clk),
		.arst_n(arst_n),
	
		.h_fifo_dout(h_fifo_dout),
		.h_fifo_rden(h_fifo_rden),
		.h_fifo_empty(h_fifo_empty),
	
		.b_fifo_dout(frame_fifo_mac_b_fifo_do),
		.b_fifo_rden(frame_fifo_mac_b_fifo_re),
		.b_fifo_empty(frame_fifo_mac_b_empty_flag),
		.b_fifo_del(frame_fifo_mac_b_EOD_out),
	
		.o_fifo_din(frame_fifo_tx_di),
		.o_fifo_del(frame_fifo_del),
		.p0_fifo_afull(frame_fifo_tx_afull_flag[0]),
		.p0_fifo_wren(frame_fifo_tx_we[0]),		
		.p1_fifo_afull(frame_fifo_tx_afull_flag[1]),
		.p1_fifo_wren(frame_fifo_tx_we[1]),			
		.p2_fifo_afull(frame_fifo_tx_afull_flag[2]),
		.p2_fifo_wren(frame_fifo_tx_we[2]),		
		.p3_fifo_afull(frame_fifo_tx_afull_flag[3]),
		.p3_fifo_wren(frame_fifo_tx_we[3])
	);
	
	// PHY-TX module & FIFO
	wire [7:0] frame_fifo_tx_do [0:3];
	wire [3:0] frame_fifo_tx_re;
	wire [3:0] frame_fifo_tx_empty_flag;
	wire [3:0] frame_fifo_tx_aempty_flag;
	wire [3:0] frame_fifo_tx_full_flag;
	wire [3:0] frame_fifo_tx_EOD_out;
	generate
	for (i = 0; i < PHY_NUM; i = i + 1)
	begin : PHY_TX_INTERFACE
		PACKET_FIFO frame_fifo_tx (
			.rst(rst_n),
			.di(frame_fifo_tx_di),
			.clkw(clk),
			.we(frame_fifo_tx_we[i]),
			.do(frame_fifo_tx_do[i]),
			.clkr(PHY_TXC[i]),
			.re(frame_fifo_tx_re[i]),
			.empty_flag(frame_fifo_tx_empty_flag[i]),
			.aempty_flag(frame_fifo_tx_aempty_flag[i]),
			.full_flag(frame_fifo_tx_full_flag[i]),
			.afull_flag(frame_fifo_tx_afull_flag[i]), 
			// my original signal
			.EOD_in(frame_fifo_del),
			.EOD_out(frame_fifo_tx_EOD_out[i])		
		);
		PHY_TX #(
   			.IFG(96), // Interframe Gap
    		.CRC32_RES(64'hC704_DD7B) // CRC32-residue
		) phy_tx ( 
			.arst_n(arst_n),
			// FIFO signal
			.fifo_aempty(frame_fifo_tx_aempty_flag[i]),
			.fifo_dout(frame_fifo_tx_do[i]),
			.fifo_empty(frame_fifo_tx_empty_flag[i]),
			.fifo_rden(frame_fifo_tx_re[i]),
			// Original FIFO signal
			.fifo_EOD_out(frame_fifo_tx_EOD_out[i]),
			// SNI signal
			.TXC(PHY_TXC[i]),
			.COL(PHY_COL[i]),
			.CRS(PHY_COL[i]),
			.TXD(PHY_TXD[i]),
			.TXEN(PHY_TXEN[i])
		);
	end	
	endgenerate
	
endmodule
