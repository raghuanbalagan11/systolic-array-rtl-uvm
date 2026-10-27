interface systolic_if(input logic clk);
  logic rst_n;
  logic load_weight;
  logic signed [7:0] weight_in [4][4];
  logic signed [7:0] a_in [4];
  logic signed [31:0] psum_in [4];
  logic signed [31:0] psum_out [4];
endinterface
