/************************************************************\
 **  Copyright (c) 2011-2021 Anlogic, Inc.
 **  All Right Reserved.
\************************************************************/
/************************************************************\
 ** Log	:	This file is generated by Anlogic IP Generator.
 ** File	:	C:/Users/splas/tinyEtherDeveloper/FPGA_project/L2Switch/al_ip/clk_bufg.v
 ** Date	:	2022 07 24
 ** TD version	:	4.4.433
\************************************************************/

`timescale 1ns / 1ps

module clk_bufg ( i, o );
output 		o;
input  		i;

		EG_LOGIC_BUFG bufg(
		.i(i),
		.o(o));

endmodule