/* 
    Module:        drawing_engine
    
    Description:   Top level module for the drawing engine.
                   This module instantiates the drawing control and
                   drawing units, and provides a bus interface to the
                   video display unit controller (VDUC).
                   It also handles the bus requests and responses.

    Authors:       James Garside & Anthony Mathews
    Date:          August 2025

*/

`timescale 1ns / 1ps

module drawing_engine(
            input  logic        clk,
            input  logic        reset_i,
            input  logic        cs_i,      /* Processor unit select           */
            input  logic        read_i,    /* Processor read operation        */
            input  logic        write_i,   /* Processor write operation       */
            input  logic [31:0] address_i, /* Processor address               */
            input  logic  [1:0] size_i,    /* Processor transfer size {W,H,B} */
            input  logic  [1:0] mode_i,    /* Processor privilege mode        */
            output logic        stall_o,   /* Processor wait                  */
            output logic  [2:0] abort_v_o, /* Processor cycle abort           */
            input  logic [31:0] data_in,   /* Processor write (store) data    */
            output logic [31:0] data_out,  /* Processor read (load) data      */
            output logic  [1:0] ireq_o,    /* Processor interrupt requests    */
            
            input  logic [17:0] v_base_i,  /* Screen configuration from VDUC  */
            input  logic  [1:0] v_mode_i,
            input  logic  [9:0] v_width_i,
            input  logic  [9:0] v_height_i,

            output logic        de_req_o,  /* Bus from drawing accelerator    */
            input  logic        de_ack_i,  /* to framestore multiplexer.      */
            output logic        de_RnW_o,
            output logic [17:0] de_address_o,
            output logic  [3:0] de_nbyte_o,
            output logic [31:0] de_wr_data_o,
            input  logic [31:0] de_rd_data_i);


typedef logic [31:0] argument_bus_t [7:0]; 
argument_bus_t arguments;

logic [31:0] command;
logic [31:0] drawing_base; 

logic        bus_reset; 
logic        bus_req;
logic        bus_ack;
logic  [7:0] bus_busy;
logic  [7:0] bus_done;

logic  [9:0] bus_display_width;
logic  [9:0] bus_display_height;
logic  [1:0] bus_display_mode;
logic [17:0] bus_display_base;

drawing_control u_drawing_control (        /* Instantiate drawing controller  */
    .clk              (clk),               /* System clock                    */
    .reset_i          (reset_i),           /* System reset                    */
    .cs_i             (cs_i),              /* Processor unit select           */
    .read_i           (read_i),            /* Processor read operation        */
    .write_i          (write_i),           /* Processor write operation       */
    .address_i        (address_i),         /* Processor address               */
    .size_i           (size_i),            /* Processor transfer size {W,H,B} */
    .mode_i           (mode_i),            /* Processor privilege mode        */
    .stall_o          (stall_o),           /* Processor wait                  */
    .abort_v_o        (abort_v_o),         /* Processor cycle abort           */
    .data_in          (data_in),           /* Processor write (store) data    */
    .data_out         (data_out),          /* Processor read (load) data      */
    .ireq_o           (ireq_o),            /* Processor interrupt requests    */
    .arguments_o      (arguments),         /* User's current arguments        */
    .command_o        (command),           /* User's current command          */
    .req_o            (bus_req),           /* Request to start drawing        */
    .ack_i            (bus_ack),           /* Acknowledgement drawing started */
    .busy_i           (bus_busy),          /* Unit indicating drawing         */
    .done_i           (bus_done),          /* Pulse indicating unit completion*/
    .drawing_unit_reset_o(bus_reset),      /* Stop drawing command (emergency)*/

    .v_width_i        (v_width_i),         /* Input configuration from VDUC   */
    .v_height_i       (v_height_i),
    .v_mode_i         (v_mode_i),
    .v_base_i         (v_base_i),

    .display_base_o   (bus_display_base),         /* Configuration, forwarded */
    .display_mode_o   (bus_display_mode),
    .display_width_o  (bus_display_width),
    .display_height_o (bus_display_height));

   
drawing_unit_bank u_drawing_unit_bank(  /* Instantiate accelerator collection */
    .clk              (clk),
    .reset_i          (bus_reset || reset_i),
    .req_i            (bus_req),
    .ack_o            (bus_ack),
    .busy_o           (bus_busy),
    .done_o           (bus_done),
    .arguments_i      (arguments),
    .command_i        (command),

    .display_base_i   (bus_display_base),
    .display_height_i (bus_display_height),
    .display_mode_i   (bus_display_mode),
    .display_width_i  (bus_display_width),

    .de_req_o         (de_req_o),
    .de_RnW_o         (de_RnW_o),
    .de_nbyte_o       (de_nbyte_o),
    .de_ack_i         (de_ack_i),
    .de_address_o     (de_address_o),
    .de_wr_data_o     (de_wr_data_o),
    .de_rd_data_i     (de_rd_data_i));

endmodule

/*============================================================================*/
