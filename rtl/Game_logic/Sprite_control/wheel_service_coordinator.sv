/**
 * Module: wheel_service_coordinator
 * Summary: Coordinates mount occupancy, rack ownership, hitbox priority, and registered mount proximity for two wheels.
 * Author: Adam Krupa
 */
module wheel_service_coordinator #(
    parameter logic signed [11:0] FRONT_MOUNT_X = 12'sd84,
    parameter logic signed [11:0] REAR_MOUNT_X  = 12'sd192,
    parameter logic signed [11:0] MOUNT_Y       = 12'sd137,
    parameter logic signed [11:0] MOUNT_MARGIN  = 12'sd12
)(
    input  logic clk,
    input  logic rst,
    input  logic enable,

    input  logic signed [11:0] front_wheel_x,
    input  logic signed [11:0] front_wheel_y,
    input  logic signed [11:0] rear_wheel_x,
    input  logic signed [11:0] rear_wheel_y,

    input  logic front_old_removed,
    input  logic rear_old_removed,
    input  logic front_detached,
    input  logic rear_detached,
    input  logic front_new_active,
    input  logic rear_new_active,
    input  logic front_locked,
    input  logic rear_locked,
    input  logic front_mounted_at_rear,
    input  logic rear_mounted_at_rear,

    input  logic front_grab_enable,
    input  logic rear_grab_enable,
    input  logic rear_hover,
    input  logic front_dragging,
    input  logic rear_dragging,

    input  logic rack_clicked,
    input  logic front_needs_new,
    input  logic rear_needs_new,

    output logic front_wheel_near_front_mount,
    output logic front_wheel_near_rear_mount,
    output logic rear_wheel_near_front_mount,
    output logic rear_wheel_near_rear_mount,
    output logic front_mount_available,
    output logic rear_mount_available,
    output logic front_grab_allowed,
    output logic rear_grab_allowed,
    output logic front_rack_take,
    output logic rear_rack_take
);

    timeunit 1ns;
    timeprecision 1ps;

    logic front_new_mounted;
    logic rear_new_mounted;
    logic front_mount_occupied;
    logic rear_mount_occupied;
    logic rack_select_rear;

    // Register proximity to break the feedback path from wheel position,
    // through the service FSM and anchor selection, back to wheel position.
    always_ff @(posedge clk) begin
        if (!rst || !enable) begin
            front_wheel_near_front_mount <= 1'b0;
            front_wheel_near_rear_mount  <= 1'b0;
            rear_wheel_near_front_mount  <= 1'b0;
            rear_wheel_near_rear_mount   <= 1'b0;
        end else begin
            front_wheel_near_front_mount <=
                (front_wheel_x >= FRONT_MOUNT_X - MOUNT_MARGIN) &&
                (front_wheel_x <= FRONT_MOUNT_X + MOUNT_MARGIN) &&
                (front_wheel_y >= MOUNT_Y - MOUNT_MARGIN) &&
                (front_wheel_y <= MOUNT_Y + MOUNT_MARGIN);

            front_wheel_near_rear_mount <=
                (front_wheel_x >= REAR_MOUNT_X - MOUNT_MARGIN) &&
                (front_wheel_x <= REAR_MOUNT_X + MOUNT_MARGIN) &&
                (front_wheel_y >= MOUNT_Y - MOUNT_MARGIN) &&
                (front_wheel_y <= MOUNT_Y + MOUNT_MARGIN);

            rear_wheel_near_front_mount <=
                (rear_wheel_x >= FRONT_MOUNT_X - MOUNT_MARGIN) &&
                (rear_wheel_x <= FRONT_MOUNT_X + MOUNT_MARGIN) &&
                (rear_wheel_y >= MOUNT_Y - MOUNT_MARGIN) &&
                (rear_wheel_y <= MOUNT_Y + MOUNT_MARGIN);

            rear_wheel_near_rear_mount <=
                (rear_wheel_x >= REAR_MOUNT_X - MOUNT_MARGIN) &&
                (rear_wheel_x <= REAR_MOUNT_X + MOUNT_MARGIN) &&
                (rear_wheel_y >= MOUNT_Y - MOUNT_MARGIN) &&
                (rear_wheel_y <= MOUNT_Y + MOUNT_MARGIN);
        end
    end

    assign front_new_mounted = front_new_active && front_locked;
    assign rear_new_mounted  = rear_new_active && rear_locked;

    assign front_mount_occupied =
        (!front_old_removed && !front_detached) ||
        (front_new_mounted && !front_mounted_at_rear) ||
        (rear_new_mounted  && !rear_mounted_at_rear);

    assign rear_mount_occupied =
        (!rear_old_removed && !rear_detached) ||
        (front_new_mounted && front_mounted_at_rear) ||
        (rear_new_mounted  && rear_mounted_at_rear);

    assign front_mount_available = !front_mount_occupied;
    assign rear_mount_available  = !rear_mount_occupied;

    // Only the upper, later-rendered wheel may capture an overlapping hitbox.
    assign front_grab_allowed = front_grab_enable && !rear_dragging &&
                                !(rear_grab_enable && rear_hover);
    assign rear_grab_allowed  = rear_grab_enable && !front_dragging;

    // Remember which station gained priority when both wait for the rack.
    always_ff @(posedge clk) begin
        if (!rst || !enable)
            rack_select_rear <= 1'b0;
        else if (front_needs_new && !rear_needs_new)
            rack_select_rear <= 1'b0;
        else if (rear_needs_new && !front_needs_new)
            rack_select_rear <= 1'b1;
        else if (front_rack_take)
            rack_select_rear <= 1'b1;
        else if (rear_rack_take)
            rack_select_rear <= 1'b0;
    end

    assign front_rack_take = rack_clicked && front_needs_new &&
                             (!rear_needs_new || !rack_select_rear);
    assign rear_rack_take  = rack_clicked && rear_needs_new &&
                             (!front_needs_new || rack_select_rear);

endmodule
