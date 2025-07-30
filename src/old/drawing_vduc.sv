// -----------------------------------------------------------------------------
// Verilog HDL for "COMP32211", "drawing_vduc"

`define TPD 2

`timescale 1ns / 10ps
// -----------------------------------------------------------------------------

// Get screen size etc.
`include "video_definitions.sv"

module drawing_vduc (input wire clk,
                     output reg frame_over,
                     output reg [17:0] vdu_address,
                     input wire [31:0] vdu_data,
                     output reg vdu_req,
                     input wire vdu_ack,
                     output reg v_sync_out,
                     output reg h_sync_out,
                     output reg [7:0] pixel_out,
                     output reg v_blank,
                     output reg h_blank);
    
    
`define BP     0			// Local definitions for VDUC states
`define ACTIVE 1
`define FP     2
`define SYNC   3

reg   [1:0] vduc_state;			// Current pixel address in word
reg   [9:0] h_count;			// Word address on line
reg   [1:0] h_state;			// BP/active/FP/sync
reg   [9:0] v_count;			// Line address in frame
reg   [1:0] v_state;			// BP/active/FP/sync
reg  [31:0] pixels;			// Screen data output latch ('shifter')
wire        blank;			// Output blanking (for any reason)
reg  [17:0] line_address;		// Address at start of next line
reg         sync_start;			// Indicate flyback to vertical FSM
reg         sync_start_L;		// Delayed sync_start allowing
//  vertical FSM to catch up
reg         v_blank0;
reg         h_blank0;

initial					// Reset conditions
begin					// FPGA will reset to these on loading
vdu_req     = 1;
vdu_address = 0;
h_count     = 0;
h_state     = `BP;
v_count     = 3;
v_state     = `FP;

v_sync_out = 1'b0;			// Reset condition
h_sync_out = 1'b0;
end

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
// State within a word

always @ (posedge clk)
if (vdu_ack)                    // Used to synchronise FSM to memory
  begin
  vdu_req    <= #`TPD 1'b0;
  vduc_state <= 3;
  end
else
  begin
  if (blank)			// Clear pixel buffer after word shifted
    begin
    if (vduc_state == 3) pixels <= 32'h0000_0000;
    end				// Ensures 'else' associates correctly
  else
    case (vduc_state)
      0: vdu_req              <= #`TPD 1'b1;
      2: if (vdu_ack) vdu_req <= #`TPD 1'b0;
      3: pixels               <= vdu_data;
    endcase
    
  if (vduc_state == 3)
    begin
    v_blank0 <= (v_state != `ACTIVE);	// Synced with data in
    h_blank0 <= (h_state != `ACTIVE);
    end
  vduc_state <= vduc_state + 1;
  end

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
// Horizontal counter
    
always @ (posedge clk)
if ((vduc_state == 3) && !vdu_ack)     /* 2nd term just to help initial sync. */
  begin
  if (h_count == 0)
    case (h_state)
      `BP:     begin
               h_state <= `ACTIVE;
               h_count <= `HORIZ_ACTIVE/4 - 1;
               end
      `ACTIVE: begin
               h_state <= `FP;
               h_count <= `HORIZ_FRONT_PORCH/4 - 1;
               end
      `FP:     begin
               h_state    <= `SYNC;
               h_count    <= `HORIZ_SYNC/4 - 1;
               h_sync_out <= #`TPD 1'b1;
               sync_start <= 1'b1;
               end
      `SYNC:   begin
               h_state    <= `BP;
               h_count    <= `HORIZ_BACK_PORCH/4 - 1;
               h_sync_out <= #`TPD 1'b0;
               end
    endcase
  else h_count <= h_count - 1;
  end
else sync_start <= 1'b0;			// Adequate for single pulse

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
// Vertical counter

always @ (posedge clk)
if (sync_start)
  begin
  if (v_count == 0)
    case (v_state)
      `BP:     begin
               v_state <= `ACTIVE;
               v_count <= `VERT_ACTIVE - 1;
               end
      `ACTIVE: begin
               v_state    <= `FP;
               v_count    <= `VERT_FRONT_PORCH - 1;
               frame_over <= 1'b1;
               end
      `FP:     begin
               v_state    <= `SYNC;
               v_count    <= `VERT_SYNC - 1;
               v_sync_out <= #`TPD 1'b1;
               end
      `SYNC:   begin
               v_state    <= `BP;
               v_count    <= `VERT_BACK_PORCH - 1;
               v_sync_out <= #`TPD 1'b0;
               end
    endcase
  else v_count <= v_count - 1;
  end
else frame_over <= 1'b0;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
    
assign blank = ((v_state != `ACTIVE) || (h_state != `ACTIVE));
    
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
    
always @ (posedge clk) sync_start_L <= sync_start;
    
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
// Address generator
    
always @ (posedge clk)
if (v_state == `SYNC) line_address <= 18'h0;			// New frame
else
  if (sync_start_L)
    begin
    vdu_address <= #`TPD line_address;
    if (v_state == `ACTIVE)
      begin          //	if (v_count[0] == 0)	// Double check condition
      line_address <= line_address + (`HORIZ_ACTIVE / 4);
      end
    end
  else
    if ((v_state == `ACTIVE) && (h_state == `ACTIVE)
     && (vduc_state == 3) && !vdu_ack)
      vdu_address <= #`TPD vdu_address + 1;
        /* The !vdu_ack term is present to ensure the addresses behave as     */
        /* might be expected from start up.  It is not really necessary as,   */
        /* once synchronisation has been achieved, it has no effect.          */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

always @ (posedge clk)		 // Pixel multiplexer and output delay
case (vduc_state)
  0: pixel_out <= #`TPD pixels[7: 0];
  1: pixel_out <= #`TPD pixels[15: 8];
  2: pixel_out <= #`TPD pixels[23:16];
  3: pixel_out <= #`TPD pixels[31:24];
endcase
    
always @ (posedge clk)		// Keep overlay signals in sync.
begin
v_blank <= #`TPD v_blank0;
h_blank <= #`TPD h_blank0;
end
    
/*----------------------------------------------------------------------------*/
    
endmodule
    
/*============================================================================*/
