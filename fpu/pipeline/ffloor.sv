`default_nettype none
//ffloor
module ffloor
    ( input wire [31:0] x,
      output wire [31:0] y,
      input wire clk,
      input wire rstn);
      wire s;
      wire [7:0] e;
      wire [22:0] m;
      assign {s, e, m} = x;
      wire [31:0] m1;
      assign m1 = {1'b1, m, 8'b0};
      wire [31:0] m2;
      assign m2 = m1 >> (8'd157-e);
      reg [31:0] m2_reg;
      reg s_reg;
      always_ff @ (posedge clk) begin
        m2_reg <= m2;
        s_reg <= s;
      end
      wire [31:0] m3;
      assign m3 = m2_reg >> 1;
      assign y = s_reg ? -m3 : m3;
endmodule
`default_nettype wire