/**

    Module:        drawing_vduc

    Description:   This module mocks the interfaces for the drawing engine with the video display unit controller (VDUC).
                   It handles bus requests and responses, and provides the necessary signals for video output.  

    Authors:       James Garside & Anthony Mathews
    Updated:       July 2025  

*/
module drawing_vduc (   input  wire        clk,
                        input  wire        pixclk,
                        input  wire        clk_TMDS,
                        input  wire        reset,
                        input  wire        cs_i,
                        input  wire        read_i,
                        input  wire        write_i,
                        input  wire [31:0] address_i,
                        input  wire  [1:0] size_i,
                        input  wire  [1:0] mode_i,
                        output wire        stall_o,
                        output wire  [2:0] abort_v_o,
                        input  wire [31:0] data_in,
                        output reg  [31:0] data_out,
                        output wire  [1:0] vduc_ireq_o,
                        
                        output wire  [9:0] v_width_o,
                        output wire  [9:0] v_height_o,
                        output wire  [1:0] v_mode_o,
                        output wire [17:0] v_frame_o,

                        output wire        fs_read_o,
                        input  wire        fs_wait_i,
                        output wire [17:0] fs_addr_o,
                        input  wire [31:0] fs_data_i,

                        output reg         TMDS_shift_blue_o,
                        output reg         TMDS_shift_green_o,
                        output reg         TMDS_shift_red_o
             ); 

reg  [31:0] H_BP;                                    /* Horizontal back porch */
reg  [31:0] H_ACTIVE_END;                    /* Horizontal active line length */
reg  [31:0] H_FP;                                   /* Horizontal front porch */
parameter   H_SYNC_LEN    = 128; 
reg  [31:0] H_LINE;                                      /* Total line length */

wire [31:0] H_SYNC_START  = H_ACTIVE_END + H_FP; 
wire [31:0] H_SYNC_END    = H_SYNC_START + H_SYNC_LEN;

reg  [31:0] V_BP;                                      /* Vertical back porch */
reg  [31:0] V_ACTIVE_END;                       /*Vertical active line number */
reg  [31:0] V_FP;                                     /* Vertical front porch */
parameter V_SYNC_LEN      = 4;
reg  [31:0]  V_SCREEN;                               /* Total number of lines */

wire [31:0] V_SYNC_START  = V_ACTIVE_END + V_FP;
wire [31:0] V_SYNC_END    = V_SYNC_START + V_SYNC_LEN;

reg  [31:0] X_ACTIVE;
reg  [31:0] V_ACTIVE;

/*----------------------------------------------------------------------------*/

reg   [4:0] addr;  // Note : if read needed devices need to latch addr/read
                  // data for output @@@
wire [17:0] fs_address;                                    /* User parameters */
reg  [31:0] int_line;
reg  [31:0] vid_mode;

wire        mem_rd;
wire        mem_wait;
wire [31:0] fs_data;

reg  [17:0] frame;
reg  [31:0] count;                  // TEMP @@@

/*----------------------------------------------------------------------------*/

reg [11:0] X;
reg  [9:0] Y;
reg  [7:0] red, green, blue;
reg  [7:0] rrr,ggg,bbb;           // NEW @@@
reg        active_area;
reg        h_sync, v_sync;
reg  [3:0] TMDS_mod10=0;  // modulus 10 counter
reg  [9:0] TMDS_shift_red=0, TMDS_shift_green=0, TMDS_shift_blue=0;
reg        TMDS_shift_load=0;

wire       fifo_wr;                         /* FIFO insert (frame store) data */
wire       fifo_rd;                               /* FIFO read (discard) head */
wire       h_blank;
wire       v_blank;
reg        v_sync_L;
wire       vsync;                                          /* One clock pulse */
wire       v_start;                                      /* Vsync-type marker */
//wire [1:0] h_resolution;   // Mode setting
reg  [1:0] h_resolution;

wire        fetch;
wire [31:0] vid_word;                                         /* Pixel output */
wire [15:0] vid_half;
reg   [7:0] vid_byte;

wire  [9:0] TMDS_red, TMDS_green, TMDS_blue;  /* Encoded outputs for shifting */

// Pattern generator
wire [7:0]   W = {8{X[7:0]==Y[7:0]}};
//wire [7:0] W = {8{1'b0}}; Blank the diagonal white lines.
//wire [7:0] A = {8{X[7:5]==3'h4 && Y[7:5]==3'h4}};
wire [7:0]   A = {8{X[7:5]==3'h2 && Y[7:5]==3'h2}};

/*----------------------------------------------------------------------------*/

assign stall_o    =    cs_i   && 1'b0;
assign abort_v_o  = {3{cs_i}}  & 3'h0;
assign vduc_ireq_o = {1'b0, v_sync};

always @ (posedge clk)
if (reset)
  begin
  frame    <= 18'h00000;
  count    <= 32'h00000;
  vid_mode <= 32'h0000_0000;
  end
else
  begin
  if (cs_i && write_i)
    case (address_i[4:2])
      3'h0: frame    <= data_in[19:2];
      3'h1: vid_mode <= data_in;
      3'h2: int_line <= data_in;
    endcase
  if (vsync) count <= count + 1;
  end

always @ (posedge clk)                                    /* Address bit hold */
if (read_i) addr <= address_i[4:0];                   /* Delay for next cycle */

always @ (*)
case (addr[4:2])
  3'h0: data_out = {12'h000, frame, 2'b00};
  3'h1: data_out = vid_mode;
  3'h2: data_out = int_line;
  3'h3: data_out = count;
  3'h4: data_out = H_ACTIVE_END + 1;     /* Horizontal pixel count -1 in 'h10 */
  3'h5: data_out = V_ACTIVE_END + 1;        /* Vertical line count -1 in 'h14 */
  default: data_out = 32'hxxxx_xxxx;
endcase

/*----------------------------------------------------------------------------*/

always @(*)   /* Set up video parameters for either 640x40, 800x600 or 960x540*/ 
 case (vid_mode[3:2])
 2'h0: begin
       H_LINE        = 32'd1056;
       H_BP          = 32'd168;                                  /* 640 x 480 */
       H_ACTIVE_END  = 32'd639;
       H_FP          = 32'd120;
       V_SCREEN      = 32'd628;
       V_BP          = 32'd83;
       V_ACTIVE_END  = 32'd479;
       V_FP          = 32'd61;
       end        
 2'h1: begin 
       H_LINE        = 32'd1056;
       H_BP          = 32'd88;                                   /* 800 x 600 */
       H_ACTIVE_END  = 32'd799;
       H_FP          = 32'd40;
       V_SCREEN      = 32'd628;
       V_BP          = 32'd23;
       V_ACTIVE_END  = 32'd599;
       V_FP          = 32'd1;
       end
 2'h2: begin
       H_LINE        = 32'd1216;
       H_BP          = 32'd88;                                   /* 960 x 540 */
       H_ACTIVE_END  = 32'd959;
       H_FP          = 32'd40;
       V_SCREEN      = 32'd568;
       V_BP          = 32'd23;
       V_ACTIVE_END  = 32'd539;
       V_FP          = 32'd1;
       end
 default: begin
          H_LINE        = 32'd1056;
          H_BP          = 32'd168;                               /* 640 x 480 */
          H_ACTIVE_END  = 32'd639;
          H_FP          = 32'd120;
          V_SCREEN      = 32'd628;
          V_BP          = 32'd83;
          V_ACTIVE_END  = 32'd479;
          V_FP          = 32'd61;
          end
endcase
             
assign v_width_o  = H_ACTIVE_END + 1;            /* Export for drawing engine */
assign v_height_o = V_ACTIVE_END + 1;
assign v_mode_o   = vid_mode[1:0];   /* <1> = monochrome; <0> = 16-bits/pixel */
assign v_frame_o  = frame;

/*----------------------------------------------------------------------------*/

always @ (*)
case (vid_mode[0])
  1'b0: h_resolution    = 2'b00;
  1'b1: h_resolution    = 2'b10;
  default: h_resolution = 2'b00;
 endcase
 
assign h_blank = (X >= H_ACTIVE_END);
assign v_blank = (Y >= V_ACTIVE_END);
assign fifo_rd = ((X[1:0] | h_resolution) == 2'h3) && active_area;

assign v_start = (Y == V_SCREEN - 2);

always @ (*)
begin
 h_sync       = (X >= H_SYNC_START && X < H_SYNC_END);
 v_sync       = (Y >= V_SYNC_START && Y < V_SYNC_END);
 active_area  = (X <= H_ACTIVE_END && Y <= V_ACTIVE_END);
end

/*----------------------------------------------------------------------------*/

always @(posedge pixclk)
if (reset)                         /* Initialisation for easy simulation view */
  begin
  X <= H_LINE - 2;
  Y <= V_SCREEN - 4;
  end
else
  begin
  if (X == H_LINE - 1)
    begin
    X <= 12'b000;
    Y <= (Y == V_SCREEN - 1) ? 10'b000 : Y + 10'b001;
    end
  else
    X <= X + 12'b001;
end

always @ (posedge clk) v_sync_L <= v_sync;          /* Making one clock pulse */
assign vsync = v_sync && ! v_sync_L;

/*----------------------------------------------------------------------------*/

/*
always @(posedge pixclk)
begin
 red   <= ({X[5:0] & {6{Y[4:3]==~X[4:3]}}, 2'b00} | W) & ~A;
 green <= (X[7:0] & {8{Y[6]}} | W) & ~A;
 blue  <= Y[7:0] | W | A;
end
*/


always @ (*)
begin
red   = rrr;
green = ggg;
blue  = bbb;
end

/*----------------------------------------------------------------------------*/

/* Fetch from memory & queue pixel data.                                      */
fetcher fetcher(.clk             (clk),
                .reset           (reset),
                .v_blank_i       (v_start),
                .fifo_full_i     (!fetch),
                .fifo_wr_o       (fifo_wr),
                .start_address_i (frame),
                .fs_rd_o         (mem_rd),
                .fs_address_o    (fs_address),
                .fs_wait_i       (mem_wait));

assign fs_read_o = mem_rd;
assign mem_wait  = fs_wait_i; 
assign fs_addr_o = fs_address;
assign fs_data   = fs_data_i;


// Doesn't need to work
// video_buff video_buff(.clk      (clk),
//                       .reset    (reset),
//                       .vsync    (v_start),                    /* Reset buffer */
//                       .nfull_o  (fetch),
//                       .fifo_wr_i(fifo_wr),
//                       .data_in  (fs_data),
//                       .data_out (vid_word),
//                       .fifo_rd_i(fifo_rd));             /* Taking element out */

assign vid_half = X[0] ? vid_word[31:16] : vid_word[15:0];
always @ (*)
case (X[1:0]) 
  2'b00: vid_byte = vid_word[7:0];
  2'b01: vid_byte = vid_word[15:8];
  2'b10: vid_byte = vid_word[23:16];
  2'b11: vid_byte = vid_word[31:24];
  default: vid_byte = 8'hxx;
endcase

always @ (*)
case (vid_mode[1:0])
  2'b00: begin                                      /* Colour: 8 bits / pixel */
         rrr = {vid_byte[7:5], vid_byte[7:5], vid_byte[7:6]};
         ggg = {vid_byte[4:2], vid_byte[4:2], vid_byte[4:3]};
         bbb = {vid_byte[1:0], vid_byte[1:0], vid_byte[1:0], vid_byte[1:0]};
         end
  2'b01: begin                                      /* Colour:16 bits / pixel */
         rrr = {vid_half[15:11], vid_half[15:13]};
         ggg = {vid_half[10:5],  vid_half[10:9]};
         bbb = {vid_half[4:0],   vid_half[4:2]};
         end
  2'b10: begin                                  /* Monochrome: 8 bits / pixel */
         rrr = vid_byte;
         bbb = vid_byte;
         ggg = vid_byte;
         end
  2'b11: begin                               /* Monochrome: '16 bits' / pixel */
         rrr = vid_half[15:8];   /* Not really useful: just completes the set */
         bbb = vid_half[15:8];          /* Uses only 8 upper bits of halfword */
         ggg = vid_half[15:8];
         end
endcase

/*----------------------------------------------------------------------------*/
/* Adapted from www.fpga4fun.com                                              */

TMDS_encoder
encode_R(.clk(pixclk), .VD(red  ), .CD(2'b00), .VDE(active_area), .TMDS(TMDS_red));

TMDS_encoder
encode_G(.clk(pixclk), .VD(green), .CD(2'b00), .VDE(active_area), .TMDS(TMDS_green));

TMDS_encoder
encode_B(.clk(pixclk), .VD(blue ), .CD({v_sync,h_sync}), .VDE(active_area), .TMDS(TMDS_blue));

always @(posedge clk_TMDS)
TMDS_shift_load <= (TMDS_mod10==4'd9);

always @(posedge clk_TMDS)
begin
  TMDS_shift_red   <= TMDS_shift_load ? TMDS_red   : TMDS_shift_red  [9:1];
  TMDS_shift_green <= TMDS_shift_load ? TMDS_green : TMDS_shift_green[9:1];
  TMDS_shift_blue  <= TMDS_shift_load ? TMDS_blue  : TMDS_shift_blue [9:1];
  TMDS_mod10       <= (TMDS_mod10==4'd9) ? 4'd0 : TMDS_mod10+4'd1;
end

always @(*)
begin
  TMDS_shift_red_o   = TMDS_shift_red[0];
  TMDS_shift_green_o = TMDS_shift_green[0];
  TMDS_shift_blue_o  = TMDS_shift_blue[0];
end

endmodule  // vduc

/*----------------------------------------------------------------------------*/

module fetcher(input  wire        clk,
               input  wire        reset,
               input  wire        v_blank_i,
               input  wire        fifo_full_i,
               output reg         fifo_wr_o,                  /* Latch output */
               input  wire [17:0] start_address_i,    /* Initialisation value */
               output wire        fs_rd_o,                    /* Read request */
               output reg  [17:0] fs_address_o,         /* Framestore address */
               input  wire        fs_wait_i);                    /* Read wait */

reg  state;                                          /* Initialisation/active */
wire mem_rd;                /* Read request which may be withdrawn (internal) */
reg  hold_rd;   // Used to keep read active once asserted (may not matter?) @@@
wire mem_rdy;                                            /* Data return phase */

always @ (posedge clk)
if (v_blank_i) state <= 1'b0;
else
  if (state == 1'b0)        /* Initialisation phase: latch input parameter(s) */
    begin
    fs_address_o <= start_address_i;
    state <= 1'b1;                                /* Active for rest of frame */
    end
  else                                                     /* Operating state */
    if (mem_rdy) fs_address_o <= fs_address_o + 18'h00001;      /* Addr. inc. */

always @ (posedge clk) hold_rd <= fs_rd_o && fs_wait_i;
assign mem_rd  = (state == 1'b1) && !v_blank_i && !fifo_full_i;
assign fs_rd_o = mem_rd || hold_rd;                /* Prevents _rd retraction */
assign mem_rdy = fs_rd_o && !fs_wait_i;

always @ (posedge clk) fifo_wr_o <= mem_rdy;      /* Delayed for FIFO control */

endmodule       // fetcher

/*----------------------------------------------------------------------------*/

module TMDS_encoder(
        input clk,
        input [7:0] VD,  // video data (red, green or blue)
        input [1:0] CD,  // control data
        input VDE,  // video data enable, to choose between CD (when VDE=0) and VD (when VDE=1)
        output reg [9:0] TMDS = 0);

wire [3:0] Nb1s = VD[0] + VD[1] + VD[2] + VD[3] + VD[4] + VD[5] + VD[6] + VD[7];

wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && VD[0]==1'b0);

wire [8:0] q_m = {~XNOR, q_m[6:0] ^ VD[7:1] ^ {7{XNOR}}, VD[0]};

reg [3:0] balance_acc = 0;

wire [3:0] balance = q_m[0] + q_m[1] + q_m[2]
                   + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;

wire balance_sign_eq = (balance[3] == balance_acc[3]);

wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;

wire [3:0] balance_acc_inc = balance -
             ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));

wire [3:0] balance_acc_new = invert_q_m ? balance_acc - balance_acc_inc
                                        : balance_acc + balance_acc_inc;

wire [9:0] TMDS_data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};

wire [9:0] TMDS_code = CD[1] ? (CD[0] ? 10'b1010101011 : 10'b0101010100)
                             : (CD[0] ? 10'b0010101011 : 10'b1101010100);

always @(posedge clk) TMDS <= VDE ? TMDS_data : TMDS_code;
always @(posedge clk) balance_acc <= VDE ? balance_acc_new : 4'h0;

endmodule // vduc

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
