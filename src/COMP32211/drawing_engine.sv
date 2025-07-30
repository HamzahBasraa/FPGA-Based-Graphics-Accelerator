/** 
    Module:        drawing_engine
    
    Description:   Top level module for the drawing engine.
                   This module instantiates the drawing control and
                   drawing units, and provides a bus interface to the
                   video display unit controller (VDUC).
                   It also handles the bus requests and responses.

    Authors:       James Garside & Anthony Mathews
    Date:          July 2025

*/

`timescale 1ns / 1ps

module drawing_engine(
               input  logic        clk,
               input  logic        reset,
               input  logic        cs_i,
               input  logic        read_i,
               input  logic        write_i,
               input  logic [31:0] address_i,
               input  logic  [1:0] size_i,
               input  logic  [1:0] mode_i,
               output logic        stall_o,
               output logic  [2:0] abort_v_o,
               input  logic [31:0] data_in,
               output logic  [31:0] data_out,
               output logic  [1:0] ireq_o,
               
               input  logic  [9:0] v_width_i,
               input  logic  [9:0] v_height_i,
               input  logic  [1:0] v_mode_i,
               input  logic [17:0] v_frame_i,

               output logic        de_req_o,  /* Bus fron drawing accelerator to FS mux. */
               output logic        de_RnW_o,
               output logic  [3:0] de_nbyte_o,
               input  logic        de_ack_i,
               output logic [17:0] de_address_o,
               output logic [31:0] de_wr_data_o,
               input  logic [31:0] de_rd_data_i);



typedef logic [31:0] argument_bus_t [7:0]; 
argument_bus_t arguments;

wire logic [31:0] command;
wire logic [31:0] drawing_base; 
wire logic [31:0] status;

wire logic bus_reset; 
wire logic bus_req;
wire logic [7:0] bus_busy;

wire logic [9:0]  bus_display_width;
wire logic [9:0]  bus_display_height;
wire logic [1:0]  bus_display_mode;
wire logic [17:0] bus_display_base;

wire logic [7:0]  drawing_units_completed_job;


/* Instantiate drawing controller */
drawing_control u_drawing_control (
    .clk         (clk         ),
    .reset       (reset       ),
    .cs_i        (cs_i        ),
    .read_i      (read_i      ),
    .write_i     (write_i     ),
    .address_i   (address_i   ),
    .size_i      (size_i      ),
    .mode_i      (mode_i      ),
    .stall_o     (stall_o     ),
    .abort_v_o   (abort_v_o   ),
    .data_in     (data_in     ),
    .data_out    (data_out    ),
    .ireq_o      (ireq_o      ),
    .arguments_o (arguments   ),
    .command_o   (command     ),
    .req_o       (bus_req     ),


    .busy_i(bus_busy),
    .job_complete_int_i(|drawing_units_completed_job),           
    .job_queue_int_i(0),            // Not implemented 

    .drawing_unit_reset_o(bus_reset), 

    .display_base_o    (bus_display_base),
    .display_height_o   (bus_display_height),
    .display_mode_o     (bus_display_mode),
    .display_width_o    (bus_display_width),

    .v_width_i(v_width_i),
    .v_height_i(v_height_i),
    .v_mode_i(v_mode_i),
    .v_frame_i(v_frame_i)
);

drawing_unit_bank u_drawing_unit_bank  (
    .clk          (clk          ),
    .reset        (bus_reset | reset  ),
    .req_i        (bus_req      ),

    .arguments_i  (arguments    ),
    .command_i    (command      ),
    .busy_o       (bus_busy     ),

    .display_base_i     (bus_display_base),
    .display_height_i   (bus_display_height),
    .display_mode_i     (bus_display_mode),
    .display_width_i    (bus_display_width),

    .completed_o(drawing_units_completed_job),

    .de_req_o     (de_req_o     ),
    .de_RnW_o     (de_RnW_o     ),
    .de_nbyte_o   (de_nbyte_o   ),
    .de_ack_i     (de_ack_i     ),
    .de_address_o (de_address_o ),
    .de_wr_data_o (de_wr_data_o ),
    .de_rd_data_i (de_rd_data_i )
);


endmodule

/*============================================================================*/
