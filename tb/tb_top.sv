`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import systolic_uvm_pkg::*;
  `include "uvm_macros.svh"

  logic clk = 0;
  always #5 clk = ~clk;  // 100 MHz

  systolic_if vif(clk);

  systolic_array_4x4 dut (
    .clk         (clk),
    .rst_n       (vif.rst_n),
    .load_weight (vif.load_weight),
    .weight_in   (vif.weight_in),
    .a_in        (vif.a_in),
    .psum_in     (vif.psum_in),
    .psum_out    (vif.psum_out)
  );

  // Verification-only taps into registered PE outputs.
  for (genvar r = 0; r < 4; r++) begin : OBS_ROW
    for (genvar c = 0; c < 4; c++) begin : OBS_COL
      assign vif.pe_activation[r][c] = dut.a_wire[r][c+1];
      assign vif.pe_psum[r][c] = dut.psum_wire[r+1][c];
    end
  end

  initial begin
    vif.rst_n = 0;
    vif.load_weight = 0;

    foreach (vif.a_in[i]) begin
      vif.a_in[i] = 0;
      vif.psum_in[i] = 0;
    end

    foreach (vif.weight_in[i,j])
      vif.weight_in[i][j] = 0;

    uvm_config_db#(virtual systolic_if)::set(
      null, "*", "vif", vif
    );

    run_test("systolic_test");
  end

endmodule
