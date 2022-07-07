/* random 32bit sequence generator */
/* Algorithm : Xorshift , Period : 2^32 - 1 */
/* Refer : https://ja.wikipedia.org/wiki/Xorshift */

module xorshift( 
	input  wire clk,
	input  wire arst_n,
	output reg [31:0] rand
);

reg [31:0] y;

always @ (posedge clk or negedge arst_n)
begin
    if (arst_n == 1'b0)
    begin
        y <= 32'd2463534242;
        rand <= 32'd0;
    end
    else
    begin
        y <= y ^ (y << 13) ^ (y >> 17) ^ (y << 5);
        rand <= y;
    end
end

endmodule