// Verilog HDL for "COMP32211", "drawing_clear"
// This unit fills the screen with the specified colour value
// J. Garside
// University of Manchester; Dept. of CS
// January 2015
// Revised Sept. 2023

`timescale 1ns / 10ps 

`include "video_definitions.sv"

`define IDLE      0			// Not active
`define BUSY      1			// Trying to output a word

module drawing_clear( input  wire        clk,
                      input  wire        req,
                      output reg         ack,
                      output wire        busy,
                      input  wire [15:0] r0,
                      input  wire [15:0] r1,
                      input  wire [15:0] r2,
                      input  wire [15:0] r3,
                      input  wire [15:0] r4,
                      input  wire [15:0] r5,
                      input  wire [15:0] r6,
                      input  wire [15:0] r7,
                      output wire        de_req,
                      input  wire        de_ack,
                      output reg  [17:0] de_addr,
                      output wire  [3:0] de_nbyte,
                      output wire        de_rnw,
                      output wire [31:0] de_w_data,
                      input  wire [31:0] de_r_data );

reg         draw_state;			// Main FSM state variable
reg   [7:0] colour;			// Internal parameter
initial draw_state = `IDLE;		// Can set state on FPGA
initial ack        = 0;

always @ (posedge clk)			// Finite State Machine
  case (draw_state)

    `IDLE:
      begin
      if (req)				// Wait for processor request
        begin
        ack     <= 1;			// Acknowledge start of operation
	colour  <= r0[7:0];		// Latch any needed parameter values
        de_addr <= 0;			// Initialise any internal state
        draw_state <= `BUSY;		// Get busy
        end
      end

    `BUSY:
      begin
      ack <= 0;			        // Remove acknowledge
      if (de_ack)			// When requested write operation has begun ...
        begin				// Compare -word- address
	if (de_addr >= ((`X_SIZE * `Y_SIZE)>>2) - 1)
          draw_state <= `IDLE;	// Finished
        else
          de_addr <= de_addr + 1;	// else set up for next request
        end
      end

  endcase

assign de_req = (draw_state == `BUSY);	// Draw requests consecutive when active
assign de_rnw =  0;			// Only ever write
assign de_nbyte = 4'b0000;		// Always write whole words
assign de_w_data = {4{colour}};		// Duplicate colour through word
assign busy = (draw_state == `BUSY);	// Indicates drawing engine active

endmodule
