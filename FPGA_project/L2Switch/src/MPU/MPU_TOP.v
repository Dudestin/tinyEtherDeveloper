module MPU_TOP( 
	input wire clk,
	input wire rst_n,
	
	// IRQ signal connected directly to CPU
	input  wire [31:0] irq,
	output wire [31:0] eoi
);

	// memory intereface
	wire i_valid;
	wire o_ready;
	wire [31:0] i_addr;
	wire [31:0] i_wdata;
	wire [3:0]  i_wstrb;
	wire [31:0] o_rdata;

	sys_sdram sys_sdram_impl(.clk(clk), .rst_n(rst_n), 
			.i_valid(i_valid), .o_ready(o_ready), 
			.i_addr(i_addr), .i_wdata(i_wdata), 
			.i_wstrb(i_wstrb), .o_rdata(o_rdata));
	
	picorv32 #(.ENABLE_IRQ(1))
	picorv32_impl(
		.clk(clk), .resetn(rst_n),
		.trap(),

		.mem_valid(i_valid),
		.mem_instr(), // If the memory transfer is an instruction fetch, the core asserts mem_instr
		.mem_ready(o_ready),

		.mem_addr(i_addr),
		.mem_wdata(i_wdata),
		.mem_wstrb(i_wstrb),
		.mem_rdata(od_rdata),

		// Look-Ahead Interface ( comment : like a cache )
		.mem_la_read(),
		.mem_la_write(),
		.mem_la_addr(),	
		.mem_la_wdata(),
		.mem_la_wstrb(),

		// Pico Co-Processor Interface (PCPI)
		.pcpi_valid(),
		.pcpi_insn(),
		.pcpi_rs1(),
		.pcpi_rs2(),
		.pcpi_wr(),
		.pcpi_rd(),
		.pcpi_wait(),
		.pcpi_ready(),

		// IRQ Interface
		.irq(irq),
		.eoi(eoi));

endmodule
