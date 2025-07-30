/** 
    Module:        drawing_gradient
    
    Description:   Clears the screen with a gradient effect.
                   This module implements a gradient drawing algorithm for the
                   drawing engine. It processes requests to draw a gradient on the
                   display and communicates with the drawing control unit.
                   It uses a linear interpolation to create a gradient effect between two colors.  
                   It calculates the color for each pixel based on its position and the specified
                   top-left and bottom-right colors.
 

    Authors:       Anthony Mathews 
    Updated:       July 2025

*/
`timescale 1ns / 10ps 

`include "video_definitions.sv"

module drawing_gradient(
    input  logic        clk,
    input  logic        reset,
    input  logic        req,
    output logic        ack,
    output logic        busy,

    input  logic [17:0] display_base,
    input  logic [9:0]  display_height,
    input  logic [1:0]  display_mode,
    input  logic [9:0]  display_width,

    input  logic [31:0] r0,
    input  logic [31:0] r1,
    input  logic [31:0] r2,
    input  logic [31:0] r3,
    input  logic [31:0] r4,
    input  logic [31:0] r5,
    input  logic [31:0] r6,
    input  logic [31:0] r7,
    output logic        de_req,
    input  logic        de_ack,
    output logic [17:0] de_addr,
    output logic [3:0]  de_nbyte,
    output logic        de_rnw,
    output logic [31:0] de_w_data,
    input  logic [31:0] de_r_data
);

typedef enum logic [1:0] {IDLE, CALC, DRAWING} draw_state_e;
draw_state_e draw_state;

logic [24:0] color_top_left;
logic [24:0] color_bottom_right;
logic [24:0] colour;

logic [24:0] color_a;   // Mixing color A
logic [24:0] color_b;   // Mixing color B

logic [7:0] colorR;
logic [7:0] colorG;
logic [7:0] colorB;

logic [9:0]  x;
logic [9:0]  y;
logic [31:0]  fraction;
logic [19:0] pixel_address;

function automatic logic [7:0] lerp(
    input logic [7:0] a,
    input logic [7:0] b,
    input logic [7:0] fraction
);
    logic [15:0] diff;
    logic [15:0] prod;
    logic [15:0] result;
    begin
        diff   = b - a;
        prod   = diff * fraction;
        result = a + (prod >> 8); // Divide by 256 for 8-bit fraction
        lerp   = result[7:0];
    end
endfunction


always_comb begin 
    
    fraction = x << 8; 
    fraction = fraction / display_width; // Scale x to 0-255 range
  
    
    if (y > (display_height >> 1)) begin  
        color_a = color_bottom_right;  // Use bottom right color
        color_b = color_top_left;      // Use top left color
    end else begin 
        color_a = color_top_left;      // Use top left color
        color_b = color_bottom_right;  // Use bottom right color
    end  

    // Interpolate colors based on x position
    colorR = lerp(color_a[24:16], color_b[24:16], fraction);
    colorG = lerp(color_a[15:8],  color_b[15:8],  fraction);
    colorB = lerp(color_a[7:0],   color_b[7:0],   fraction);  

    // Address would be 20
    pixel_address = (y * display_width + x) ;        // Calculate address based on x and y
    de_addr = {pixel_address[19:1] };               // Use upper bits for address, lower bits for byte alignment
     
    if (x[0] == 0) begin 
        de_w_data = { 16'b0, colorR[7:3], colorG[7:2], colorB[7:3]}; // Output colour as 16 bit 
        de_rnw = 1'b0; // Write operation
        de_nbyte = 4'b1100; // All bytes enabled
    end else begin  
        de_w_data = {colorR[7:3], colorG[7:2], colorB[7:3],16'b0}; // Output colour as 16 bit 
        de_rnw = 1'b0; // Write operation
        de_nbyte = 4'b0011; // All bytes enabled
    end
    busy = (draw_state != IDLE);
end

  
always_ff @(posedge clk) begin
    if (reset) begin
        draw_state <= IDLE;
        ack        <= 1'b0; 
        de_req     <= 1'b0;
        x         <= 0;
        y         <= 0;
    end else begin
        case (draw_state)
            IDLE: begin
                if (req) begin
                    ack      <= 1'b1;
                    color_top_left <= r0[23:0];
                    color_bottom_right <= r1[23:0]; 
                    draw_state <= CALC;
                    x <= 0;
                    y <= 0;
                end else begin
                    ack <= 1'b0;
                end
            end
            CALC: begin  
                draw_state <= DRAWING; // Move to drawing 
                   
                
                if (x >= display_width) begin 
                    x <= 0;
                    y <= y + 1;
                end else begin 
                    x <= x + 1;
                end
                // Check if we have reached the end of the display
                if (y >= display_height) begin
                    x <= 0;
                    y <= 0;
                    draw_state <= IDLE; // Finished drawing
                end else begin  
                    draw_state <= DRAWING; // Move to drawing 
                    de_req <= 1'b1; // Request data to be written  
                end

            end
            DRAWING : begin 
                if (de_ack) begin  
                    draw_state <= CALC;
                end
            end
        endcase
    end
end 

endmodule