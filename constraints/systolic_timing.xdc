
# 4x4 Systolic Array
# Target FPGA: xc7vx485tffg1157-1

# Target clock: 100 MHz
create_clock -name sys_clk -period 10.000 [get_ports clk]
# Hypothetical synchronous interface timing
# Clock period = 10 ns

set_input_delay -clock sys_clk -max 2.000 \
    [get_ports {a_in* weight_in* psum_in* load_weight}]

set_input_delay -clock sys_clk -min 0.000 \
    [get_ports {a_in* weight_in* psum_in* load_weight}]

set_output_delay -clock sys_clk -max 2.000 \
    [get_ports {psum_out*}]

set_output_delay -clock sys_clk -min 0.000 \
    [get_ports {psum_out*}]