`default_nettype none
//ftoi
// 1 stage
module fcvtws
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
      assign m3 = (m2_reg + 32'b1) >> 1;
      assign y = s_reg ? -m3 : m3;
endmodule

//itof
// 1 stage
module fcvtsw
    ( input wire [31:0] x,
      output wire [31:0] y,
      input wire clk,
      input wire rstn);
      wire [31:0] absx;
      assign absx = x[31] ? -x : x;
      wire [7:0] e1, e1_2;
      wire [25:0] m1, m1_2;
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
                        absx[16] ? {8'd143, 1'b0, absx[16:0], 8'b0} : 0;
      reg [7:0] e1_reg;
      reg [25:0] m1_reg;
      reg [31:0] absx_reg;
      reg hit, x_sign;
      always_ff @ (posedge clk) begin
        e1_reg <= e1;
        m1_reg <= m1;
        absx_reg <= absx;
        hit <= |absx[30:16];
        x_sign <= x[31];
      end                
      assign {e1_2, m1_2} = hit ? {e1_reg, m1_reg} :
                            absx_reg[15] ? {8'd142, 1'b0, absx_reg[15:0], 9'b0} :
                            absx_reg[14] ? {8'd141, 1'b0, absx_reg[14:0], 10'b0} :
                            absx_reg[13] ? {8'd140, 1'b0, absx_reg[13:0], 11'b0} :
                            absx_reg[12] ? {8'd139, 1'b0, absx_reg[12:0], 12'b0} :
                            absx_reg[11] ? {8'd138, 1'b0, absx_reg[11:0], 13'b0} :
                            absx_reg[10] ? {8'd137, 1'b0, absx_reg[10:0], 14'b0} :
                            absx_reg[9] ? {8'd136, 1'b0, absx_reg[9:0], 15'b0} :
                            absx_reg[8] ? {8'd135, 1'b0, absx_reg[8:0], 16'b0} :
                            absx_reg[7] ? {8'd134, 1'b0, absx_reg[7:0], 17'b0} :
                            absx_reg[6] ? {8'd133, 1'b0, absx_reg[6:0], 18'b0} :
                            absx_reg[5] ? {8'd132, 1'b0, absx_reg[5:0], 19'b0} :
                            absx_reg[4] ? {8'd131, 1'b0, absx_reg[4:0], 20'b0} :
                            absx_reg[3] ? {8'd130, 1'b0, absx_reg[3:0], 21'b0} :
                            absx_reg[2] ? {8'd129, 1'b0, absx_reg[2:0], 22'b0} :
                            absx_reg[1] ? {8'd128, 1'b0, absx_reg[1:0], 23'b0} :
                            absx_reg[0] ? {8'd127, 1'b0, absx_reg[0], 24'b0} : 34'b0;
      wire [25:0] m2;
      assign m2 = m1_2 + 25'b1;
      assign y = m2[25] ? {x_sign, (e1_2+8'b1), 23'b0} : {x_sign, e1_2, m2[23:1]};
endmodule
`default_nettype wire