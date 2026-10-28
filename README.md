# 4x4 INT8 Systolic Array Accelerator — RTL Design & UVM Verification

## Overview
Designed a 4x4 systolic array accelerator in SystemVerilog and developed a UVM-based verification environment to validate its functionality.

The design contains 16 processing elements supporting signed 8-bit multiplication, 32-bit partial-sum accumulation, and pipelined data propagation.

## Hardware Architecture
- 4x4 array of 16 processing elements
- Signed INT8 activation and weight operands
- Signed INT16 multiplication results
- 32-bit partial-sum accumulation
- Horizontal activation propagation
- Vertical partial-sum propagation
- Parallel weight loading
- Active-low asynchronous reset

Input scheduling and row skewing are managed externally.

## UVM Verification Environment
- UVM test and environment
- Active agent with sequencer, driver, and monitor
- Transaction-level stimulus
- Directed and pseudorandom sequences
- Self-checking reference-model scoreboard
- Functional coverage collector
- Asynchronous-reset and post-reset recovery testing

## Verification Results

The latest Verilator/UVM regression completed successfully using seed 1.

| Metric | Result |
|---|---:|
| Directed transactions | 12 |
| Pseudorandom transactions | 956 |
| Arithmetic-boundary transactions | 32 |
| Total stimulus transactions | 1,000 |
| Scoreboard comparisons | 36,684 |
| Scoreboard mismatches | 0 |
| Transaction functional coverage | 100.00% |
| Internal PE activation coverage | 100.00% |
| Internal PE partial-sum coverage | 100.00% |
| Signed INT32 MAC overflow coverage | 100.00% |
| Sampled MAC operations | 16,176 |
| MAC operations without overflow | 16,070 |
| Positive overflow events | 47 |
| Negative overflow events | 59 |
| Asynchronous reset | PASS |
| Post-reset recovery | PASS |
| UVM warnings | 2 |
| UVM errors | 0 |
| UVM fatals | 0 |
| Simulation exit code | 0 |

### Verification Methodology

- Directed, pseudorandom, and arithmetic-boundary stimulus
- Cycle-accurate reference-model scoreboard
- Checking of four array outputs and 16 internal PE activation and partial-sum signals
- Functional coverage of activation, weight, weight-loading, and PE behavior
- Signed INT32 MAC overflow classification using 64-bit reference arithmetic
- Active-low asynchronous reset and post-reset recovery verification
- Pipeline-drain testing

The two UVM warnings relate to the `UVM_NO_DPI` configuration.
They do not indicate detected RTL mismatches.

**Coverage limitation:** The reported 100% values represent coverage
of explicitly defined functional bins, not exhaustive verification,
complete code coverage, or formal proof.

### Verification Report

[View the UVM Verification Report](UVM_Verification_Report.html)

## FPGA Synthesis, Implementation & Timing Closure

The systolic array was implemented separately using Xilinx Vivado,
targeting the Virtex-7 FPGA (7vx485t-ffg1157) with a 100 MHz clock target.

### Implementation Flow
1. RTL synthesis
2. Resource utilization analysis
3. Placement and routing
4. Static timing analysis (STA)
5. I/O register placement optimization
6. Post-route timing verification

### Final Timing Results

| Metric | Result |
|---|---|
| Target clock frequency | 100 MHz |
| Clock period | 10 ns |
| Final worst setup slack (WNS) | +0.181 ns |
| Final worst hold slack (WHS) | +0.068 ns |
| Total negative setup slack (TNS) | 0.000 ns |
| Total negative hold slack (THS) | 0.000 ns |
| Setup failing endpoints | 0 |
| Hold failing endpoints | 0 |
| Timing constraints | MET |

The final timing report confirms that all user-specified timing
constraints were met.

### Synthesis and Timing Reports
- [Synthesis utilization](reports/utilization_synth.rpt)
- [Synthesis timing](reports/timing_synth.rpt)
- [Post-route utilization](reports/utilization_postroute.rpt)
- [Initial post-route timing](reports/timing_postroute.rpt)
- [Timing after IOB optimization](reports/timing_after_iob_route.rpt)
- [Timing after physical optimization](reports/timing_after_physopt_reroute.rpt)
- [Final timing closure report](reports/systolic_100MHz_final_timing.rpt)
- [Reproducible timing report](reports/systolic_100MHz_reproducible_timing.rpt)

### FPGA Constraints
- [Original timing constraints](constraints/systolic_timing.xdc)
- [Output IOB constraints](constraints/systolic_output_iob.xdc)
- [Optimized 100 MHz constraints](constraints/systolic_100MHz_optimized.xdc)

The synthesis and FPGA implementation were performed separately
from the Verilator/UVM verification flow.

## Tools
- SystemVerilog
- Universal Verification Methodology (UVM)
- Verilator 5.053
- Accellera UVM 2020.3.1
- Xilinx Vivado

## Project Structure
- `rtl/` — Systolic array and processing-element RTL
- `tb/` — UVM verification components and testbench
- `reports/` — Vivado synthesis, utilization, and timing reports
- `constraints/` — FPGA timing and I/O constraints
- `UVM_Verification_Report.html` — Updated UVM verification report
- `tb/systolic_coverage.sv` — Functional and overflow coverage

## Verification Status
PASS — 1,000 stimulus transactions, 36,684 scoreboard comparisons, zero mismatches, and 100% coverage of defined functional bins.
