/**

    Module:        mock_drawing_vduc

    Description:   This module produces minimal video fetch signal timing
                   for illustrative purposes.

    Authors:       James Garside & Anthony Mathews
    Updated:       August 2025  

*/

module mock_drawing_vduc(input  wire        clk,
                         input  wire        reset,
                         output wire        h_blank,
                         output wire        v_blank,
                         output reg         fs_req,
                         input  wire        fs_ack,
                         output reg  [17:0] fs_addr_o);


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

wire        fetch;                                       /* Want another read */
reg  [11:0] X;
reg   [9:0] Y;
reg         active_area;
reg         h_sync, v_sync;

reg         v_sync_L;
wire        vsync;                                         /* One clock pulse */
wire        v_start;                                     /* Vsync-type marker */

reg         state;                                   /* Initialisation/active */

/*----------------------------------------------------------------------------*/

initial                                                          /* 640 x 480 */
begin
H_LINE        = 32'd1056;
H_BP          = 32'd168;
H_ACTIVE_END  = 32'd639;
H_FP          = 32'd120;
V_SCREEN      = 32'd628;
V_BP          = 32'd83;
V_ACTIVE_END  = 32'd479;
V_FP          = 32'd61;
end        

/*----------------------------------------------------------------------------*/
 
assign h_blank = (X >= H_ACTIVE_END);
assign v_blank = (Y >= V_ACTIVE_END);
assign fetch   = (X[1:0] == 2'h3) && active_area;

assign v_start = (Y == V_SCREEN - 2);

always @ (*)
begin
 h_sync       = (X >= H_SYNC_START && X < H_SYNC_END);
 v_sync       = (Y >= V_SYNC_START && Y < V_SYNC_END);
 active_area  = (X <= H_ACTIVE_END && Y <= V_ACTIVE_END);
end

/*----------------------------------------------------------------------------*/
/* Run the (X, Y) scan defining the output screen map.                        */

always @(posedge clk)
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
assign vsync = v_sync && ! v_sync_L;        /* Pulse generator on rising edge */

/*----------------------------------------------------------------------------*/

always @ (posedge clk)
if (reset || v_start) state <= 1'b0;
else
  if (state == 1'b0)        /* Initialisation phase: latch input parameter(s) */
    begin
    fs_addr_o <= 18'h00000;
    state <= 1'b1;                                /* Active for rest of frame */
    end
  else                                                     /* Operating state */
    if (fs_ack) fs_addr_o <= fs_addr_o + 18'h00001;      /* Address increment */

always @ (posedge clk)
if (reset)            fs_req <= 0;
else if (fetch)       fs_req <= 1;
     else if (fs_ack) fs_req <= 0;

/*----------------------------------------------------------------------------*/

endmodule // vduc

/*----------------------------------------------------------------------------*/
