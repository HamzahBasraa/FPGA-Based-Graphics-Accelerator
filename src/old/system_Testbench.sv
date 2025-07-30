/******************************************************************************/
/* Module:   system_Testbench                                                 */
/* Modified: September 2023                                                   */
/* Author:   J Garside, JSP                                                   */
/*                                                                            */
/* Description:                                                               */
/*                                                                            */
/* Example test stimulus for drawing_main schematic design                    */
/* External 'world' model comprising framestore memory and simulated display  */
/*                                                                            */
/* Modified by JSP 21-01-2019, framestore reads requires                      */
/* fs_nbyte_sel[0..3] being activated                                         */
/*                                                                            */
/******************************************************************************/

`define R0  6'h00
`define R1  6'h01
`define R2  6'h02
`define R3  6'h03
`define R4  6'h04
`define R5  6'h05
`define R6  6'h06
`define R7  6'h07
`define GO  6'h08

`timescale 1ns / 10ps
`include "../COMP32211/video_definitions.sv"

module system_Testbench();

// Setup params for test bench
reg          clk;					// Inputs are 'reg's
reg          reset;

reg          uP_ncs;					// Processor interface
reg   [6:1]  uP_address;
reg   [1:0]  uP_nbs;
reg          uP_nrd;
reg          uP_nwr;
reg  [15:0]  uP_wdata;
wire [15:0]  uP_rdata;
wire         uP_irq;

wire  [1:0]  fs_ncs;					// Framestore interface
wire [17:0]  fs_address;
wire  [3:0]  fs_nbyte_sel;
wire         fs_noe;
wire         fs_nwe;
wire [31:0]  fs_wdata;
reg  [31:0]  fs_rdata;

wire  [7:0]  pixel;					// Video interface
wire         hsync;
wire         vsync;

wire         test_0;					// Miscellaneous
wire         test_1;
wire         test_2;
wire  [5:0]  LED;
reg   [5:0]  switch;

reg   [15:0] status;		// Tester's copy of status register

// Instantiate drawing top
drawing_main top(.clk          (clk),
                 .reset        (reset),
               // Processor interface
                 .uP_ncs       (uP_ncs),		// Device select
                 .uP_address   (uP_address),		// Address
                 .uP_nbs       (uP_nbs),		// (not) Byte select
                 .uP_nrd       (uP_nrd),		// (not) Read
                 .uP_nwr       (uP_nwr),		// (not) Write
                 .uP_rdata     (uP_rdata),		// Read data bus
                 .uP_wdata     (uP_wdata),		// Write data bus
                 .uP_irq       (uP_irq),		// Interrupt request
               // Framestore interface
                 .fs_ncs       (fs_ncs),		// Framestore select
                 .fs_address   (fs_address),		// Framestore address
                 .fs_nbyte_sel (fs_nbyte_sel),		// ... (not) byte select
                 .fs_noe       (fs_noe),		// ... (not) output
                 .fs_nwe       (fs_nwe),		// ... (not) write
                 .fs_wdata     (fs_wdata),		// ... write data
                 .fs_rdata     (fs_rdata),		// ... read data
               // Screen interface
                 .vsync        (vsync),			// Vertical sync.
                 .hsync        (hsync),			// Horizontal sync.
                 .pixel        (pixel),			// Colour value

                 .test_0       (test_0),
                 .test_1       (test_1),
                 .test_2       (test_2),
                 .LED          (LED),
                 .switch       (switch));

`define LINE  1
`define CHAR  0

/*----------------------------------------------------------------------------*/
// Stop simulator running after a frame scan
initial
begin
#20000000;		// 20 million ns = 20 ms or 1/50th of a second
$stop;			// VGA has a 60 fps frame rate -- so just over 1 frame
end

/*----------------------------------------------------------------------------*/
/* Clock generator used for DUT and frame store                               */

initial    clk = 1'b1;
always #20 clk <= !clk;	// 20 ns half-period = 40 ns period => 25 MHz pixel rate

/*----------------------------------------------------------------------------*/
// Reset DUT (Device Under Test)

initial
 begin
  reset <= 1'b0;
  repeat (5) @ (posedge clk);
  #2 reset <= 1'b1;				// Delayed: not preferred form
  repeat (2) @ (posedge clk);			// Will resync. to clock
  reset <= #2 1'b0;				// Probably better delay form
 end

// In this instance all resetting will performed by the FPGA loading (or
// 'initial' statements in simulation) and the signal is unused.
// In an ASIC this would be important and the driver is left here as a reminder.

/*----------------------------------------------------------------------------*/
/* Microprocessor end of test bench                                           */

//               **** Area to develop sequences of test stimuli ****

initial
begin

//            **** Develop, replace, augment etc. with your stuff ****


uP_ncs     <=  1'b1;				// Define bus outputs (inactive)
uP_address <=  6'h00;
uP_nbs     <=  2'b11;
uP_nrd     <=  1'b1;
uP_nwr     <=  1'b1;
uP_wdata   <= 16'h0000;

// wait until the drawing engine is not busy
#200 bus_read(15, status);
while(status[1])				// Processor polls device
  #200 bus_read(15, status);			// (asynchronously)

/*----------------------------------------------------------------------------*/
//Draw a white line starting at (100,100) and finishing at (200,130)

pre_process_line(100, 100, 200, 130, 255);

// wait until the drawing engine has finished drawing shape
#200 bus_read(15, status);

#300000;

end // Finished sending drawing commands

/*----------------------------------------------------------------------------*/
// The given line drawing engine assumes software preprocessing

task pre_process_line(input [15:0] x0, y0, x1, y1, colour);

reg [15:0] dx, dy, adx, ady;            // Coordinate differences & abs()
reg [15:0] sx, sy;                      // Pixel address steps
reg [15:0] m, n;                        // Larger/smaller absolute differences
reg [15:0] a1, a2;                      // Steps in major axis/both axes
reg [19:0] start_addr;                  // start address of line

begin
  dx = x1 - x0;
  dy = y1 - y0;
  if (dx[15]) begin sx =   -1; adx = -dx; end else begin sx =   1; adx = dx; end
  if (dy[15]) begin sy = -640; ady = -dy; end else begin sy = 640; ady = dy; end
  if (adx > ady) begin a1 = sx; m = adx; n = ady; end
  else           begin a1 = sy; m = ady; n = adx; end
  a2 = sx + sy;

  start_addr = y0*`X_SIZE + x0;

// Text report to log file (Probably "transcript" in Questa)
$display("Values: %h %h %h %h %h %h %h", m,n,a1,a2, start_addr[15:0],
                                                    start_addr[19:16], colour);
// Now call task to output parameters
draw_line(m, n, a1, a2, start_addr[15:0], start_addr[19:16],  colour);

end
endtask

/*----------------------------------------------------------------------------*/
// This task executes a sequence of write (STRH) operations to trigger a
// line drawing operation

task draw_line(input [15:0] r0, r1, r2, r3, r4, r5, r6);
begin
bus_write(`R0, r0);		// abs(Larger difference)
bus_write(`R1, r1);		// abs(Smaller difference)
bus_write(`R2, r2);		// Primary step
bus_write(`R3, r3);		// Both steps
bus_write(`R4, r4);		// Address (L)
bus_write(`R5, r5);		// Address (H)
bus_write(`R6, r6);		// Colour
bus_write(`GO, `LINE);		// Command
end
endtask

/*----------------------------------------------------------------------------*/
// Microprocessor register write task
// This task is asynchronous; it is not related to the system clock in any way

task bus_write(input [5:0] addr, input [15:0] data);
begin
uP_ncs     = 1'b0;		// Select the FPGA
uP_address = addr;		// Set the register address 'within' the FPGA
uP_wdata   = data;		// Set up data to write
#10				// Allow some set up time
uP_nwr     = 1'b0;		// Activate write strobe
#15				// Wait for 'Pulse width'
uP_nwr     = 1'b1;		// Deactivate write strobe
#10				// Hold time
uP_ncs     = 1'b1;		// Deselect the FPGA
end
endtask

/*----------------------------------------------------------------------------*/
// Microprocessor register read task
// This task is asynchronous; it is not related to the system clock in any way

task bus_read(input [5:0] addr, output [15:0] data);
begin
uP_ncs     = 1'b0;		// You can work out the sequence as an exercise!
uP_address = addr;
uP_nwr     = 1'b1;		// Shouldn't be needed
#25				// As implemented, the selected FPGA will 'read'
data   = uP_rdata;		// by default.
#10				
uP_ncs     = 1'b1;		
end
endtask

/*----------------------------------------------------------------------------*/
/* Stimulus end of test bench                                                 */
/*============================================================================*/


/*============================================================================*/
/* These routines provide the framestore and simulated display                */
/* (i.e. environment outside the SoC).                                        */

/* Start virtual screen to display shapes                                     */
initial $start_screen("-k123", "-c332", "-s1");

/* Simple test diagnostics                                                    */
integer line_count;
always @ (posedge hsync)
if (vsync) line_count <= 0;
else       line_count <= line_count + 1;

/* (Crude) SRAM model to represent frame store                                */
reg [7:0] frame_store0 [0:131071];	// 0.5 MB SRAM
reg [7:0] frame_store1 [0:131071];	//
reg [7:0] frame_store2 [0:131071];	//
reg [7:0] frame_store3 [0:131071];	//
reg [7:0] out_reg0, out_reg1, out_reg2, out_reg3;

// Make into a 'properly' timed async. SRAM @@@
integer fs_addr_t, fs_ncs_t, fs_noe_t, fs_nwe_t;
reg data_valid;

integer i;

initial
for (i = 0; i < 131072; i = i + 1)	// Blank screen, simulation hack
  begin
  frame_store0[i] = 8'h00;
  frame_store1[i] = 8'h00;
  frame_store2[i] = 8'h00;
  frame_store3[i] = 8'h00;
  end

initial
for (i = 0; i < 76800; i = i + 1)      // Blank virtual screen screen
  begin
   $write_screen(123, 0, i, 0);
   $write_screen(123, 1, i, 0);
   $write_screen(123, 2, i, 0);
   $write_screen(123, 3, i, 0);
  end


always @ (fs_address) fs_addr_t = $time;
always @ (fs_ncs)     fs_ncs_t  = $time;
always @ (fs_nwe)     fs_nwe_t  = $time;
always @ (fs_noe)     fs_noe_t  = $time;

// Work out if the inputs have been stable for long enough for output stability
always #1
begin
if (!fs_ncs && !fs_noe && fs_nwe && ($time > (fs_addr_t + 55))
                                 && ($time > (fs_ncs_t + 55))
                                 && ($time > (fs_noe_t + 10))
                                 && ($time > (fs_nwe_t + 10)))
  data_valid = 1;
else
  data_valid = 0;
end

// Only return defined answer when SRAM guaranteed stable.
always @ (data_valid, out_reg3, out_reg2, out_reg1, out_reg0)
begin
#1
if (data_valid) fs_rdata = {out_reg3, out_reg2, out_reg1, out_reg0};
else            fs_rdata = 32'hxxxxxxxx;
end

// For simulation purposes this testbench catches framestore accesses and
// implements a memory.  Write operations are duplicated using an added
// "$write_screen" call which services the interface to the mock-up screen.

always @ (posedge clk)		// Shouldn't really be clocked :-/ @@@@
begin
if (!fs_ncs[0])
  if (!fs_nwe)
    begin
    if (!fs_nbyte_sel[0])
      begin
      frame_store0[fs_address[16:0]] <= fs_wdata[7:0];
      $write_screen(123, 0, fs_address[16:0], fs_wdata[7:0]);
      end
    if (!fs_nbyte_sel[1])
      begin
      frame_store1[fs_address[16:0]] <= fs_wdata[15:8];
      $write_screen(123, 1, fs_address[16:0], fs_wdata[15:8]);
      end
    end
  else
    if (!fs_noe)
      begin
      if (!fs_nbyte_sel[0]) out_reg0 <= frame_store0[fs_address[16:0]];
      else                  out_reg0 <= 8'hxx;	// Helps to highlight problems
      if (!fs_nbyte_sel[1]) out_reg1 <= frame_store1[fs_address[16:0]];
      else                  out_reg1 <= 8'hxx;
      end
if (!fs_ncs[1])
  if (!fs_nwe)
    begin
    if (!fs_nbyte_sel[2])
      begin
      frame_store2[fs_address[16:0]] <= fs_wdata[23:16];
      $write_screen(123, 2, fs_address[16:0], fs_wdata[23:16]);
      end
    if (!fs_nbyte_sel[3])
      begin
      frame_store3[fs_address[16:0]] <= fs_wdata[31:24];
      $write_screen(123, 3, fs_address[16:0], fs_wdata[31:24]);
      end
    end
  else
    if (!fs_noe)
      begin
      if (!fs_nbyte_sel[2]) out_reg2 <= frame_store2[fs_address[16:0]];
      else                  out_reg2 <= 8'hxx;
      if (!fs_nbyte_sel[3]) out_reg3 <= frame_store3[fs_address[16:0]];
      else                  out_reg3 <= 8'hxx;
      end
end

/* Frame store end of test bench                                              */
/*============================================================================*/

endmodule // testbench

/*============================================================================*/
