# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# tcl script being sourced to Vivado to build a project from sources and generate a bitstream.
# Some project details and paths to the source files are read from project_details.tcl


# Source the project details file
# (it should provide: project_name, top_module, target, and paths to all the sources)
source scripts/project_details.tcl

# Create project
proc create_new_project {project_name target top_module} {
    file mkdir build
    create_project ${project_name} build -part ${target} -force

    # read files from the variables provided by the project_details.tcl
    if {[info exists ::xdc_files]}     {read_xdc ${::xdc_files}}
    if {[info exists ::sv_files]}      {read_verilog -sv ${::sv_files}}
    if {[info exists ::verilog_files]} {read_verilog ${::verilog_files}}
    if {[info exists ::vhdl_files]}    {read_vhdl ${::vhdl_files}}
    if {[info exists ::mem_files]}     {read_mem ${::mem_files}}

    set_property top ${top_module} [current_fileset]
    update_compile_order -fileset sources_1
}

proc assert_run_complete {run_name} {
    set run_status [get_property STATUS [get_runs ${run_name}]]
    if {![string match "*Complete*" ${run_status}]} {
        error "Run ${run_name} failed or did not complete: ${run_status}"
    }
}


# Generate bitstream
proc generate_bitstream {} {
    file mkdir ../results

    # Run synthesis
    reset_run synth_1
    launch_runs synth_1 -jobs 8
    wait_on_run synth_1
    assert_run_complete synth_1
    open_run synth_1
    report_utilization -file ../results/synthesis_utilization.rpt

    # Run implementation up to bitstream generation
    launch_runs impl_1 -to_step write_bitstream -jobs 8
    wait_on_run impl_1
    assert_run_complete impl_1
    open_run impl_1
    report_utilization -file ../results/implementation_utilization.rpt
    report_timing_summary -delay_type max -max_paths 10 \
        -file ../results/timing_summary.rpt
    report_clock_utilization -file ../results/clock_utilization.rpt
    report_methodology -file ../results/methodology.rpt
}


# MAIN
create_new_project $project_name $target $top_module
generate_bitstream
exit
