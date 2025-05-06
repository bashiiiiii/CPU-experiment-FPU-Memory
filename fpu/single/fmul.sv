`default_nettype none

module fmul
    ( input wire [31:0] x1,
      input wire [31:0] x2,
      output wire [31:0] y);
      wire s1;
      wire [7:0] e1;
      wire [22:0] m1;
      wire s2;
      wire [7:0] e2;
      wire [22:0] m2;
      assign {s1, e1, m1} = x1;
      assign {s2, e2, m2} = x2;
      wire [12:0] h1, h2;
      wire [10:0] l1, l2;
      assign h1 = {1'b1, m1[22:11]};
      assign h2 = {1'b1, m2[22:11]};
      assign l1 = m1[10:0];
      assign l2 = m2[10:0];
      wire [25:0] hh, hl, lh;
      assign hh = h1*h2;
      assign hl = h1*l2;
      assign lh = l1*h2;
      wire [25:0] my1;
      assign my1 = hh + (hl >> 11) + (lh >> 11) + 26'd2;
      wire [8:0] ey1;
      assign ey1 = {1'b0, e1} + {1'b0, e2} + 9'd129;
      wire [8:0] ey2;
      assign ey2 = my1[25] ? (ey1 + 9'b1) : ey1;
      wire [7:0] ey;
      assign ey = (ey2[8] && (|e1) && (|e2)) ? ey2[7:0] : 8'b0;
      wire sy;
      assign sy = s1 ^ s2;
      wire [22:0] my;
      assign my = (|ey) ? (my1[25] ? my1[24:2] : my1[23:1]) : 23'b0;
      assign y = {sy, ey, my};
endmodule 
`default_nettype wire