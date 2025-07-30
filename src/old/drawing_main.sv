// Drawing main Module
//
// Revised: September 2023
//
// This integrates the whole 'core' of the SoC and includes the 'drawing_engine'
// accelerator as one component.

`timescale 1ns / 10ps

module drawing_main (input  wire        clk,		// Global control
                     input 	        reset,
							// Processor interface
                     input 	        uP_ncs,		// FPGA select
                     input  wire  [6:1] uP_address,	// Lower address bits
                     input  wire  [1:0] uP_nbs,		// Byte selects
                     input 	        uP_nrd,		// Read strobe
                     input 	        uP_nwr,		// Write strobe
                     output wire [15:0] uP_rdata,	// Load data
                     input  wire [15:0] uP_wdata,	// Store data
                     output wire        uP_irq,		// Interrupt request

							// Framestore interface
                     output wire  [1:0] fs_ncs,		// RAM selects (2 ICs)
                     output wire [17:0] fs_address,	// Address
                     output wire  [3:0] fs_nbyte_sel,	// Byte (pixel) selects
                     output wire        fs_noe,		// Output enable (Read)
                     output wire        fs_nwe,		// Write enable
                     output wire [31:0] fs_wdata,	// Output data
                     input  wire [31:0] fs_rdata,	// Read data

                     output wire  [7:0] pixel,		// Pixel to DACs
                     output wire        vsync,		// Vertical sync.
                     output wire        hsync,		// Horizontal sync.

                     output wire        test_0,		// Sundry test outputs
                     output wire        test_1,
                     output wire        test_2,
                     input  wire  [5:0] switch,		// Input buttons
                     output wire  [5:0] LED);		// Status LEDs

// Buses in the design

wire         cmd_req;				// Bus from processor interface
wire         cmd_ack;				// to drawing engine
wire  [15:0] cmd;
wire         cmd_busy;
wire  [15:0] r0, r1, r2, r3, r4, r5, r6, r7;	// Parameters

wire         cmd_iq_req;			// Bus from processor interface
wire         cmd_iq_ack;			// to 'direct' framestore port
wire  [19:0] cmd_iq_address;
wire         cmd_iq_rnw;
wire         cmd_iq_busy;

wire         iq_req;				// Bus from 'direct' port
wire         iq_ack;				// to framestore memory
wire         iq_rnw;
wire  [17:0] iq_address;
wire  [31:0] iq_w_data;
wire   [3:0] iq_nbyte;
wire  [31:0] iq_r_data;

wire         de_req;				// Bus from drawing engine
wire         de_ack;				// to framestore memory
wire         de_rnw;
wire  [31:0] de_wdata;
wire   [3:0] de_nbyte;
wire   [7:0] data_from_iq;
wire  [17:0] de_address;
wire  [31:0] de_rdata;

wire         vdu_req;				// Bus from VDU controller
wire         vdu_ack;				// to framestore memory
wire  [17:0] vdu_address;
wire  [31:0] vdu_data;
wire   [7:0] data_to_iq;

wire         frame_over;			// For synchronising drawing
wire         v_blank;				// with display
wire         h_blank;				// (e.g. for animation)

wire   [5:0] nSwitch;				// Auxiliary I/O
wire   [5:0] nLED;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
// Instantiate processor interface

drawing_command
        Proc_interface (.clk(clk),
                        .reset(reset),

                        .uP_address(uP_address),
                        .uP_nbs(uP_nbs),
                        .uP_wdata(uP_wdata),
                        .uP_rdata(uP_rdata),
                        .uP_ncs(uP_ncs),
                        .uP_nwr(uP_nwr),
                        .uP_nrd(uP_nrd),
                        .uP_irq(uP_irq),
                        .cmd_req(cmd_req),
                        .cmd_ack(cmd_ack),
                        .r0(r0),
                        .r1(r1),
                        .r2(r2),
                        .r3(r3),
                        .r4(r4),
                        .r5(r5),
                        .r6(r6),
                        .r7(r7),
                        .command(cmd),
                        .cmd_busy(cmd_busy),
                        .iq_req(cmd_iq_req),
                        .iq_ack(cmd_iq_ack),
                        .iq_address(cmd_iq_address),
                        .iq_rnw(cmd_iq_rnw),
                        .data_from_iq(data_from_iq),
                        .data_to_iq(data_to_iq),
                        .iq_busy(cmd_iq_busy),
                        .v_blank(v_blank),
                        .frame_over(frame_over),
                        .port_out_1(nLED),
                        .port_in_1(nSwitch));

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Instantiate drawing engine                                                 */

drawing_engine Drawing_Engine(.clk(clk),

                              .req(cmd_req),		// Commands from
                              .ack(cmd_ack),		// processor
                              .cmd(cmd[15:0]),
                              .r0(r0[15:0]),
                              .r1(r1[15:0]),
                              .r2(r2[15:0]),
                              .r3(r3[15:0]),
                              .r4(r4[15:0]),
                              .r5(r5[15:0]),
                              .r6(r6[15:0]),
                              .r7(r7[15:0]),
                              .busy(cmd_busy),

                              .de_req(de_req),		// Connection to
                              .de_ack(de_ack),		// framestore (manager)
                              .de_rnw(de_rnw),
                              .de_addr(de_address[17:0]),
                              .de_nbyte(de_nbyte[3:0]),
                              .de_data(de_wdata[31:0]),
                              .de_rd_data(de_rdata[31:0]));

// If the whole bus is used there is no need to specify the range of signals.
// e.g. here "de_rdata" could be used instead of "de_rdata[31:0]".
// If a subset of the bus is used then this needs to be specified.

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Instantiate other 'central' components                                     */

drawing_iq IQ ( .clk            (clk),
                .cmd_iq_req     (cmd_iq_req),        /* Bus from uP interface */
                .cmd_iq_ack     (cmd_iq_ack),        /* to "inquisitor" block */
                .cmd_iq_rnw     (cmd_iq_rnw),
                .cmd_iq_busy    (cmd_iq_busy),
                .cmd_iq_address (cmd_iq_address),
                .cmd_iq_w_data  (data_from_iq),
                .cmd_iq_r_data  (data_to_iq),
                .iq_w_data      (iq_w_data),          /* Bus onward to memory */
                .iq_r_data      (iq_r_data),          /* controller           */
                .iq_address     (iq_address),
                .iq_nbyte       (iq_nbyte),
                .iq_rnw         (iq_rnw),
                .iq_req         (iq_req),
                .iq_ack         (iq_ack));

drawing_vduc vduc (.clk         (clk),                      /* VDU controller */
                   .frame_over  (frame_over),
                   .vdu_address (vdu_address),  /* Fetches from framestore... */
                   .vdu_data    (vdu_data),
                   .vdu_req     (vdu_req),
                   .vdu_ack     (vdu_ack),
                   .v_sync_out  (vsync),
                   .h_sync_out  (hsync),
                   .pixel_out   (pixel),     /* ... outputs to display device */
                   .v_blank     (v_blank),
                   .h_blank     (h_blank));

// Interconnection here done in a different (older) Verilog style using signal
// order rather than explicit connections.
// This is for illustration - not a particular recommendation!
drawing_mem_ctrl mem_ctrl ( clk, reset, iq_req, iq_ack,
     iq_address[17:0], iq_nbyte[3:0], iq_rnw, iq_w_data[31:0],
     iq_r_data[31:0], vdu_req, vdu_ack, vdu_address[17:0],
     vdu_data[31:0], de_req, de_ack, de_address[17:0], de_nbyte[3:0],
     de_rnw, de_wdata[31:0], de_rdata[31:0], fs_address[17:0],
     fs_ncs[1:0], fs_noe, fs_nwe, fs_nbyte_sel[3:0], fs_rdata[31:0],
     fs_wdata[31:0]);
// That is the framestore memory arbiter and multiplexers.

// Sundry extra board connections
assign nSwitch = ~switch;
assign LED     = ~nLED;
assign test_0 = 1'b0;				// Potential test points
assign test_1 = 1'b0;				// Lose?
assign test_2 = 1'b0;

endmodule // drawing_main
