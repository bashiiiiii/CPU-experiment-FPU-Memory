`default_nettype none
module fhalf
    ( input wire [31:0] x,
      output wire [31:0] y,
      input wire clk,
      input wire rstn);
      wire s;
      wire [7:0] e;
      wire [22:0] m;
      assign {s, e, m} = x;
      assign y = (|e) ? {s,e-8'b1,m} : x;
endmodule
`default_nettype wire