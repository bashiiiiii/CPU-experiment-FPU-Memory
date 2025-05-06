`default_nettype none
//ftoi
module fcvtws
    ( input wire [31:0] x,
      output wire [31:0] y);
      wire s;
      wire [7:0] e;
      wire [22:0] m;
      assign {s, e, m} = x;
      wire [31:0] m1;
      assign m1 = {1'b1, m, 8'b0};
      wire [31:0] m2;
      assign m2 = m1 >> (8'd157-e);
      wire [31:0] m3;
      assign m3 = (m2 + 32'b1) >> 1;
      assign y = s ? -m3 : m3;
endmodule

//itof
module fcvtsw
    ( input wire [31:0] x,
      output wire [31:0] y);
      wire [31:0] absx;
      assign absx = x[31] ? -x : x;
      wire [7:0] e1;
      wire [25:0] m1;
      assign {e1, m1} = absx[30] ? {8'd157, 1'b0, absx[30:6]} :
                        absx[29] ? {8'd156, 1'b0, absx[29:5]} :
                        absx[28] ? {8'd155, 1'b0, absx[28:4]} :
                        absx[27] ? {8'd154, 1'b0, absx[27:3]} :
                        absx[26] ? {8'd153, 1'b0, absx[26:2]} :
                        absx[25] ? {8'd152, 1'b0, absx[25:1]} :
                        absx[24] ? {8'd151, 1'b0, absx[24:0]} :
                        absx[23] ? {8'd150, 1'b0, absx[23:0], 1'b0} :
                        absx[22] ? {8'd149, 1'b0, absx[22:0], 2'b0} :
                        absx[21] ? {8'd148, 1'b0, absx[21:0], 3'b0} :
                        absx[20] ? {8'd147, 1'b0, absx[20:0], 4'b0} :
                        absx[19] ? {8'd146, 1'b0, absx[19:0], 5'b0} :
                        absx[18] ? {8'd145, 1'b0, absx[18:0], 6'b0} :
                        absx[17] ? {8'd144, 1'b0, absx[17:0], 7'b0} :
                        absx[16] ? {8'd143, 1'b0, absx[16:0], 8'b0} :
                        absx[15] ? {8'd142, 1'b0, absx[15:0], 9'b0} :
                        absx[14] ? {8'd141, 1'b0, absx[14:0], 10'b0} :
                        absx[13] ? {8'd140, 1'b0, absx[13:0], 11'b0} :
                        absx[12] ? {8'd139, 1'b0, absx[12:0], 12'b0} :
                        absx[11] ? {8'd138, 1'b0, absx[11:0], 13'b0} :
                        absx[10] ? {8'd137, 1'b0, absx[10:0], 14'b0} :
                        absx[9] ? {8'd136, 1'b0, absx[9:0], 15'b0} :
                        absx[8] ? {8'd135, 1'b0, absx[8:0], 16'b0} :
                        absx[7] ? {8'd134, 1'b0, absx[7:0], 17'b0} :
                        absx[6] ? {8'd133, 1'b0, absx[6:0], 18'b0} :
                        absx[5] ? {8'd132, 1'b0, absx[5:0], 19'b0} :
                        absx[4] ? {8'd131, 1'b0, absx[4:0], 20'b0} :
                        absx[3] ? {8'd130, 1'b0, absx[3:0], 21'b0} :
                        absx[2] ? {8'd129, 1'b0, absx[2:0], 22'b0} :
                        absx[1] ? {8'd128, 1'b0, absx[1:0], 23'b0} :
                        absx[0] ? {8'd127, 1'b0, absx[0], 24'b0} : 34'b0;
      wire [25:0] m2;
      assign m2 = m1 + 25'b1;
      assign y = m2[25] ? {x[31], (e1+8'b1), 23'b0} : {x[31], e1, m2[23:1]};
endmodule
`default_nettype wire