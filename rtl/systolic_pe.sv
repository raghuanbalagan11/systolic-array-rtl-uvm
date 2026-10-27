//=============================================================
// Module : systolic_pe
// Project: 4x4 INT8 Systolic-Array MAC Accelerator (ECE Capstone)
// Author : Raghu Anbalagan
//
// Description:
//   Single Processing Element (PE) for a weight-stationary
//   systolic array.
//
//   Dataflow:
//     - Weight (INT8) is loaded once per matrix multiply and
//       held stationary in this PE for the duration of the op.
//     - Activation (INT8) flows west -> east, one PE per cycle.
//     - Partial sum (INT32) flows north -> south, one PE per
//       cycle, accumulating a*weight at each stage.
//
//   Per-cycle behavior:
//     psum_out <= psum_in + (a_in * weight_reg)
//     a_out    <= a_in                              (1-cycle systolic delay)
//
//   This 1-cycle registered delay on both a_out and psum_out is
//   what gives the array its systolic (skewed) timing -- inputs
//   to row/column N+1 must be staggered by one cycle relative to
//   row/column N for the partial sums to align correctly. This
//   skew is handled at the array-integration level (Phase 1,
//   next step), not inside the PE itself.
//=============================================================

module systolic_pe #(
    parameter int DATA_WIDTH = 8,   // INT8 activation / weight width
    parameter int ACC_WIDTH  = 32   // INT32 accumulator width
)(
    input  logic                          clk,
    input  logic                          rst_n,

    // Weight load interface (control plane)
    input  logic                          load_weight,
    input  logic signed [DATA_WIDTH-1:0]  weight_in,

    // Systolic activation path (west -> east)
    input  logic signed [DATA_WIDTH-1:0]  a_in,
    output logic signed [DATA_WIDTH-1:0]  a_out,

    // Systolic partial-sum path (north -> south)
    input  logic signed [ACC_WIDTH-1:0]   psum_in,
    output logic signed [ACC_WIDTH-1:0]   psum_out
);

    logic signed [DATA_WIDTH-1:0]     weight_reg;
    logic signed [2*DATA_WIDTH-1:0]   product;
    logic signed [ACC_WIDTH-1:0]      product_ext;

    // ---------------------------------------------------------
    // Weight register: loaded once per matrix (weight-stationary)
    // ---------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            weight_reg <= '0;
        else if (load_weight)
            weight_reg <= weight_in;
    end

    // ---------------------------------------------------------
    // Combinational multiply (INT8 x INT8 -> INT16)
    // ---------------------------------------------------------
    assign product     = a_in * weight_reg;
    assign product_ext = {{(ACC_WIDTH-2*DATA_WIDTH){product[2*DATA_WIDTH-1]}}, product};

    // ---------------------------------------------------------
    // Registered MAC + systolic pipeline registers
    // ---------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out    <= '0;
            psum_out <= '0;
        end else begin
            a_out    <= a_in;                    // propagate activation east
            psum_out <= psum_in + product_ext;    // accumulate and propagate south
        end
    end

endmodule
