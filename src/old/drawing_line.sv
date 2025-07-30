/******************************************************************************/
/*                                                                            */
/* Verilog HDL for "COMP32211", "drawing_line"                                */
/* Module:   drawing_line                                                     */
/* Modified: Sept. 2023                                                       */
/* Author:   J Garside                                                        */
/*                                                                            */
/* Description:                                                               */
/*                                                                            */
/* This version is 'fire and forget' and assumes the outputs                  */
/* are held by the memory controller.                                         */
/* No propagation delays have been inserted here yet.                         */
/* Maybe omit for clarity?                                                    */
/******************************************************************************/

`timescale 1ns / 10ps 
`define IDLE 0
`define BUSY 1

`define TPD 2				// Cosmetic delay - may make clearer?

module drawing_line ( input  wire        clk,
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
		      output wire [17:0] de_addr,
		      output reg   [3:0] de_nbyte,
		      output wire [31:0] de_data);

reg draw_state;

reg [11:0] error;			// Signed
reg  [9:0] dab;				// Unsigned
reg  [9:0] db;				// Unsigned
reg [10:0] onestep;			// Step in primary direction
reg [10:0] twostep;			// Step in both directions
reg [19:0] address;			// Pixel address
reg  [9:0] length;			// Pixels left to plot + 1
reg  [7:0] colour;

wire [19:0] onestep_ext;		// Sign extension
wire [19:0] twostep_ext;		// Sign extension
					// See also 'signed' declarations
wire [11:0] compare;			// Calculate comparison explicitly
wire [19:0] address_in = {r5[3:0], r4};

initial draw_state = `IDLE;		// Enumerated states
initial ack        = 0;

assign onestep_ext[10:0]  = onestep[10:0];
assign onestep_ext[19:11] = {9{onestep[10]}};

assign twostep_ext[10:0]  = twostep[10:0];
assign twostep_ext[19:11] = {9{twostep[10]}};

assign #`TPD compare = error - (db << 1);
assign #`TPD de_req = busy && ((length != 0) || !de_ack);
// Suppress request early (async) in last cycle	to allow contiguous acks

assign busy = (draw_state == `BUSY);

always @ (posedge clk)
  case (draw_state)
    `IDLE:				// Idle
      if (req)				// Wait for request
        begin
        ack     <= #`TPD 1;		// Acknowledge start
					// Work out/load initial values
        error   <= #`TPD r0[9:0];	// Signed
        dab     <= #`TPD r0[9:0] - r1[9:0]; // Unsigned
        db      <= #`TPD r1[9:0];	// Unsigned
        onestep	<= #`TPD r2[10:0];	// Step in primary direction
        twostep	<= #`TPD r3[10:0];	// Step in both directions
        address	<= #`TPD address_in;	// Pixel address
        length	<= #`TPD r0[9:0];	// Pixels left to plot + 1
        colour 	<= #`TPD r6[7:0];

        draw_state <= #`TPD `BUSY;	// Get busy
        end

    `BUSY:				// Busy
      begin
      ack <= #`TPD 1'b0;		// Start now acknowledged
      if (de_ack)			// If last request accepted
        begin
        if (length == 0)		// See if finished?
          draw_state <= #`TPD `IDLE;	//  Yes - back to idle
          // Pixel still plotted *this* cycle as (length+1) pixels needed
        else
          begin				// Still drawing
          if (!compare[11])		// i.e. positive
            begin			// Step only in primary direction
            error   <= #`TPD compare;
            address <= #`TPD address + onestep_ext;
            end
          else
            begin			// Step diagonally
            error   <= #`TPD error + (dab << 1);
            address <= #`TPD address + twostep_ext;
            end
          length <= #`TPD length - 1;	// Decrement count and repeat
          end
        end				// .. of `not waiting' clause
      end				// .. of busy case
  endcase

assign de_addr = address[19:2];  // Set address_out to be word address
assign de_data = {4{colour}};

// Decode the lower 2 bits of address to produce nbyte selects.
// Added by dmc 18/1/07.
always @(address[1:0])
  case(address[1:0])
    2'b00 : de_nbyte <= #`TPD 4'b1110;
    2'b01 : de_nbyte <= #`TPD 4'b1101;
    2'b10 : de_nbyte <= #`TPD 4'b1011;
    2'b11 : de_nbyte <= #`TPD 4'b0111;
    default:de_nbyte <= #`TPD 4'b1111;
  endcase

endmodule
