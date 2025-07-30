// Verilog HDL for "COMP32211", "drawing_command"
// Processor bus interface
// There are some 'unfinished' features not needed for COMP32211

`define TPD 2

`timescale 1ns / 10ps

module drawing_command (
                 input  wire        clk,
                 input  wire        reset,

                 input  wire  [5:0] uP_address,
	         input  wire  [1:0] uP_nbs,
	         input  wire [15:0] uP_wdata,
	         output reg  [15:0] uP_rdata,
	         input  wire        uP_ncs,
	         input  wire        uP_nwr,
	         input  wire        uP_nrd,
		 output wire        uP_irq,

		 output wire        cmd_req,
		 input  wire        cmd_ack,
		 output wire [15:0] r0,
		 output wire [15:0] r1,
		 output wire [15:0] r2,
		 output wire [15:0] r3,
		 output wire [15:0] r4,
		 output wire [15:0] r5,
		 output wire [15:0] r6,
		 output wire [15:0] r7,

		 output wire [15:0] command,
		 input  wire        cmd_busy,

		 output wire        iq_req,
		 input  wire        iq_ack,
		 output reg  [19:0] iq_address,
		 output reg         iq_rnw,
		 output reg   [7:0] data_from_iq,
		 input  wire  [7:0] data_to_iq,
		 input  wire        iq_busy,

                 input  wire        v_blank,	// CRTC status
                 input  wire        frame_over,	// Entering blanking

                 output reg   [5:0] port_out_1,
                 input  wire  [5:0] port_in_1
		 );

reg  [15:0] reg0, reg1, reg2, reg3;	// Internal reg. bank
reg  [15:0] reg4, reg5, reg6, reg7;	// Internal reg. bank
reg  [15:0] cmd;
reg         frame_irq;
wire        clr_irq;
wire [15:0] status;

reg go, go_1, go_2;
reg gg, gg_1, gg_2;
initial go = 0;
initial gg = 0;

assign #`TPD r0 = reg0;
assign #`TPD r1 = reg1;
assign #`TPD r2 = reg2;
assign #`TPD r3 = reg3;
assign #`TPD r4 = reg4;
assign #`TPD r5 = reg5;
assign #`TPD r6 = reg6;
assign #`TPD r7 = reg7;
assign #`TPD command = cmd;
assign #`TPD cmd_req = go_2;
assign #`TPD iq_req  = gg_2;

assign status = { 2'h0, port_in_1,	// Assemble bits into register
                  2'b00, frame_irq, v_blank,
		              2'b00, cmd_busy, iq_busy};
assign uP_irq = 0;			// Tie off interrupt for now

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register bank

initial port_out_1 = 6'h15;			// Just an LED pattern at reset 

// Register writes (see commentary below)
always @ (uP_address, uP_wdata, uP_ncs, uP_nwr)
  if (!uP_ncs && !uP_nwr)
    case (uP_address)
       0: reg0 = uP_wdata;
       1: reg1 = uP_wdata;
       2: reg2 = uP_wdata;
       3: reg3 = uP_wdata;
       4: reg4 = uP_wdata;
       5: reg5 = uP_wdata;
       6: reg6 = uP_wdata;
       7: reg7 = uP_wdata;
       8: cmd  = uP_wdata;
       9: port_out_1 = uP_wdata[5:0];
      12: iq_address[15:0]  = uP_wdata;
      13: iq_address[19:16] = uP_wdata[3:0];
      14: data_from_iq      = uP_wdata[7:0];
// ...
    endcase
// The processor bus here is an -asynchronous- bus: it has no accompanying
// clock.  The register enables are gated combinatorially.  This is increasingly
// unusual and a style which is largely deprecated.  Only do this a) if forced;
// b) after acquiring a reasonable amount of experience.  It is easy to
// introduce timing problems, plus (on modern FPGAs) implementation (synthesis)
// may be inefficient.

// Register reads
always @ (uP_address, reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7,
          status, port_out_1, iq_address, data_to_iq)
  case (uP_address)
     0: uP_rdata = reg0;
     1: uP_rdata = reg1;
     2: uP_rdata = reg2;
     3: uP_rdata = reg3;
     4: uP_rdata = reg4;
     5: uP_rdata = reg5;
     6: uP_rdata = reg6;
     7: uP_rdata = reg7;

     9: uP_rdata = {10'h000, port_out_1};
    12: uP_rdata = iq_address[15:0];
    13: uP_rdata = {12'h000, iq_address[19:16]};
    14: uP_rdata = {8'h00, data_to_iq};		// iq_busy ?? @@@@

    15: uP_rdata = status;			// Temporary parking address @@@
/*
    16: uP_rdata = cur_address[15:0];		// Address (low)
    17: uP_rdata = {14'd0, iq_address[17:16]};	// Address (high)
    18: uP_rdata = (two_pixels || (last_hword == 1'b0)) ? reg2 : reg3;
						// Data (sync.) L
    19: uP_rdata = reg3;			// Data (sync.) H
    21: uP_rdata = 8'h1B;			// Version indication ****
      
// ...
*/
    default: uP_rdata = 16'h2A2A;		// Obvious pattern for debug
  endcase

assign clr_irq = !uP_ncs && !uP_nrd && (uP_address == 15);
// TEMP *** will always clear request before it can be seen by processor   @@@

always @ (posedge uP_nwr)			// Set direction for FS access
if (!uP_ncs)
  if (uP_address == 6'h0E) iq_rnw <= 0;
  else                     iq_rnw <= 1;

// The following deals with entering the internal clock domain.
// You can cross-reference this with your notes if interested.
always @ (posedge uP_nwr, posedge cmd_ack)	// Byte selects?
if (cmd_ack)
  begin
  go <= 0;
  end
else
  if (!uP_ncs)
    if (uP_address == 6'h08)
       go <= 1;

// Synchroniser flip-flops taking processor DE request into local clock domain
always @ (posedge clk, posedge cmd_ack)
if (cmd_ack)
  begin
  go_1 <= 0;
  go_2 <= 0;
  end
else
  begin
  go_1 <= go;
  go_2 <= go_1;
  end

// Synchroniser flip-flops taking processor IQ request into local clock domain
always @ (posedge uP_nwr, posedge iq_ack)
if (iq_ack)
  begin
  gg <= 0;
  end
else
  if (!uP_ncs)
    if ((uP_address == 6'h0E) || (uP_address == 6'h0D) || (uP_address == 6'h0C))
      gg <= 1;

always @ (posedge clk, posedge iq_ack)
if (iq_ack)
  begin
  gg_1 <= 0;
  gg_2 <= 0;
  end
else
  begin
  gg_1 <= gg;
  gg_2 <= gg_1;
  end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @ (frame_over, clr_irq)		// RS flip-flop
if (frame_over)   frame_irq <= 1;
else if (clr_irq) frame_irq <= 0;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

endmodule
