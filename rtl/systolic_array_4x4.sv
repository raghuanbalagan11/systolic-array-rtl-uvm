//=============================================================
// Module : systolic_array_4x4
// Project: 4x4 INT8 Systolic-Array MAC Accelerator (ECE Capstone)
// Author : Raghu Anbalagan
//
// Description:
//   Top-level 4x4 weight-stationary systolic array, built from
//   16 instances of systolic_pe (see systolic_pe.sv).
//
//   Grid layout (row, col), row 0 = north edge, col 0 = west edge:
//
//        a_in[0]->[PE00]--a-->[PE01]--a-->[PE02]--a-->[PE03]
//                    |psum        |psum        |psum        |psum
//                    v            v            v            v
//        a_in[1]->[PE10]--a-->[PE11]--a-->[PE12]--a-->[PE13]
//                    |            |            |            |
//                    v            v            v            v
//        a_in[2]->[PE20]--a-->[PE21]--a-->[PE22]--a-->[PE23]
//                    |            |            |            |
//                    v            v            v            v
//        a_in[3]->[PE30]--a-->[PE31]--a-->[PE32]--a-->[PE33]
//                    |            |            |            |
//                    v            v            v            v
//                 psum_out[0]  psum_out[1]  psum_out[2]  psum_out[3]
//
//   Weight loading:
//     load_weight is broadcast to all 16 PEs. weight_in is a
//     4x4 array so the controller/testbench can present all 16
//     weights in parallel on the cycle load_weight is asserted
//     (models a "load matrix" instruction -- a realistic control
//     FSM could instead stream weights in row-by-row; that FSM
//     lives in the top-level controller, not in this datapath
//     module, per separation of datapath and control).
//
//   Activation feed (from testbench / controller):
//     To get correct systolic timing, a_in[row] must be
//     presented with a skew of (row) extra idle cycles relative
//     to a_in[0], i.e. row 0's activation stream starts at cycle
//     0, row 1's at cycle 1, row 2's at cycle 2, row 3's at
//     cycle 3. This diagonal skew is a CONTROLLER responsibility,
//     not internal to this array module.
//
//   Result drain:
//     Column c's final accumulated result exits psum_out[c],
//     also skewed in time (col 0 finishes first). The controller
//     must sample psum_out[c] at the correct cycle per column.
//=============================================================

module systolic_array_4x4 #(
    parameter int DATA_WIDTH = 8,    // INT8 activation / weight width
    parameter int ACC_WIDTH  = 32,   // INT32 accumulator width
    parameter int N          = 4     // array dimension (4x4)
)(
    input  logic                              clk,
    input  logic                              rst_n,

    // Weight load interface: parallel load of all N x N weights
    input  logic                              load_weight,
    input  logic signed [DATA_WIDTH-1:0]      weight_in [N][N],

    // Activation inputs, one per row, entering from the west edge
    input  logic signed [DATA_WIDTH-1:0]      a_in [N],

    // Partial-sum inputs, one per column, entering from the north edge
    // (normally tied to zero -- exposed for cascading multiple arrays)
    input  logic signed [ACC_WIDTH-1:0]       psum_in [N],

    // Partial-sum outputs, one per column, exiting the south edge
    output logic signed [ACC_WIDTH-1:0]       psum_out [N]
);

    // Internal wires: activation flows west->east between columns
    // a_wire[row][col] = activation entering PE(row,col) from the west
    logic signed [DATA_WIDTH-1:0] a_wire [N][N+1];

    // Internal wires: partial sum flows north->south between rows
    // psum_wire[row][col] = partial sum entering PE(row,col) from the north
    logic signed [ACC_WIDTH-1:0]  psum_wire [N+1][N];

    genvar r, c;
    generate
        for (r = 0; r < N; r++) begin : ROW
            // West edge of this row is the external activation input
            assign a_wire[r][0] = a_in[r];

            for (c = 0; c < N; c++) begin : COL
                // North edge of this column is either the external
                // psum_in (row 0) or the previous row's psum output
                if (r == 0) begin : GEN_NORTH_EDGE
                    assign psum_wire[0][c] = psum_in[c];
                end

                systolic_pe #(
                    .DATA_WIDTH (DATA_WIDTH),
                    .ACC_WIDTH  (ACC_WIDTH)
                ) u_pe (
                    .clk         (clk),
                    .rst_n       (rst_n),
                    .load_weight (load_weight),
                    .weight_in   (weight_in[r][c]),
                    .a_in        (a_wire[r][c]),
                    .a_out       (a_wire[r][c+1]),
                    .psum_in     (psum_wire[r][c]),
                    .psum_out    (psum_wire[r+1][c])
                );
            end
        end
    endgenerate

    // South edge of the array is the final accumulated result per column
    generate
        for (c = 0; c < N; c++) begin : OUT
            assign psum_out[c] = psum_wire[N][c];
        end
    endgenerate

endmodule
