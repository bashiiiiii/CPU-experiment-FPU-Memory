`default_nettype none

module fsqrt
    ( input wire [31:0] x,
      output wire [31:0] y);
      wire s;
      wire [7:0] e;
      wire [22:0] m;
      assign {s, e, m} = x;

      (* ram_style = "BLOCK" *) reg [35:0] mem [1023:0];
      initial begin
        $readmemb("sqrt_table.txt", mem);
      end

      wire [8:0] e1;
      assign e1 = {1'b0, e} + 9'd127; 
      wire [9:0] index;
      wire [12:0] rest;
      assign index = {e1[0], m[22:14]};
      assign rest = m[13:1];
      wire [22:0] intercept;
      wire [12:0] slope;
      assign {intercept, slope} = mem[index];
      wire [25:0] xslope;
      assign xslope = rest * slope;
      wire [22:0] sqrt_m;
      assign sqrt_m = e1[0] ? (intercept + {9'b0, xslope[25:12]}) : (intercept + {10'b0, xslope[25:13]});
      assign y = (|e) ? {1'b0, e1[8:1], sqrt_m} : 32'b0;
endmodule
`default_nettype wire