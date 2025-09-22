// VGA values
`define  HORIZ_BACK_PORCH   40
`define  HORIZ_ACTIVE      640
`define  HORIZ_FRONT_PORCH  16
`define  HORIZ_SYNC         88
`define  VERT_BACK_PORCH    33
`define  VERT_ACTIVE       480
`define  VERT_FRONT_PORCH   10
`define  VERT_SYNC           2

`define  FRAME0_START    18'h00000	// Remains of a past application
`define  FRAME1_START    18'h12C00
`define  FRAME2_START    18'h25800

`define  INPUT_WIDTH        720		// More remains of a past application
`define  INPUT_HEIGHT       576
`define  OUTPUT_WIDTH       640
`define  OUTPUT_HEIGHT      480

`define  LINESZ         `HORIZ_ACTIVE	// Maybe used in testbench(es)
`define  X_SIZE         `HORIZ_ACTIVE	// Dimensions in pixels
`define  Y_SIZE         `VERT_ACTIVE
