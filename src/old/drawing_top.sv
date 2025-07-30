/* This file defines specific resources used on the FPGA implementation, such */
/* as the pad names.  You can look, but DON'T TOUCH!  It works in concert     */
/* the -constraints- file (.../resource/constraints.ucf) which maps the pads  */
/* to specific locations on the FPGA package and, hence, the PCB.             */

`timescale 1ns / 10ps 
`default_nettype none
 
module drawing_top ( 
      input  wire        top_clk,
      output wire  [5:0] LED_pad,
      output wire [14:0] pixel_pad,
      output wire [17:0] fs_a_pad,
      output wire        fs_noe_pad,
      output wire  [1:0] fs_ncs_pad,
      output wire        fs_nwe_pad,
      output wire  [3:0] fs_nbs_pad,
      output wire        hsync_pad,
      output wire        vsync_pad,
      output wire        irq_pad,
      input  wire  [1:0] nBS_pad,
      input  wire  [6:1] A_pad,
      input  wire        nRD_pad,
      input  wire        nWR_pad,
      input  wire        nCS_pad,
      output wire [15:0] DBUS_pad,
      output wire [31:0] fs_dw_pad,
      input  wire  [5:0] SW_pad );
 
// Buses in the design

wire clk;
wire clk2;

// Clocks
// Creates clock signal and half frequency clock
wire buffered_clk;
IBUF clk_buf(.I(top_clk), .O(buffered_clk));
BUFG clk2_buf_o(.I(buffered_clk), .O(clk2));

// Clk 2 through ff
wire buffered_clk_q;
wire clk2_ff_d;
FD clk2_ff (.C(buffered_clk), .D(clk2_ff_d), .Q(buffered_clk_q));
INV clk2_inv (.I(buffered_clk_q), .O(clk2_ff_d));
BUFG clk_buf_o (.I(buffered_clk_q), .O(clk));

wire    [5:0]  LED;
wire    [5:0]  SW;
wire    [1:0]  fs_ncs;
wire   [15:0]  DOUT;
wire    [6:1]  A;
wire   [17:0]  fs_a;
wire    [7:0]  pix; //
wire   [31:0]  fs_dr;
wire   [31:0]  fs_dw;
wire           fs_noe;
wire           fs_nwe;
wire           hsync;
wire           irq;
wire           vsync;
wire    [3:0]  fs_nbs;
wire    [1:0]  nBS;
wire   [8:15]  P;
wire   [14:0]  pixel;		// The video DACs are 5-bit (x3 for RGB)
wire   [15:0]  DIN;

wire           nCS;
wire           nRD;
wire           nWR;

wire           T_DOUT;		// Direction control on bidirectional buses
wire           T_dio_15_0;
wire           T_dio_31_16;

/*
wire reset;
GND reset_ground (.G(reset));
*/
wire        reset = 1'b0;	// Not needed for this FPGA implementation

assign T_DOUT = nCS | nRD;

//  IO Buffers

//  Input Buffers
IBUF SW_buf [5:0] (.I(SW_pad[5:0]), .O(SW[5:0])); 
IBUF nBS_buf [1:0] (.I (nBS_pad[1:0]), .O(nBS[1:0]));
IBUF A_buf [6:1] (.I (A_pad[6:1]), .O(A[6:1]));
IBUF nRD_buf (.I(nRD_pad), .O(nRD));
IBUF nWR_buf (.I(nWR_pad), .O(nWR));
IBUF nCS_buf (.I(nCS_pad), .O(nCS));

// Output Buffers
OBUF LED_buf    [5:0] (.I(LED[5:0]), .O(LED_pad[5:0]));
OBUF pixel_buf [14:0] (.I(pixel[14:0]), .O(pixel_pad[14:0]));
OBUF fs_a_buf  [17:0] (.I(fs_a[17:0]), .O(fs_a_pad[17:0]));
OBUF fs_noe_buf       (.I(fs_noe), .O(fs_noe_pad));
OBUF fs_ncs_buf [1:0] (.I(fs_ncs[1:0]), .O(fs_ncs_pad[1:0]));
OBUF fs_nwe_buf       (.I(fs_nwe), .O(fs_nwe_pad));
OBUF fs_nbs_buf [3:0] (.I(fs_nbs[3:0]), .O(fs_nbs_pad[3:0]));
OBUF hsync_buf        (.I(hsync), .O(hsync_pad));
OBUF vsync_buf        (.I(vsync), .O(vsync_pad));
OBUF irq_buf          (.I(irq),   .O(irq_pad));

// DIN DOUT
IBUF DIN_buf [15:0] (.I(DBUS_pad[15:0]), .O(DIN[15:0])); 
OBUFT DOUT_buf [15:0] (.I(DOUT[15:0]), .O(DBUS_pad[15:0]), .T(T_DOUT));

// Framestore [15:0]
assign T_dio_15_0 = ! ( (fs_noe) & (!fs_ncs[0]));
IBUF fs_dr_buf [15:0] (.I(fs_dw_pad[15:0]), .O(fs_dr[15:0]));
OBUFT fs_dw_buf [15:0] (.I(fs_dw[15:0]), .O(fs_dw_pad[15:0]), .T(T_dio_15_0));

// Framestore [31:16]
assign T_dio_31_16 = !( (fs_noe) & !(fs_ncs[1]));
IBUF fs_dr_buf_high [31:16] (.I(fs_dw_pad[31:16]), .O(fs_dr[31:16]));
OBUFT fs_dw_buf_high [31:16] (.I(fs_dw[31:16]), .O(fs_dw_pad[31:16]),
                                                .T(T_dio_31_16));

// Pixel buffers
/*
BUF  I374 ( .I(pix[7]), .O(pixel[14]));
BUF  I375 ( .I(pix[6]), .O(pixel[13]));
BUF  I376 ( .I(pix[5]), .O(pixel[12]));
BUF  I380 ( .I(pix[7]), .O(pixel[11]));
BUF  I379 ( .I(pix[6]), .O(pixel[10]));
BUF  I378 ( .I(pix[4]), .O(pixel[9]));
BUF  I377 ( .I(pix[3]), .O(pixel[8]));
BUF  I381 ( .I(pix[2]), .O(pixel[7]));
BUF  I382 ( .I(pix[4]), .O(pixel[6]));
BUF  I383 ( .I(pix[3]), .O(pixel[5]));
BUF  I384 ( .I(pix[1]), .O(pixel[4]));
BUF  I388 ( .I(pix[0]), .O(pixel[3]));
BUF  I387 ( .I(pix[1]), .O(pixel[2]));
BUF  I386 ( .I(pix[0]), .O(pixel[1]));
BUF  I385 ( .I(pix[1]), .O(pixel[0]));
*/
assign pixel[14:10] = {pix[7:5], pix[7:6]};
assign pixel[9:5]   = {pix[4:2], pix[4:3]};
assign pixel[4:0]   = {pix[1:0], pix[1:0], pix[1]};

drawing_main system ( .clk(clk),	// Instantiate chip 'core'
// .clk2(clk2),
                      .reset(reset),
                      .uP_ncs(nCS),
                      .uP_address(A[6:1]),
                      .uP_nbs(nBS[1:0]),
                      .uP_nrd(nRD),
                      .uP_nwr(nWR), 
                      .uP_wdata(DIN[15:0]),
                      .uP_rdata(DOUT[15:0]),
                      .uP_irq(irq),
                      .fs_ncs(fs_ncs[1:0]),
                      .fs_address(fs_a[17:0]),
                      .fs_nbyte_sel(fs_nbs[3:0]),
                      .fs_noe(fs_noe),
                      .fs_nwe(fs_nwe),
                      .fs_wdata(fs_dw[31:0]),
                      .fs_rdata(fs_dr[31:0]),
                      .pixel(pix[7:0]),
                      .hsync(hsync),
                      .vsync(vsync),
                      .switch(SW[5:0]),
                      .LED(LED[5:0]));

endmodule

`default_nettype wire
