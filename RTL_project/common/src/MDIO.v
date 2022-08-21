/* Simple MDIO memory mapped interface */
/* Address assign: [31:24] - 8'h07, [12:8] - PHY-ID, [4:0] - Register-ID */
/* Data assign   : transmit index sequence 7 -> 0, 15 -> 8 (little endian byte assign) */

module MDIO (
    clk,
    arst_n,

	/* MDIO interface */
    MDC,
    MDIO,
    
    /* picosoc IO interface */
    iomem_valid,
    iomem_ready,
    iomem_wstrb,
    iomem_addr,
    iomem_wdata,
    iomem_rdata
);
	input wire clk;
	input wire arst_n;

	/* Data transfer interface */
	input         iomem_valid;
	output  reg   iomem_ready;
	input  [ 3:0] iomem_wstrb;
	input  [31:0] iomem_addr;
	input  [31:0] iomem_wdata;
	output reg [31:0] iomem_rdata;
	reg [31:0] ram_data;

	reg [3:0] STATE;
	localparam S_IDLE = 3'd0,
		S_PREAMBLE = 3'd1,
		S_MODESET  = 3'd2,
		S_PHY_ID   = 3'd3,
		S_REG_ADDR = 3'd4,
		S_RX_DATA  = 3'd5,
		S_TX_DATA  = 3'd6,
		S_END      = 3'd7;

	/* MDIO interface */
	reg [5:0] mdio_div; // 1/64 divider, 
	output wire MDC;
	assign MDC = mdio_div[5];
	inout wire MDIO;
	reg mdio_reg;
	assign MDIO = (STATE == S_RX_DATA) ? 1'bz : mdio_reg; 

	always @(posedge clk or negedge arst_n) // clock divider
	begin
		if (~arst_n) mdio_div <= 6'b0;
		mdio_div <= mdio_div + 1'b1;
	end

	/* local signal */
	reg [7:0] count_reg;
	reg mode_reg; // 1:write, 0:read
	reg [4:0] phy_id_reg;
	reg [4:0] reg_addr_reg;

	// convert endian, because riscv support little-endian, 
	// but ethernet frame follow big endian
	function [31:0] endian_conv (input [31:0] din);
	begin
		endian_conv[ 7: 0] = din[31:24];
		endian_conv[15: 8] = din[23:16];
		endian_conv[23:16] = din[15: 8];
		endian_conv[31:24] = din[7 : 0];
	end
	endfunction

    always @(posedge MDC or negedge arst_n)
    begin
		if (~arst_n)
			ram_data <= 32'b0;
		else
		begin
			case (STATE)
				S_IDLE:
				begin
					iomem_ready <= 1'b0;
					if (iomem_valid && iomem_addr[31:24] == 8'h07)
					begin
						if (iomem_wstrb[3])
							ram_data[31:24] <= iomem_wdata[31:24];
						if (iomem_wstrb[2])
							ram_data[23:16] <= iomem_wdata[23:16];
						if (iomem_wstrb[1])
							ram_data[15: 8] <= iomem_wdata[15: 8];
						if (iomem_wstrb[0])
							ram_data[ 7: 0] <= iomem_wdata[ 7: 0];
						phy_id_reg   <= iomem_addr[12: 8];
						reg_addr_reg <= iomem_addr[ 4: 0];
						mode_reg   <= |iomem_wstrb; // 1: write, 0: read
					end
				end

				S_PREAMBLE:
				begin
					count_reg <= count_reg + 1'b1;
					mdio_reg <= 1'b1;
					if (count_reg == 8'd32)
						mdio_reg <= 1'b0;
					else if (count_reg == 8'd33)
					begin
						count_reg <= 8'd0;
						mdio_reg <= 1'b1;
						STATE <= S_MODESET;
					end
				end

				S_MODESET:
				begin
					if (count_reg == 8'b0)
					begin
						count_reg <= 8'b1;
						mdio_reg  <= mode_reg;
					end
					else
					begin
						count_reg <= 8'd4;
						mdio_reg <= ~mode_reg;
						STATE <= S_REG_ADDR;
					end
				end

				S_PHY_ID:
				begin
					count_reg <= count_reg - 1'b1; // Start from 4
					mdio_reg <= phy_id_reg[count_reg];
					if (count_reg == 8'd0)
					begin
						count_reg <= 8'd4;
						STATE <= S_REG_ADDR;
					end
				end

				S_REG_ADDR:
				begin
					count_reg <= count_reg - 1'b1; // Start from 4
					mdio_reg  <= reg_addr_reg[count_reg];
					if (count_reg == 8'd0)
					begin
						count_reg <= 8'd15;
						if (mode_reg)
							STATE <= S_TX_DATA;
						else
							STATE <= S_RX_DATA;
					end
				end

				S_RX_DATA:
				begin
					count_reg <= count_reg - 1'b1; // Start from 15
					ram_data  <= {MDIO, ram_data[31:1]}; // TODO : endian conversion
					if (count_reg == 8'd0)
						STATE <= S_END;
				end

				S_TX_DATA:
				begin
					count_reg <= count_reg - 1'b1; // Start from 15
					mdio_reg  <= ram_data[count_reg];
					if (count_reg == 8'd0)
						STATE <= S_END;
				end

				S_END:
				begin
					iomem_ready <= 1'b1;
					iomem_rdata <= endian_conv(ram_data[31:0]); // endian conversion
					count_reg <= 8'b0;
					mdio_reg  <= 1'b0;
					STATE <= S_END;
				end
			endcase
		end
    end
endmodule
