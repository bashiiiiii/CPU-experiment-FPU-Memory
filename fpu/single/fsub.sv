`default_nettype none

module fsub
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
      assign s2 = ~x2[31];
      assign {e2, m2} = x2[30:0];
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
      assign tde =  (~ce) ? td1[7:0] : td2[7:0];
      wire [4:0] de;
      assign de = (tde > 8'd31) ? 5'd31 : tde[4:0];
      wire sel;
      assign sel = (|de) ? ce : ((m1a > m2a) ? 1'b0 :1'b1);
      wire [24:0] ms;
      wire [24:0] mi;
      wire [7:0] es;
      wire [7:0] ei;
      wire ss;
      assign ms = sel ? m2a : m1a;
      assign mi = sel ? m1a : m2a;
      assign es = sel ? e2 : e1;
      assign ei = sel ? e1 : e2;
      assign ss = sel ? s2 : s1;
      wire [55:0] mie;
      assign mie = {mi,31'b0};
      wire [55:0] mia;
      assign mia = (mie >> de);
      wire tstck;
      assign tstck = |(mia[28:0]);
      wire [26:0] mye;
      assign mye = (s1 === s2) ? ({ms,2'b0} + mia[55:29]) : ({ms,2'b0} - (mia[55:29]));
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
      wire [26:0] myf;
      wire [7:0] eyr;
      assign myf = (~(eyf[8]) && (|eyf)) ? (myd << se) : 27'b0;
      assign eyr = (~(eyf[8]) && (|eyf)) ? eyf[7:0] : 8'b0;
      wire [24:0] myr;
      assign myr = (myf[1] && ~myf[0] && ~stck && myf[2]) ||
                   (myf[1] && ~myf[0] && (s1 === s2) && stck) ||
                   (myf[1] && myf[0]) ? 
                   (myf[26:2] + 25'b1) : myf[26:2];
      wire [7:0] ey;
      wire [22:0] my;
      assign ey = myr[24] ? eyr + 8'b1 : (|(myr[23:0]) ? eyr : 8'b0);
      assign my = myr[24] ? 23'b0 : myr[22:0];
      assign y = {ss,ey,my};
endmodule 
`default_nettype wire