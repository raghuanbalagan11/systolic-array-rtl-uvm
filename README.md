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

| Metric | Result |
|---|---|
| Directed transactions | 12 |
| Pseudorandom transactions | 200 |
| Total transactions | 212 |
| Scoreboard checks | 924 |
| Scoreboard mismatches | 0 |
| Functional coverage of defined bins | 100% |
| Asynchronous reset | PASS |
| Post-reset recovery | PASS |
| UVM errors | 0 |
| UVM fatals | 0 |

Functional coverage includes activation sign, weight sign, weight-load enable, and activation/weight sign cross coverage. The reported percentage does not represent exhaustive input-space or code coverage.

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
- `sim/verification_summary.txt` — Final verification summary
- `sim/final_coverage_corrected.log` — Final regression log

## Verification Status
PASS — 924 scoreboard checks, zero mismatches, and 100% coverage of defined functional bins.
