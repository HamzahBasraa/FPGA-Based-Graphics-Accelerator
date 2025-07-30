/**
    Module:        drawing_unit_triggers   

    Description:   This module generates job completion signals for each
                   drawing unit based on the busy signals from the drawing units.
                   It is used to trigger interrupts when a drawing unit completes a job.

    Authors:       James Garside & Anthony Mathews
    Updated:       July 2025
*/
module drawing_unit_triggers( 
    input logic clk, 
    input logic reset,
    input logic [7:0] busy_bus_i,
    output logic [7:0] job_completed_o
);

/** Registers */
logic [7:0] busy_bus_latched;

always_ff @ (posedge clk) begin 
    if (reset)
        busy_bus_latched <= 8'h0;
    else 
        busy_bus_latched <= busy_bus_i;
end

always_comb begin

    // Just completed if it was busy 
    // last cycle but not busy now 
    job_completed_o = busy_bus_latched & ~busy_bus_i; 
end


endmodule