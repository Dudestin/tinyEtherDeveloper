module MDIO (
    clk,
    arst_n,

    mdc,
    mdio,
    
    /* picosoc IO interface */
    iomem_valid,
    iomem_ready,
    iomem_wstrb,
    iomem_addr,
    iomem_wdata,
    iomem_rdata
);

input         iomem_valid;
output  reg   iomem_ready;
input  [ 3:0] iomem_wstrb;
input  [31:0] iomem_addr;
input  [31:0] iomem_wdata;
output reg [31:0] iomem_rdata;

    always @(posedge clk or negedge arst_n)
    begin

    end

endmodule
