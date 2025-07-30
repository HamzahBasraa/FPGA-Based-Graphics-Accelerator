/**

    Module:        drawing_control
    
    Description:   Module holding register file and control logic for the
                   drawing system. This module handles the control
                   signals for the drawing units, and provides a
                   register interface to the processor.
                   It also provides a bus interface to the video
                   display unit controller (VDUC).


    Authors:       A Mathews, J Garside
    Updated:       July 2025


    Drawing Control Register Descriptions:

    00-1C   Arguments       32  R/W     General drawing arguments
    20      Command         3   WO      Code to activate particular drawing unit
    24      Status          10  RO      See status definition below
    28      Status Set      10  WO      Set bits of Status register
    2C      Status Clear    10  WO      Clears bits of Status Registers

    28      Drawing base    20  R/W     Set base framestore for drawing.
    2C      Reserved 
    40      Display base    20  RO      Display start (top left)
    44      Display mode    2   RO      Mode code ({colour, resolution} table 8.1).
    48      Display width   10  RO      Width in pixels
    4C      Display height  10  RO      Height in pixels

    Status Register further description:

    Bit         Name        Width  R/W     Description
    0-7        Busy        8     RO      Busy flags for each drawing unit
    8          Job Complete 1     RO      High if a drawing unit has completed a
                                            request. This is cleared by writing to
                                            the Status Clear register.
    9          Queue       1     RO      High if a drawing unit has a job queued.
                                            This is cleared by writing to the
                                            Status Clear register.
    10         Job IE      1     R/W     Interrupt enable for Job Complete.
                                            If set, an interrupt will be generated
                                            when a drawing unit completes a job.
    11         Queue IE    1     R/W     Interrupt enable for Queue.                
                                            If set, an interrupt will be generated
                                            when a drawing unit has a job queued.
    12         Base Bit    1     R/W     If set, the drawing_base register is used
                                            as the base address for drawing.
                                            If clear, the VDUC display_base register
                                            is used as the base address for drawing.
    13         Reset Bit   1     R/W     Writing a 1 to this bit will reset all
                                            drawing units. 
*/

typedef logic [31:0] argument_bus_t [7:0]; 

module drawing_control(
               input  logic         clk,
               input  logic         reset,
               input  logic         cs_i,
               input  logic         read_i,
               input  logic         write_i,
               input  logic  [31:0] address_i,
               input  logic  [1:0]  size_i,
               input  logic  [1:0]  mode_i,
               output logic         stall_o,
               output logic  [2:0]  abort_v_o,
               input  logic  [31:0] data_in,
               output logic  [31:0] data_out,
               output logic  [1:0]  ireq_o,

               output argument_bus_t arguments_o,
               output logic  [31:0] command_o,
               output logic         req_o, 

               output logic [17:0] display_base_o,
               output logic [1:0] display_mode_o,
               output logic [9:0] display_width_o,
               output logic [9:0] display_height_o, 

               input  wire  [9:0] v_width_i,
               input  wire  [9:0] v_height_i,
               input  wire  [1:0] v_mode_i,
               input  wire [17:0] v_frame_i,

               input logic [7:0]    busy_i,
               input logic          job_complete_int_i,
               input logic          job_queue_int_i, 
               output logic         drawing_unit_reset_o

); 

localparam REG_ARGUMENTS        = 32'h0;
localparam REG_COMMAND          = 32'h20;
localparam REG_STATUS_SET       = 32'h24;
localparam REG_STATUS_SET       = 32'h28;
localparam REG_STATUS_CLEAR     = 32'h2C;
localparam REG_DRAWING_BASE     = 32'h30;
localparam REG_DISPLAY_BASE     = 32'h40;
localparam REG_DISPLAY_MODE     = 32'h44;
localparam REG_DISPLAY_WIDTH    = 32'h48;
localparam REG_DISPLAY_HEIGHT   = 32'h4c;

localparam STATUS_JOB_IE      = 10;
localparam STATUS_QUEUE_IE    = 11;
localparam STATUS_BASE_BIT    = 12;
localparam STATUS_RESET_BIT   = 13;

/** Registers */
reg [31:0]  arguments [7:0];
reg [31:0]  command;
reg [17:0]  drawing_base;
logic       job_queue_interrupt_enable;
logic       job_complete_interrupt_enable;
logic       job_queue_interrupt;
logic       job_complete_interrupt;
logic       drawing_base_ctrl;
logic       reset_drawing_units;


reg command_requested;          // Goes high in the cycle in which a command   
                                // is recieved
logic [31:0] status;             

always_comb begin : drawing_video_bus_out

    display_base_o = drawing_base_ctrl ? drawing_base : v_frame_i;
    display_mode_o = v_mode_i;
    display_width_o = v_width_i;
    display_height_o = v_height_i; 
end

always_comb begin : ctrl_bus_out 
    
    // Masked interrupts 
    ireq_o = {
        job_queue_interrupt & job_queue_interrupt_enable,
        job_complete_interrupt & job_complete_interrupt_enable
    }; 
    drawing_unit_reset_o = reset_drawing_units;
end

always_comb begin : drawing_bus_out
    status = {      
                    18'h0, // Spare bits 
                    1'b0,  // Reset Bit
                    drawing_base_ctrl,
                    job_queue_interrupt_enable,
                    job_complete_interrupt_enable,
                    job_queue_interrupt,
                    job_complete_interrupt,
                    busy_i[7:0]
             }; 
    command_o = command;
    arguments_o = arguments; 
    req_o = command_requested;
end
 
always_ff @( posedge clk ) begin : reg_latching
      
    if (reset) begin : clear_registers
        arguments[3'd0] <= 0; 
        arguments[3'd1] <= 0;
        arguments[3'd2] <= 0;
        arguments[3'd3] <= 0;
        arguments[3'd4] <= 0;
        arguments[3'd5] <= 0;
        arguments[3'd6] <= 0;
        arguments[3'd7] <= 0;
        command      <= 0;
        drawing_base <= 0;
        command_requested  <= 0;

        drawing_base_ctrl <= 0;
        reset_drawing_units <= 0;

        // Clear interrupt and masks on reset 
        job_queue_interrupt_enable <= 0;
        job_complete_interrupt_enable <= 0;
        job_queue_interrupt <= 0;
        job_complete_interrupt <= 0;

    end else begin  


        if (command_requested)
            command_requested <= 0;
        if (reset_drawing_units)
            reset_drawing_units <= 0;

        // Handle writes to control registers 
        if (cs_i && write_i) begin  
            // Writing to the registers
            case(address_i[7:0]) 
                REG_ARGUMENTS + 32'h0 :  arguments[3'd0] <= data_in; 
                REG_ARGUMENTS + 32'h4 :  arguments[3'd1] <= data_in;
                REG_ARGUMENTS + 32'h8 :  arguments[3'd2] <= data_in;
                REG_ARGUMENTS + 32'hC :  arguments[3'd3] <= data_in;
                REG_ARGUMENTS + 32'h10 : arguments[3'd4] <= data_in;
                REG_ARGUMENTS + 32'h14 : arguments[3'd5] <= data_in;
                REG_ARGUMENTS + 32'h18 : arguments[3'd6] <= data_in;
                REG_ARGUMENTS + 32'h1C : arguments[3'd7] <= data_in;
                REG_COMMAND : begin 
                            command              <= data_in; 
                            command_requested    <= 1;
                         end
                REG_DISPLAY_BASE : drawing_base <= data_in; 
                REG_STATUS_CLEAR : begin 

                    if (data_in[STATUS_JOB_IE]) job_complete_interrupt_enable <= 0;
                    if (data_in[STATUS_QUEUE_IE]) job_queue_interrupt_enable <= 0;
                    if (data_in[STATUS_BASE_BIT]) drawing_base_ctrl <= 0;
                end
                REG_STATUS_SET : begin 
                    if (data_in[STATUS_JOB_IE]) job_complete_interrupt_enable <= 1;
                    if (data_in[STATUS_QUEUE_IE]) job_queue_interrupt_enable <= 1;
                    if (data_in[STATUS_RESET_BIT]) reset_drawing_units <= 1;
                    if (data_in[STATUS_BASE_BIT]) drawing_base_ctrl <= 1;
                end
            endcase 
        end   
    end
end

always_comb begin : comb_data_bus_output 
    if (cs_i && read_i) begin 
        // Reading back from the registers
        case(address_i[7:0]) 
            REG_ARGUMENTS + 8'h0 :  data_out = arguments[3'd0];
            REG_ARGUMENTS + 8'h4 :  data_out = arguments[3'd1];
            REG_ARGUMENTS + 8'h8 :  data_out = arguments[3'd2];
            REG_ARGUMENTS + 8'hC :  data_out = arguments[3'd3];
            REG_ARGUMENTS + 8'h10 : data_out = arguments[3'd4];
            REG_ARGUMENTS + 8'h14 : data_out = arguments[3'd5];
            REG_ARGUMENTS + 8'h18 : data_out = arguments[3'd6];
            REG_ARGUMENTS + 8'h1C : data_out = arguments[3'd7];
            REG_COMMAND           : data_out = command;      
            REG_STATUS            : data_out = status;      
            REG_DRAWING_BASE      : data_out = drawing_base;
            REG_DISPLAY_BASE      : data_out = v_frame_i;
            REG_DISPLAY_HEIGHT    : data_out = v_height_i;
            REG_DISPLAY_WIDTH     : data_out = v_width_i;
            REG_DISPLAY_MODE      : data_out = v_mode_i;
        endcase
    end  
end

endmodule