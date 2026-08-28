# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# tcl file sourced to Vivado to load the bitstream specified in the argument to ALL connected FPGAs sequentially.

# Bitstream location
set bitstream_file [lindex ${argv} 0]

# Load bitstream to FPGA
proc program_fpga {bitstream_file} {
    if {[file exists $bitstream_file] == 0} {
        puts "ERROR: Bitstream not found"
        exit 1
    } else {
        open_hw_manager
        connect_hw_server
        
        # Get a list of all connected hardware targets
        set targets [get_hw_targets]
        
        if {[llength $targets] == 0} {
            puts "ERROR: No hardware targets connected!"
            exit 1
        }
        
        # Iterate through all discovered boards
        foreach target $targets {
            puts "========================================"
            puts " Programming target: $target"
            puts "========================================"
            
            current_hw_target $target
            open_hw_target
            
            set device [lindex [get_hw_devices] 0]
            current_hw_device $device
            refresh_hw_device -update_hw_probes false $device
            
            set_property PROBES.FILE {} $device
            set_property FULL_PROBES.FILE {} $device
            set_property PROGRAM.FILE ${bitstream_file} $device
            
            program_hw_devices $device
            refresh_hw_device $device
            
            # Close the current target before moving to the next one
            close_hw_target
        }
        
        disconnect_hw_server
        close_hw_manager
    }
}

## MAIN
if {${argc} != 1} {
    puts "ERROR: Bitstream not specified"
    exit 1
} else {
    program_fpga $bitstream_file
    exit
}