read_verilog [glob ../../src/*.v ../../src/*.vh]
read_xdc [glob ../../constr/*.xdc]
synth_design -top top -part xc7s50csga324-1
opt_design
place_design
route_design
#write_checkpoint -force ./post_route.dcp
write_bitstream -force ../bit/top.bit

# reports
#open_checkpoint ./post_route.dcp
report_utilization -hierarchical -file report/utilization_impl.rpt
report_timing_summary -max_paths 10 -file report/timing_impl.rpt
#report_timing -delay_type max -from [get_pins i_num_a_reg_reg[*]/Q] -to [get_pins o_num_reg_reg[*]/D] -max_paths 10 -file report/timing_impl.rpt
#report_timing -delay_type max -from [get_ports i_num_a] -to [get_ports o_num] -max_paths 10 -file report/timing_impl.rpt