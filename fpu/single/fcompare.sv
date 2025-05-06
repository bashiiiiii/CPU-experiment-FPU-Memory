`default_nettype none

module feq
    ( input wire [31:0] x1,
      input wire [31:0] x2,
      output wire y);
      wire [7:0] e1;
      wire [7:0] e2;
      assign e1 = x1[30:23];
      assign e2 = x2[30:23];
      
      assign y = (|e1 || |e2) ? (x1 === x2) : 1'b1;

endmodule

module flt
    ( input wire [31:0] x1,
      input wire [31:0] x2,
      output wire y);
      wire s1;
      wire [7:0] e1;
      wire [22:0] m1;
      wire s2;
      wire [7:0] e2;
      wire [22:0] m2;
      assign {s1, e1, m1} = x1;
      assign {s2, e2, m2} = x2;
      
      assign y = (|e1 || |e2) ? 
                 ((s1 && ~s2) ? 1'b1 : 
                  (~s1 && s2) ? 1'b0 :
                  (s1 && s2) ?  (e1 === e2 ? m1 > m2 : e1 > e2) : (e1 === e2 ? m1 < m2 : e1 < e2)) : 
                 1'b0;
endmodule

module fle
    ( input wire [31:0] x1,
      input wire [31:0] x2,
      output wire y);
      wire s1;
      wire [7:0] e1;
      wire [22:0] m1;
      wire s2;
      wire [7:0] e2;
      wire [22:0] m2;
      assign {s1, e1, m1} = x1;
      assign {s2, e2, m2} = x2;
      
      assign y = (|e1 || |e2) ? 
                 ((s1 && ~s2) ? 1'b1 : 
                  (~s1 && s2) ? 1'b0 :
                  (s1 && s2) ?  (e1 === e2 ? m1 >= m2 : e1 > e2) : (e1 === e2 ? m1 <= m2 : e1 < e2)): 
                 1'b1;
endmodule
`default_nettype wire