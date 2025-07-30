/*
    Daryl O'Brien
    Version 1.0
    25/09/08

    MemoryChannel.v - Handles memory request

    Based on code written by plana, jpepper, lbrackenbury, dclark, jgarside

    Last Modified 9/1/15

*/

// -----------------------------------------------------------------------------
//
//  This module accepts synchronised requests from three clients.  Conflicts are
// arbitrated and prioritised in the following order:
//
//	VDU - read only access
//
//	Camera - write only access
//
//	Processor - read/write access
//
//  Memory cycles take two clock periods and the multiplexing and timing is
// generated within this block.  When a request is serviced it is acknowledged
// by a one-cycle high pulse during the first half of the memory access.  This
// allows time for the request to be withdrawn before the end of the cycle when
// the next arbitration takes place.  When writing, buses are latched within.
// However when reading the client must note the acknowledge and latch data on
// the -subsequent- rising clock edge.
//
// -----------------------------------------------------------------------------

`define TPD 2

`timescale 1ns / 10ps 
module drawing_mem_ctrl (
                  input  wire        clk,		//FPGA Clock
                  input  wire        reset,		//
		  input  wire        iq_req,		//Stuff to/from iq
		  output reg         iq_ack,
                  input  wire [17:0] iq_address,
		  input  wire  [3:0] iq_nbyte,
		  input  wire        iq_rnw,
		  input  wire [31:0] data_from_iq,
		  output wire [31:0] data_to_iq,
		  input  wire        vdu_req,		//Stuff to VDU
		  output  reg        vdu_ack,
		  input  wire [17:0] vdu_address,
		  output wire [31:0] vdu_data,
		  input  wire        de_req,		//Stuff from drawing engine
		  output reg         de_ack,
		  input  wire [17:0] de_address,
		  input  wire  [3:0] de_nbyte,
		  input  wire        de_rnw,
		  input  wire [31:0] de_wdata,
		  output wire [31:0] de_rdata,
		  output reg  [17:0] fs_address,	//Stuff to/from fs
		  output reg   [1:0] fs_ncs,
		  output reg         fs_noe,
		  output reg         fs_nwe,
		  output reg   [3:0] fs_nbyte_sel,
		  input  wire [31:0] fs_rdata,
		  output reg  [31:0] fs_wdata
		  );

reg        mem_state;		// Counts states during memory access
reg [1:0]  granted;		// Diagnostic: indicates what memory is doing

reg        pre_nwe;		// Rising edge synchronised nWE

initial mem_state = 0;
initial fs_ncs    = 2'b00;
initial fs_noe    = 1;
initial pre_nwe   = 1;

always @ (posedge clk, posedge reset)
if (reset)
  begin						// Reset state
  mem_state <= 0;
  fs_ncs    <= #`TPD 2'b00;
  fs_noe    <= #`TPD 1;
  pre_nwe   <= #`TPD 1;
  end
else
  if (mem_state == 0)
    begin
    mem_state <= 1;				// Do 'nothing' in second half of cycle
    vdu_ack   <= #`TPD 0;
    de_ack    <= #`TPD 0;
    iq_ack    <= #`TPD 0;
    pre_nwe   <= 1;
    end
  else
    begin
    mem_state <= 0;				// Approaching new memory cycle
    if (vdu_req)				// Arbitrate first for VDUC
      begin
      granted  <= 1;				// Diagnostic only
      vdu_ack  <= #`TPD 1;			// Acknowledge
      fs_noe   <= #`TPD 0;			// Read
      pre_nwe  <= 1;				// not Write
      fs_ncs   <= #`TPD 2'b00;			// Select
      fs_nbyte_sel <= #`TPD 4'b0000;		// All bytes
      fs_address   <= #`TPD vdu_address;
      end
    else
      if (iq_req)				// If not VDUC then try processor
        begin
        granted  <= 3;				// Diagnostic only
        iq_ack   <= #`TPD 1;			// Acknowledge
        fs_noe   <= #`TPD!iq_rnw;		// Can be read ...
        pre_nwe  <= iq_rnw;			// ... or write
        fs_ncs   <= #`TPD 2'b00;		// Select
        fs_nbyte_sel <= #`TPD iq_nbyte;		// Specified bytes only
        fs_address   <= #`TPD iq_address;
        fs_wdata     <= #`TPD data_from_iq;	// Write data if appropriate
        end
      else
        if (de_req)
          begin
          granted  <= 2;			// Diagnostic only
          de_ack   <= #`TPD 1;			// Acknowledge
          fs_noe   <= #`TPD!de_rnw;		// Can now be read ...
          pre_nwe  <= #`TPD de_rnw;		// ... or write
          fs_ncs   <= #`TPD 2'b00;		// Select
          fs_nbyte_sel <= #`TPD de_nbyte;	// Selected byte
          fs_address   <= #`TPD de_address;
          fs_wdata     <= #`TPD de_wdata;	// Latch data
          end
        else
          begin					// No requests
          granted  <= 0;			// Diagnostic only
          fs_noe   <= #`TPD 1;			// not Read
          pre_nwe  <= 1;			// not Write
          fs_ncs   <= #`TPD 2'b11;		// Don't select
          fs_nbyte_sel <= #`TPD 4'b1111;	// No bytes
          end
    end

always @ (negedge clk) fs_nwe <= #`TPD pre_nwe;	// Half clock delay to form write pulse

assign vdu_data   = fs_rdata;		// Alias for read data
assign data_to_iq = fs_rdata;
assign de_rdata   = fs_rdata;

endmodule
