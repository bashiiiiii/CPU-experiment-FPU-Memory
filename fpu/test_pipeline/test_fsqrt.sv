`timescale 1ns / 100ps
`default_nettype none

module test_fsqrt();
   wire [31:0] x,y;
   logic [31:0] xi;
   shortreal    fx,fy;
   int i;
   bit dum;
   bit [31:0] m;
   logic [31:0] fybit;
   logic clk,rstn;

   assign x = xi;
   
   fsqrt u1(x,y,clk,rstn);

   initial begin

      $display("start of checking module fsqrt");
      #1;
      rstn = 1;
      clk = 0;
      for (i = 0; i < 100000; i++) begin
        #1;
        m = $urandom();
        xi = {1'b0, m[31:1]};
        fx = $bitstoshortreal(xi);
        fy = $sqrt(fx);
        fybit = $shortrealtobits(fy);
        #1;
        clk = 0;
        #1;
        clk = 1;
        #1; 
        clk = 0;
        #1;
        clk = 1;
        if ((xi[30:23] !== 8'b0) && (y !== fybit) && (fybit[30:23] !== 8'd255) && (fybit[30:23] !== 8'd0) && 
        ((y-fybit) > 32'd4) && ((fybit-y) > 32'd4)) begin
            $display("x = %e %b %b %b, %3d", fx, x[31], x[30:23], x[22:0], x[30:23]);
            $display("%e %b,%b,%b", fy, fybit[31], fybit[30:23], fybit[22:0]);
            $display("%e %b,%b,%b\n", $bitstoshortreal(y), y[31], y[30:23], y[22:0]);
        end
      end
      #1;
      xi = 32'b0;
      fx = $bitstoshortreal(xi);
      fy = $sqrt(fx);
      fybit = $shortrealtobits(fy);
      #1;
      clk = 0;
      #1;
      clk = 1;
      #1; 
      clk = 0;
      #1;
      clk = 1;
      if (y !== 32'b0) begin
          $display("x = %e %b %b %b, %3d", fx, x[31], x[30:23], x[22:0], x[30:23]);
          $display("%e %b,%b,%b", fy, fybit[31], fybit[30:23], fybit[22:0]);
          $display("%e %b,%b,%b\n", $bitstoshortreal(y), y[31], y[30:23], y[22:0]);
    end
      $display("end of checking module fsqrt");
      $finish;
   end
endmodule

`default_nettype wire
