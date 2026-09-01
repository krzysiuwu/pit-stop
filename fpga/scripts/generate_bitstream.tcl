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

    # This message only reports that the design is too small for Vivado's
    # parallel synthesis partitioning.  It does not identify an RTL problem.
    set_msg_config -id {Synth 8-7080} -suppress

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

proc assert_timing_met {} {
    set failing_paths [get_timing_paths -quiet -delay_type max \
        -slack_lesser_than 0.0 -max_paths 1]

    if {[llength ${failing_paths}] != 0} {
        set worst_slack [get_property SLACK [lindex ${failing_paths} 0]]
        error "Timing requirements not met after routing (WNS=${worst_slack} ns). See ../results/timing_summary.rpt and ../results/timing_paths.rpt."
    }
}


# Generate bitstream
proc generate_bitstream {} {
    file mkdir ../results

    # The shared text renderers favor area.  Use Vivado's timing-oriented
    # implementation flow, including post-route physical optimization, to
    # recover placement and routing margin without relaxing the 65 MHz clock.
    set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

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
    report_timing_summary -delay_type min_max -max_paths 20 \
        -report_unconstrained \
        -file ../results/timing_summary.rpt
    report_timing -delay_type max -max_paths 50 -nworst 5 \
        -sort_by group -path_type full_clock_expanded \
        -file ../results/timing_paths.rpt
    report_clock_utilization -file ../results/clock_utilization.rpt
    report_high_fanout_nets -max_nets 50 \
        -file ../results/high_fanout_nets.rpt
    report_methodology -file ../results/methodology.rpt

    # Power analysis is vectorless in this flow.  Model the synchronized,
    # active-low reset distribution in its normal deasserted state.  Match
    # possible MAX_FANOUT replicas as well as the original RTL net.
    set_switching_activity -deassert_resets
    set core_reset_nets [get_nets -hierarchical -quiet \
        -filter {NAME =~ *reset_distribution*}]
    if {[llength ${core_reset_nets}] != 0} {
        set_switching_activity -static_probability 1.0 -toggle_rate 0.0 \
            ${core_reset_nets}
    }
    report_power -advisory -file ../results/power.rpt

    # A generated bitstream is not considered a successful build when setup
    # timing is negative.  Previously Vivado returned a completed run while
    # only printing Timing 38-282 as a critical warning.
    assert_timing_met
}


# MAIN
create_new_project $project_name $target $top_module
generate_bitstream
exit
