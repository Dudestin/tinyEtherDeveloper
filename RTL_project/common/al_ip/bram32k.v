/* used in FRAME_FIFO.v to implement PORT_FIFO */

/************************************************************\
 **  Copyright (c) 2011-2021 Anlogic, Inc.
 **  All Right Reserved.
\************************************************************/
/************************************************************\
 ** Log	:	This file is generated by Anlogic IP Generator.
 ** File	:	C:/Users/splas/tinyEtherDeveloper/FPGA_project/L2Switch/al_ip/bram32k.v
 ** Date	:	2022 07 26
 ** TD version	:	4.4.433
\************************************************************/

`timescale 1ns / 1ps

module bram32k # (
	parameter integer DATA_WIDTH = 8
)( 
	doa, dia, addra, clka, wea, rsta, 
	dob, dib, addrb, clkb, web, rstb
);

	output [DATA_WIDTH-1:0] doa;
	output [DATA_WIDTH-1:0] dob;


	input  [DATA_WIDTH-1:0] dia;
	input  [DATA_WIDTH-1:0] dib;
	input  [11:0] addra;
	input  [11:0] addrb;
	input  wea;
	input  web;
	input  clka;
	input  clkb;
	input  rsta;
	input  rstb;




	EG_LOGIC_BRAM #( .DATA_WIDTH_A(DATA_WIDTH),
				.DATA_WIDTH_B(DATA_WIDTH),
				.ADDR_WIDTH_A(12),
				.ADDR_WIDTH_B(12),
				.DATA_DEPTH_A(4096),
				.DATA_DEPTH_B(4096),
				.MODE("DP"),
				.REGMODE_A("NONE"), // OUTREG
				.REGMODE_B("NONE"),
				.WRITEMODE_A("NORMAL"),
				.WRITEMODE_B("NORMAL"),
				.RESETMODE("SYNC"),
				.IMPLEMENT("32K"),
				.INIT_FILE("NONE"),
				.FILL_ALL("00000000"))
			inst(
				.dia(dia),
				.dib(dib),
				.addra(addra),
				.addrb(addrb),
				.cea(1'b1),
				.ceb(1'b1),
				.ocea(1'b1),
				.oceb(1'b1),
				.clka(clka),
				.clkb(clkb),
				.wea(wea),
				.web(web),
				.bea(1'b0),
				.beb(1'b0),
				.rsta(rsta),
				.rstb(rstb),
				.doa(doa),
				.dob(dob));


endmodule
