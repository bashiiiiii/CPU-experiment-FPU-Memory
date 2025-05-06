`default_nettype none
// 2 stage
module fsqrt
    ( input wire [31:0] x,
      output reg [31:0] y,
      input wire clk,
      input wire rstn);
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
      reg [22:0] intercept;
      reg [12:0] slope;
      reg [12:0] rest_reg;
      reg [7:0] e_reg;
      reg [8:0] e1_reg;
      always_ff @ (posedge clk) begin
        {intercept, slope} <= mem[index];
        rest_reg <= rest;
        e_reg <= e;
        e1_reg <= e1;
      end
      wire [25:0] xslope;
      assign xslope = rest_reg * slope;
      wire [22:0] sqrt_m;
      assign sqrt_m = e1_reg[0] ? (intercept + {9'b0, xslope[25:12]}) : (intercept + {10'b0, xslope[25:13]});
      assign y = (|e_reg) ? {1'b0, e1_reg[8:1], sqrt_m} : 32'b0;
endmodule
`default_nettype wire