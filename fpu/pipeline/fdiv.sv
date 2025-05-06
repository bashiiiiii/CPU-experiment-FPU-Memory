`default_nettype none
// 4 stage
module fdiv
    ( input wire [31:0] x1,
      input wire [31:0] x2,
      output reg [31:0] y,
      input wire clk,
      input wire rstn);

      (* ram_style = "BLOCK" *) reg [35:0] mem [1023:0];
      initial begin
        $readmemb("inv_table.txt", mem);
      end
      wire s1;
      wire [7:0] e1;
      wire [22:0] m1;
      wire s2;
      wire [7:0] e2;
      wire [22:0] m2;
      assign {s1, e1, m1} = x1;
      assign {s2, e2, m2} = x2;
      wire [9:0] index;
      wire [12:0] rest;
      assign {index, rest} = m2;
      reg [22:0] intercept;
      reg [12:0] slope;
      reg [12:0] rest_reg;
      reg [22:0] m1_reg1;
      reg [7:0] e1_reg1, e2_reg1;
      reg s1_reg1, s2_reg1;
      always_ff @ (posedge clk) begin
        {intercept, slope} <= mem[index];
        rest_reg <= rest;
        m1_reg1 <= m1;
        e1_reg1 <= e1;
        e2_reg1 <= e2;
        s1_reg1 <= s1;
        s2_reg1 <= s2;
      end
      
      wire [25:0] xslope;
      assign xslope = rest_reg * slope;
      wire [22:0] inv;
      assign inv = intercept - {9'b0, xslope[25:12]};

      reg [22:0] inv_reg, m1_reg2;
      reg [7:0] e1_reg2, e2_reg2;
      reg s1_reg2, s2_reg2;
      always_ff @ (posedge clk) begin
        inv_reg <= inv;
        m1_reg2 <= m1_reg1;
        e1_reg2 <= e1_reg1;
        e2_reg2 <= e2_reg1;
        s1_reg2 <= s1_reg1;
        s2_reg2 <= s2_reg1;
      end
      
      wire [8:0] e2inv;
      assign e2inv = 9'd253 - {1'b0,e2_reg2};
      wire [12:0] h1, h2;
      wire [10:0] l1, l2;
      assign h1 = {1'b1, m1_reg2[22:11]};
      assign h2 = {1'b1, inv_reg[22:11]};
      assign l1 = m1_reg2[10:0];
      assign l2 = inv_reg[10:0];
      wire [25:0] hh, hl, lh;
      assign hh = h1*h2;
      assign hl = h1*l2;
      assign lh = l1*h2;

      reg [25:0] hh_reg, hl_reg, lh_reg;
      reg [7:0] e1_reg3;
      reg [8:0] e2inv_reg;
      reg s1_reg3, s2_reg3;
      always_ff @ (posedge clk) begin
        hh_reg <= hh;
        hl_reg <= hl;
        lh_reg <= lh;
        e1_reg3 <= e1_reg2;
        e2inv_reg <= e2inv;
        s1_reg3 <= s1_reg2;
        s2_reg3 <= s2_reg2;
      end

      wire [25:0] my1;
      assign my1 = hh_reg + (hl_reg >> 11) + (lh_reg >> 11) + 26'd2;
      wire [8:0] ey1;
      assign ey1 = {1'b0, e1_reg3} + e2inv_reg + 9'd129;
      wire [8:0] ey2;
      assign ey2 = my1[25] ? (ey1 + 9'b1) : ey1;
      wire [7:0] ey;
      assign ey = (ey2[8] && (|e1_reg3)) ? ey2[7:0] : 8'b0;
      wire sy;
      assign sy = s1_reg3 ^ s2_reg3;
      wire [22:0] my;
      assign my = (|ey) ? (my1[25] ? my1[24:2] : my1[23:1]) : 23'b0;
      assign y = {sy, ey, my};
endmodule
`default_nettype wire