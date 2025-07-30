/******************************************************************************/
/* Module:   system_Testbench                                                 */
/* Modified: July 2025                                                        */
/* Author:   J Garside, JSP, AMM                                              */
/*                                                                            */
/* Description:                                                               */
/*                                                                            */
/* Example test stimulus for drawing_main schematic design                    */
/* External 'world' model comprising framestore memory and simulated display  */
/*                                                                            */ 
/*                                                                            */
/******************************************************************************/
 

`timescale 1ns / 10ps 

module system_Testbench(); 


// Constants for Register locations 
localparam R0 = 8'h00;
localparam R1 = 8'h04;
localparam R2 = 8'h08;
localparam R3 = 8'h0C;
localparam R4 = 8'h10;
localparam R5 = 8'h14;
localparam R6 = 8'h18;
localparam R7 = 8'h1C;
localparam GO = 8'h20;
localparam STATUS = 8'h24;
localparam DISPLAY_BASE = 8'h30;
localparam DISPLAY_MODE = 8'h34;
localparam DISPLAY_WIDTH = 8'h38;
localparam DISPLAY_HEIGHT = 8'h3C;

localparam V_WIDTH    = 640; // Video width
localparam V_HEIGHT   = 480; // Video height  
localparam V_MODE     = 2'b00; // Video mode (e.g., 16-bit colour)
localparam V_FRAME    = 0; // Video frame (not used in this testbench)

logic clk;
logic reset;

logic         de_req;    /* DE bus takes different form */
logic         de_ack;
logic [17:0]  de_addr;
logic  [3:0]  de_nbyte;
logic [31:0]  de_w_data;
logic         de_rnw;
logic [31:0]  de_r_data;

// Processor databus                 
logic drawing_engine_cs;
logic drawing_engine_read;
logic drawing_engine_write;
logic [31:0] drawing_engine_address;
logic [1:0]  drawing_engine_size;
logic [1:0]  drawing_engine_mode;
logic [31:0] drawing_engine_data_in;
logic [31:0] drawing_engine_data_out;

/********************************************************

/********************************************************/
/*                                                      */
/*                                                      */
/*                                                      */
/*                                                      */
/*                                                      */
/********************************************************/

logic [31:0] data_test_buf;     // Buffer for test data 

initial begin

  repeat(3) @(posedge clk);
  reset = 1;
  repeat(3) @(posedge clk);
  reset = 0;
  @(posedge clk);

  // Reading and writing to the drawing engine
  // registers 
  bus_write(8'h08, 32'hffff0000);
  bus_read(8'h08, data_test_buf);
  bus_write(8'h08, 32'habcdef12);
  bus_read(8'h08, data_test_buf);

  // Start a drawing unit 
  bus_write(8'h00, 32'hFF1F);     // Write argument 0
  bus_write(8'h20, 32'h0);        // Go command to Drawing unit #0  
  await_until_drawing_engine_not_busy();


  // Use Gradient drawing unit
  bus_write(8'h00, 32'h0021FF22);   // Write argument 0
  bus_write(8'h04, 32'h00FF0000);   // Write argument 1
  bus_write(8'h20, 32'h2);      // Go command to Drawing unit #2
 

  // Drawing a line
  pre_process_line( 120,120, 160, 150, 16'h0213);
  await_until_drawing_engine_not_busy();
   
  // Drawing another line
  pre_process_line( 300,300,400, 400, 16'h02F3); 
  await_until_drawing_engine_not_busy();

  $stop;
   
end

/********************************************************/
/* System setup                                         */
/********************************************************/

// Clock setup 
initial begin clk = 0; end
always begin clk = ~clk; #20; end

/*******************************************************/
/*  Instantiation of a mocked sram controller, VDUC
/*  and the drawing_engine 
/* 
/*******************************************************/

drawing_engine u_drawing(
    .clk          (clk),
    .reset        (reset),
    .cs_i         (drawing_engine_cs),
    .read_i       (drawing_engine_read),
    .write_i      (drawing_engine_write),
    .address_i    (drawing_engine_address),
    .size_i       (drawing_engine_size),
    .mode_i       (drawing_engine_mode),
    .stall_o      (),
    .abort_v_o    (),
    .data_in      (drawing_engine_data_in),
    .data_out     (drawing_engine_data_out),
    .ireq_o       (),

    .v_width_i    (V_WIDTH),            /** FROM VDUC */
    .v_height_i   (V_HEIGHT),            /** FROM VDUC */
    .v_mode_i     (V_MODE),            /** FROM VDUC */
    .v_frame_i    (V_FRAME),            /** FROM VDUC */

    .de_req_o     (de_req),
    .de_RnW_o     (de_rnw),
    .de_nbyte_o   (de_nbyte),
    .de_ack_i     (de_ack),
    .de_address_o (de_addr),
    .de_wr_data_o (de_w_data),
    .de_rd_data_i (de_r_data)
);

/** Framestore bus */
logic        fs_n_CS;        
logic         fs_n_rd;                  
logic         fs_n_wr;                  
logic  [17:0] fs_addr;
logic   [3:0] fs_n_bytes;
logic        fs_n_write;        
logic [31:0] fs_d_in;
logic  [31:0] fs_d_out;

sram_ctrl u_sram_ctrl(
    .clk       (clk       ),
    .reset     (reset     ),

    /* Wired off ports A and B to the SRAM controller */
    .CS_A      (0), .read_A    (0), .write_A   (0),
    .stall_A   (),  .size_A    (0), .addr_A    (0),
    .dwr_A     (0), .drd_A     (),  .CS_B      (0),
    .read_B    (0), .write_B   (0), .stall_B   (),
    .size_B    (0), .addr_B    (0), .dwr_B     (0),
    .drd_B     (), 
    
    .de_req    (de_req    ),
    .de_ack    (de_ack    ),
    .de_addr   (de_addr   ),
    .de_nbyte  (de_nbyte  ),
    .de_w_data (de_w_data ),
    .de_rnw    (de_rnw    ),
    .de_r_data (de_r_data ),

    .n_CS_o    (fs_n_CS),
    .n_rd_o    (fs_rd),
    .n_wr_o    (fs_wr),
    .addr_o    (fs_addr),
    .n_bytes_o (fs_n_bytes),
    .n_write_o (fs_n_write),
    .d_in_i    (fs_d_in),
    .d_out_o   (fs_d_out)
);

/** Mocked framestore */ 
mock_framestore u_mock_framestore(
    .n_CS_o    (fs_n_CS    ),
    .n_rd_o    (fs_rd    ),
    .n_wr_o    (fs_wr    ),
    .addr_o    (fs_addr    ),
    .n_bytes_o (fs_n_bytes ),
    .n_write_o (fs_n_write ),
    .d_in_i    (fs_d_in    ),
    .d_out_o   (fs_d_out   )
);


/**  Drawing VDUC */
drawing_vduc  
u_drawing_vduc(
    .clk                (clk),
    .pixclk             (clk),
    .clk_TMDS           (clk),
    .reset              (reset),
    .cs_i               (0),
    .read_i             (0),
    .write_i            (0),
    .address_i          (0),
    .size_i             (0),
    .mode_i             (0)     
);
 
/*************************************************************/
/* Processor bus interface 
/*************************************************************/


/*----------------------------------------------------------------------------*/
// Microprocessor register write task
// This task is asynchronous; it is not related to the system clock in any way

task bus_write(input [7:0] addr, input [31:0] data);
begin
  $display("Writing %h: %h ",addr, data);

  drawing_engine_cs       <= 1'b1;		// You can work out the sequence as an exercise!
  drawing_engine_address  <= {24'h0, addr};   // set address
  drawing_engine_read     <= 1'b0;		// read  disabled
  drawing_engine_write    <= 1'b1;   // Write enabled
  drawing_engine_size     <= 2'b11;  // word
  drawing_engine_data_in  <= data;    
  @(posedge clk);   // Wait a clock cycle  
  drawing_engine_cs       <= 1'b0;		// You can work out the sequence as an exercise!
  drawing_engine_address  <= 32'hx;   
  drawing_engine_read     <= 1'b0;		 
  drawing_engine_write    <= 1'b0;    
  drawing_engine_size     <= 2'bxx;

end
endtask

/*----------------------------------------------------------------------------*/
// Microprocessor register read task
// This task is asynchronous; it is not related to the system clock in any way 
task bus_read(input [7:0] addr, output [31:0] data);
begin
  drawing_engine_cs       <= 1'b1;		// You can work out the sequence as an exercise!
  drawing_engine_address  <= {24'h0, addr};
  drawing_engine_read     <= 1'b1;		// Shouldn't be needed
  drawing_engine_write    <= 1'b0;    

  @(posedge clk); 
  data   <= drawing_engine_data_out;	// Read data on the bus 

  drawing_engine_cs       <= 1'b0;		 
  drawing_engine_address  <= 32'hx;   
  drawing_engine_read     <= 1'b0;		 
  drawing_engine_write    <= 1'b0;    
  drawing_engine_size     <= 2'bxx; 
end
endtask


/** Reads the status register until the Drawing Engine reports
    not being busy                                              */
task automatic await_until_drawing_engine_not_busy();
begin
  logic [31:0] data_test_buf = '0;
  integer not_busy_wait_counter = 0;
  integer max_clock_cycles = 1000000; // Set a limit to avoid infinite loops
   
  if (u_drawing.bus_busy == 0) begin
    $display("Drawing engine is not busy at the start of the task. Awaiting for next change...");
    @(u_drawing.bus_busy); // Wait for the unit to go busy 
  end

  $display("Waiting for the drawing engine to become not busy...");
  // Wait until the drawing engine is not busy
  // Bottom 8 bits of the status register should be zero
  // This is a blocking task, so it will wait until the condition is met
  while( u_drawing.bus_busy !=0) begin 
    @(posedge clk)
    not_busy_wait_counter++;
  end

  if (not_busy_wait_counter > max_clock_cycles) begin
    $display("ERROR: Drawing engine did not become not busy within %d cycles", max_clock_cycles);
    $display("Last status read: %h", data_test_buf);
    $display("Simulation will terminate to prevent infinite loop.");
    $stop; // Terminate simulation if it takes too long
  end else
    $display("Drawing engine is not busy after %d cycles", not_busy_wait_counter);

end
endtask

/*----------------------------------------------------------------------------*/
// This task executes a sequence of write (STRH) operations to trigger a
// line drawing operation

task draw_line(input [15:0] r0, r1, r2, r3, r4, r5, r6);
begin
  bus_write(R0, r0);		// abs(Larger difference)
  bus_write(R1, r1);		// abs(Smaller difference)
  bus_write(R2, r2);		// Primary step
  bus_write(R3, r3);		// Both steps
  bus_write(R4, r4);		// Address (L)
  bus_write(R5, r5);		// Address (H)
  bus_write(R6, r6);		// Colour
  bus_write(GO, 1);		  // Command
end
endtask


/*----------------------------------------------------------------------------*/
// The given line drawing engine assumes software preprocessing
`define X_SIZE 640 

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


endmodule // testbench
 
