`timescale 1ns / 100ps
`default_nettype none

module test_fmul();
   wire [31:0] x1,x2,y;
   logic [31:0] x1i,x2i;
   shortreal    fx1,fx2,fy;
   int          i,j,k,it,jt;
   bit [22:0]   m1,m2;
   bit [9:0]    dum1,dum2;
   logic [31:0] fybit;
   int          s1,s2;
   logic [23:0] dy;
   bit [22:0] tm;

   assign x1 = x1i;
   assign x2 = x2i;
   
   fmul u1(x1,x2,y);

   initial begin

      $display("start of checking module fmul");

      for (i = 0; i < 10000000; i++) begin
        #1;
        x1i = $urandom();
        x2i = $urandom();
        fx1 = $bitstoshortreal(x1i);
        fx2 = $bitstoshortreal(x2i);
        fy = fx1 * fx2;
        fybit = $shortrealtobits(fy);
        #1;
        if ((x1i[30:23] !== 8'b0) && (x2i[30:23] !== 8'b0) && (y !== fybit) && (fybit[30:23] !== 8'd255) && (fybit[30:23] !== 8'd0) && (y+32'b1 !== fybit) && (y-32'b1 !== fybit)) begin
            $display("x1 = %e %b %b %b, %3d", fx1, x1[31], x1[30:23], x1[22:0], x1[30:23]);
            $display("x2 = %e %b %b %b, %3d", fx2, x2[31], x2[30:23], x2[22:0], x2[30:23]);
            $display("%e %b,%b,%b", fy, fybit[31], fybit[30:23], fybit[22:0]);
            $display("%e %b,%b,%b\n", $bitstoshortreal(y), y[31], y[30:23], y[22:0]);
        end
      end
      for (i = 0; i < 10000; i++) begin
        #1;
        x1i = $urandom();
        x2i = 32'b0;
        fx1 = $bitstoshortreal(x1i);
        fx2 = $bitstoshortreal(x2i);
        fy = fx1 * fx2;
        fybit = $shortrealtobits(fy);
        #1;
        if (y[30:0] !== 31'b0) begin
            $display("x1 = %e %b %b %b, %3d", fx1, x1[31], x1[30:23], x1[22:0], x1[30:23]);
            $display("x2 = %e %b %b %b, %3d", fx2, x2[31], x2[30:23], x2[22:0], x2[30:23]);
            $display("%e %b,%b,%b", fy, fybit[31], fybit[30:23], fybit[22:0]);
            $display("%e %b,%b,%b\n", $bitstoshortreal(y), y[31], y[30:23], y[22:0]);
        end
      end
      for (i = 0; i < 10000; i++) begin
        #1;
        x1i = $urandom();
        x2i = {1'b1,31'b0};
        fx1 = $bitstoshortreal(x1i);
        fx2 = $bitstoshortreal(x2i);
        fy = fx1 * fx2;
        fybit = $shortrealtobits(fy);
        #1;
        if (y[30:0] !== 31'b0) begin
            $display("x1 = %e %b %b %b, %3d", fx1, x1[31], x1[30:23], x1[22:0], x1[30:23]);
            $display("x2 = %e %b %b %b, %3d", fx2, x2[31], x2[30:23], x2[22:0], x2[30:23]);
            $display("%e %b,%b,%b", fy, fybit[31], fybit[30:23], fybit[22:0]);
            $display("%e %b,%b,%b\n", $bitstoshortreal(y), y[31], y[30:23], y[22:0]);
        end
      end
      #1;
      x1i = {1'b1,31'b0};
      x2i = {1'b1,31'b0};
      fx1 = $bitstoshortreal(x1i);
      fx2 = $bitstoshortreal(x2i);
      fy = fx1 * fx2;
      fybit = $shortrealtobits(fy);
      #1;
      if (y[30:0] !== 31'b0) begin
          $display("x1 = %e %b %b %b, %3d", fx1, x1[31], x1[30:23], x1[22:0], x1[30:23]);
          $display("x2 = %e %b %b %b, %3d", fx2, x2[31], x2[30:23], x2[22:0], x2[30:23]);
          $display("%e %b,%b,%b", fy, fybit[31], fybit[30:23], fybit[22:0]);
          $display("%e %b,%b,%b\n", $bitstoshortreal(y), y[31], y[30:23], y[22:0]);
      end
      $display("end of checking module fmul");
      $finish;
   end
endmodule

`default_nettype wire
