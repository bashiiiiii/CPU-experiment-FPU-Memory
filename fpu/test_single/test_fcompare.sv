`timescale 1ns / 100ps
`default_nettype none

module test_fcompare();
   wire [31:0] x1,x2;
   wire y1, y2, y3;
   logic [31:0] x1i,x2i;
   shortreal    fx1,fx2;
   int          i,j,k,it,jt;
   bit [22:0]   m1,m2;
   bit [9:0]    dum1,dum2;
   logic [31:0] fybit;
   int          s1,s2;
   logic [23:0] dy;
   bit [22:0] tm;

   assign x1 = x1i;
   assign x2 = x2i;
   
   feq u1(x1,x2,y1);
   flt u2(x1,x2,y2);
   fle u3(x1,x2,y3);

   initial begin

      $display("start of checking module fcompare");

      for (i = 0; i < 10000000; i++) begin
        #1;
        x1i = $urandom();
        x2i = $urandom();
        fx1 = $bitstoshortreal(x1i);
        fx2 = $bitstoshortreal(x2i);
        #1;
        if ((x1i[30:23] !== 8'd255) && (x2i[30:23] !== 8'd255) && (x1i[30:23] !== 8'b0 || x1i[30:0] == 31'b0) && (x2i[30:23] !== 8'b0 || x2i[30:0] == 31'b0) && 
        ((y1 != (fx1 == fx2)) || (y2 != (fx1 < fx2)) || (y3 != (fx1 <= fx2)))) begin
            $display("x1 = %e %b %b %b, %3d", fx1, x1[31], x1[30:23], x1[22:0], x1[30:23]);
            $display("x2 = %e %b %b %b, %3d", fx2, x2[31], x2[30:23], x2[22:0], x2[30:23]);
        end
      end
      x1i = 32'b0;
      x2i = 32'b0;
      if ((x1i[30:23] !== 8'd255) && (x2i[30:23] !== 8'd255) && (x1i[30:23] !== 8'b0 || x1i[30:0] == 31'b0) && (x2i[30:23] !== 8'b0 || x2i[30:0] == 31'b0) && 
        ((y1 != (fx1 == fx2)) || (y2 != (fx1 < fx2)) || (y3 != (fx1 <= fx2)))) begin
            $display("x1 = %e %b %b %b, %3d", fx1, x1[31], x1[30:23], x1[22:0], x1[30:23]);
            $display("x2 = %e %b %b %b, %3d", fx2, x2[31], x2[30:23], x2[22:0], x2[30:23]);
      end
      $display("end of checking module fcompare");
      $finish;
   end
endmodule

`default_nettype wire
