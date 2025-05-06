`default_nettype none
// 3 stage
module fadd
    ( input wire [31:0] x1,
      input wire [31:0] x2,
      output reg [31:0] y,
      input wire clk,
      input wire rstn);
      wire s1;
      wire [7:0] e1;
      wire [22:0] m1;
      wire s2;
      wire [7:0] e2;
      wire [22:0] m2;
      assign {s1, e1, m1} = x1;
      assign {s2, e2, m2} = x2;
      wire [24:0] m1a;
      wire [24:0] m2a;
      assign m1a = (|e1) ? {2'b01,m1} : {2'b00,m1};
      assign m2a = (|e2) ? {2'b01,m2} : {2'b00,m2};
      wire [8:0] td1;
      assign td1 = {1'b0, e1}-{1'b0, e2};
      wire [8:0] td2;
      assign td2 = {1'b0, e2}-{1'b0, e1};
      wire ce;
      assign ce = td1[8];
      wire [7:0] tde;
      assign tde =  ce ? td2[7:0] : td1[7:0];
      wire [4:0] de;
      assign de = (tde > 8'd31) ? 5'd31 : tde[4:0];

      reg [24:0] m1a_reg, m2a_reg;
      reg s1_reg, s2_reg, sel_reg;
      reg [7:0] e1_reg, e2_reg;
      reg [4:0] de_reg;
      reg [7:0] tde_reg;
      always_ff @ (posedge clk) begin
        m1a_reg <= m1a;
        m2a_reg <= m2a;
        e2_reg <= e2;
        e1_reg <= e1;
        s1_reg <= s1;
        s2_reg <= s2;
        de_reg <= de;
        tde_reg <= tde;
        sel_reg <= |tde[7:0] ? ce : m1a <= m2a;
      end

      
      wire [55:0] mia1, mia2;
      assign mia1 = |tde_reg[7:5] ? {31'b0, m1a_reg} : ({m1a_reg,31'b0} >> tde_reg[4:0]);
      assign mia2 = |tde_reg[7:5] ? {31'b0, m2a_reg} : ({m2a_reg,31'b0} >> tde_reg[4:0]);
      wire [24:0] ms;
      wire [24:0] mi;
      wire [7:0] es;
      wire [7:0] ei;
      wire ss;
      assign ms = sel_reg ? m2a_reg : m1a_reg;
      assign mi = sel_reg ? m1a_reg : m2a_reg;
      assign es = sel_reg ? e2_reg : e1_reg;
      assign ei = sel_reg ? e1_reg : e2_reg;
      assign ss = sel_reg ? s2_reg : s1_reg;
      wire [55:0] mia;
      assign mia = sel_reg ? mia1 : mia2;

      wire tstck;
      assign tstck = |(mia[28:0]);
      wire [26:0] mye;
      assign mye = (s1_reg === s2_reg) ? ({ms,2'b0} + mia[55:29]) : ({ms,2'b0} - (mia[55:29]));
      wire [7:0] eyd;
      wire [26:0] myd;
      wire stck;
      assign eyd = mye[26] ? (es + 8'b1) : es;
      assign myd = mye[26] ? (mye >> 1'b1) : mye;
      assign stck = mye[26] ? (tstck || mye[0]) : tstck;
      wire [4:0] se;
      assign se = myd[25] ? {5'd0} :
                  myd[24] ? {5'd1} :
                  myd[23] ? {5'd2} :
                  myd[22] ? {5'd3} :
                  myd[21] ? {5'd4} :
                  myd[20] ? {5'd5} :
                  myd[19] ? {5'd6} :
                  myd[18] ? {5'd7} :
                  myd[17] ? {5'd8} :
                  myd[16] ? {5'd9} :
                  myd[15] ? {5'd10} :
                  myd[14] ? {5'd11} :
                  myd[13] ? {5'd12} :
                  myd[12] ? {5'd13} :
                  myd[11] ? {5'd14} :
                  myd[10] ? {5'd15} :
                  myd[9] ? {5'd16} :
                  myd[8] ? {5'd17} :
                  myd[7] ? {5'd18} :
                  myd[6] ? {5'd19} :
                  myd[5] ? {5'd20} :
                  myd[4] ? {5'd21} :
                  myd[3] ? {5'd22} :
                  myd[2] ? {5'd23} :
                  myd[1] ? {5'd24} :
                  myd[0] ? {5'd25} :
                  {5'd26};
      wire [8:0] eyf;
      assign eyf = {1'b0,eyd}-{4'b0,se};

      reg [8:0] eyf_reg;
      reg [26:0] myd_reg;
      reg [4:0] se_reg;
      reg stck_reg, s1_reg2, s2_reg2, ss_reg2;
      always_ff @ (posedge clk) begin
        eyf_reg <= eyf;
        myd_reg <= myd;
        se_reg <= se;
        stck_reg <= stck;
        s1_reg2 <= s1_reg;
        s2_reg2 <= s2_reg;
        ss_reg2 <= ss;
      end

      wire [26:0] myf;
      wire [7:0] eyr;
      assign myf = (~(eyf_reg[8]) && (|eyf_reg)) ? (myd_reg << se_reg) : 27'b0;
      assign eyr = (~(eyf_reg[8]) && (|eyf_reg)) ? eyf_reg[7:0] : 8'b0;
      wire [24:0] myr;
      assign myr = (myf[1] && ~myf[0] && ~stck_reg && myf[2]) ||
                   (myf[1] && ~myf[0] && (s1_reg2 === s2_reg2) && stck_reg) ||
                   (myf[1] && myf[0]) ? 
                   (myf[26:2] + 25'b1) : myf[26:2];
      wire [7:0] ey;
      wire [22:0] my;
      assign ey = myr[24] ? eyr + 8'b1 : (|(myr[23:0]) ? eyr : 8'b0);
      assign my = myr[24] ? 23'b0 : myr[22:0];
      assign y = {ss_reg2,ey,my};
endmodule 
`default_nettype wire