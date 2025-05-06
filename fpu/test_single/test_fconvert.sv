`timescale 1ns / 100ps
`default_nettype none

module test_fconvert();
   wire [31:0] x,y1,y2;
   logic [31:0] xi,yi,yi1;
   shortreal    fx,fy,f,a,a1,f1;
   shortreal    fmax, fmin, fhalf;
   int i;
   int xint, y, y_ans;
   int m,n;
   bit dum;
   logic [31:0] fybit;

   assign x = xi;
   
   fcvtws u1(x,y1);
   fcvtsw u2(x,y2);
   initial begin
      $display("start of checking module fconvert");
      xi = 32'b0;
      #1;
      if(y1 !== 32'b0) begin
        $display("y1 = %d %b\n", y1, y1);
      end
      #1;
      xi = {1'b1,31'b0};
      if(y1 !== 32'b0) begin
        $display("y1 = %d %b\n", y1, y1);
      end
      for (i = 0; i < 10000; i++) begin
        #1;
        xi = $urandom();
        fx = $bitstoshortreal(xi);
        fmax = $bitstoshortreal({1'b0,8'd158, 23'b0});
        fmin = $bitstoshortreal({1'b1,8'd158, 23'b0});
        y = $rtoi(fx);
        f = $itor(y);
        #1;
        if((fx > 0) && (fx-f >= 0.5)) begin
          y = y+1;
        end else if ((fx < 0) && (f-fx >= 0.5)) begin
          y = y-1;
        end
        y_ans = y1;
        #1;
        if ((fx < fmax) && (fx > fmin) && (xi[30:23] !== 8'b0) && (y !== y1)) begin
            $display("x = %e %b %b %b, %3d", fx, x[31], x[30:23], x[22:0], x[30:23]);
            $display("y = %d %b", y,y);
            $display("y1 = %d %b\n", y_ans, y_ans);
        end
      end
      #1;
      xi = 32'b0;
      #1;
      if(y2 != 32'b0) begin
        $display("x = %d %b", xi, xi);
      end
      for (i = 0; i < 10000000; i++) begin
        //要修正
        #1;
        xi = $urandom();
        xint = xi;
        f = $itor(xint);
        #1;
        a = $bitstoshortreal(y2);
        yi = $shortrealtobits(f);
        f1 = $bitstoshortreal(yi);
        yi1 = yi+32'b1;
        a1 = $bitstoshortreal(yi1);
        m = $rtoi(f1);
        n = $rtoi(a1);
        #1;
        if (((n-xint) != 0) && ((xint > 0) && ((n-xint) <= (xint-m))) || (((xint-n) != 0) && (xint < 0) && ((xint-n) <= (m-xint)))) begin
          yi = yi1;
          f = a1;
        end
        #1;
        if (yi !== y2) begin
            $display("x = %d %b", xint, xint);
            $display("n-xint = %d", n-xint);
            $display("xint-m = %d", xint-m);
            $display("f = %e %b %b %b", f, yi[31],yi[30:23],yi[22:0]);
            $display("a = %e %b %b %b\n", a, y2[31],y2[30:23],y2[22:0]);
        end
      end
      $display("end of checking module fconvert");
      $finish;
   end
endmodule

`default_nettype wire
