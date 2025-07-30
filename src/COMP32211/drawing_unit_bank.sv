/** 
    Module:        drawing_unit_bank
    
    Description:   This module instantiates the drawing units and connects them to the
                   drawing control. It also provides a bus interface to the
                   video display unit controller (VDUC).
                   The module handles the bus requests and responses.

    Authors:       James Garside & Anthony Mathews
    Date:          July 2025

*/

module drawing_unit_bank(

        input logic             clk, 
        input logic             reset, 
        input logic             req_i,
        output logic            ack, 

        input logic   [31:0]    arguments_i [7:0],  /** Argument bus  */
        input logic   [31:0]    command_i,          /** Command input */

        output logic  [7:0]     busy_o,
        output logic  [7:0]     completed_o,        

            
        input logic [17:0] display_base_i,
        input logic [9:0]  display_height_i,
        input logic [1:0]  display_mode_i,
        input logic [9:0]  display_width_i,


        /** Bus outwards to the framestore  */
        output logic            de_req_o,   
        output logic            de_RnW_o,
        output logic [3:0]      de_nbyte_o,
        input  logic            de_ack_i,
        output logic [17:0]     de_address_o,
        output logic [31:0]     de_wr_data_o,
        input  logic [31:0]     de_rd_data_i
);

localparam drawing_unit_count = 8;
 
/**************************************************************/
/* Internal busses                                            */

logic [31:0] mux_bus_data_write [drawing_unit_count];
logic [31:0] mux_bus_data_read  [drawing_unit_count];
logic        mux_bus_req        [drawing_unit_count];
logic        mux_bus_ack        [drawing_unit_count];
logic        mux_bus_rnw        [drawing_unit_count];
logic [17:0] mux_bus_addr       [drawing_unit_count];
logic [3:0]  mux_bus_nbyte      [drawing_unit_count]; 


logic demux_bus_de_req   [drawing_unit_count]; 
logic demux_bus_de_ack   [drawing_unit_count]; 

logic [(drawing_unit_count-1):0] busy_bus ; 



assign busy_o = busy_bus;
  
drawing_unit_triggers u_drawing_unit_triggers ( 
    .clk(clk), 
    .reset(reset),
    .busy_bus_i(busy_bus),
    .job_completed_o(completed_o)
);


/***************************************************************/

drawing_mux_8 u_drawing_mux_8(
    .clk        (clk),
    .req0       (mux_bus_req[0]),
    .ack0       (mux_bus_ack[0]),
    .rnw0       (mux_bus_rnw[0]),
    .addr0      (mux_bus_addr[0]),
    .nbyte0     (mux_bus_nbyte[0]),
    .data0      (mux_bus_data_write[0]),
    .rd_data0   (mux_bus_data_read[0]),  
    .req1       (mux_bus_req[1]),
    .ack1       (mux_bus_ack[1]),
    .rnw1       (mux_bus_rnw[1]),
    .addr1      (mux_bus_addr[1]),
    .nbyte1     (mux_bus_nbyte[1]),
    .data1      (mux_bus_data_write[1]),
    .rd_data1   (mux_bus_data_read[1]),  
    .req2       (mux_bus_req[2]),
    .ack2       (mux_bus_ack[2]),
    .rnw2       (mux_bus_rnw[2]),
    .addr2      (mux_bus_addr[2]),
    .nbyte2     (mux_bus_nbyte[2]),
    .data2      (mux_bus_data_write[2]),
    .rd_data2   (mux_bus_data_read[2]),  
    .req3       (mux_bus_req[3]),
    .ack3       (mux_bus_ack[3]),
    .rnw3       (mux_bus_rnw[3]),
    .addr3      (mux_bus_addr[3]),
    .nbyte3     (mux_bus_nbyte[3]),
    .data3      (mux_bus_data_write[3]),
    .rd_data3   (mux_bus_data_read[3]),  
    .req4       (mux_bus_req[4]),
    .ack4       (mux_bus_ack[4]),
    .rnw4       (mux_bus_rnw[4]),
    .addr4      (mux_bus_addr[4]),
    .nbyte4     (mux_bus_nbyte[4]),
    .data4      (mux_bus_data_write[4]),
    .rd_data4   (mux_bus_data_read[4]),  
    .req5       (mux_bus_req[5]),
    .ack5       (mux_bus_ack[5]),
    .rnw5       (mux_bus_rnw[5]),
    .addr5      (mux_bus_addr[5]),
    .nbyte5     (mux_bus_nbyte[5]),
    .data5      (mux_bus_data_write[5]),
    .rd_data5   (mux_bus_data_read[5]),  
    .req6       (mux_bus_req[6]),
    .ack6       (mux_bus_ack[6]),
    .rnw6       (mux_bus_rnw[6]),
    .addr6      (mux_bus_addr[6]),
    .nbyte6     (mux_bus_nbyte[6]),
    .data6      (mux_bus_data_write[6]),
    .rd_data6   (mux_bus_data_read[6]),  
    .req7       (mux_bus_req[7]),
    .ack7       (mux_bus_ack[7]),
    .rnw7       (mux_bus_rnw[7]),
    .addr7      (mux_bus_addr[7]),
    .nbyte7     (mux_bus_nbyte[7]),
    .data7      (mux_bus_data_write[7]),
    .rd_data7   (mux_bus_data_read[7]), 

    .de_req     (de_req_o),         /* Connections out to the framestore */
    .de_ack     (de_ack_i),
    .de_rnw     (de_RnW_o),
    .de_addr    (de_address_o),
    .de_nbyte   (de_nbyte_o),
    .de_data    (de_wr_data_o),
    .de_rd_data (de_rd_data_i)
);

logic busy;
assign busy = busy_bus[0]|busy_bus[1]|busy_bus[2];

drawing_demux_8 u_drawing_demux_8(
    .de_req  (req_i & ~busy),
    .de_cmd  (command_i),
    .de_req0 (demux_bus_de_req[0]),
    .de_req1 (demux_bus_de_req[1]),
    .de_req2 (demux_bus_de_req[2]),
    .de_req3 (demux_bus_de_req[3]),
    .de_req4 (demux_bus_de_req[4]),
    .de_req5 (demux_bus_de_req[5]),
    .de_req6 (demux_bus_de_req[6]),
    .de_req7 (demux_bus_de_req[7]),
    .de_ack0 (demux_bus_de_ack[0]),
    .de_ack1 (demux_bus_de_ack[1]),
    .de_ack2 (demux_bus_de_ack[2]),
    .de_ack3 (demux_bus_de_ack[3]),
    .de_ack4 (demux_bus_de_ack[4]),
    .de_ack5 (demux_bus_de_ack[5]),
    .de_ack6 (demux_bus_de_ack[6]),
    .de_ack7 (demux_bus_de_ack[7]),
    .de_ack  (ack)
);


/****************************************************************************/
/* Drawing Components *******************************************************/

// No mux at present 
drawing_clear u_drawing_clear(
    .clk       (clk),
    .reset     (reset),
    .req       (demux_bus_de_req[0]),
    .ack       (demux_bus_de_ack[0]),
    .busy      (busy_bus[0]),
    .r0        (arguments_i[0]),
    .r1        (arguments_i[1]),
    .r2        (arguments_i[2]),
    .r3        (arguments_i[3]),
    .r4        (arguments_i[4]),
    .r5        (arguments_i[5]),
    .r6        (arguments_i[6]),
    .r7        (arguments_i[7]),
    .display_base(display_base_i),
    .display_height(display_height_i),
    .display_mode(display_mode_i),
    .display_width(display_width_i),
    .de_req    (mux_bus_req[0]),
    .de_ack    (mux_bus_ack[0]),
    .de_addr   (mux_bus_addr[0]),
    .de_nbyte  (mux_bus_nbyte[0]),
    .de_rnw    (mux_bus_rnw[0]),
    .de_w_data (mux_bus_data_write[0]),
    .de_r_data (mux_bus_data_read[0])
);



drawing_line  u_drawing_line (
    .clk       (clk),
    .reset     (reset),
    .req       (demux_bus_de_req[1]),
    .ack       (demux_bus_de_ack[1]),
    .busy      (busy_bus[1]),
    .r0        (arguments_i[0]),
    .r1        (arguments_i[1]),
    .r2        (arguments_i[2]),
    .r3        (arguments_i[3]),
    .r4        (arguments_i[4]),
    .r5        (arguments_i[5]),
    .r6        (arguments_i[6]),
    .r7        (arguments_i[7]),
    .display_base(display_base_i),
    .display_height(display_height_i),
    .display_mode(display_mode_i),
    .display_width(display_width_i), 
    .de_req    (mux_bus_req[1]),
    .de_ack    (mux_bus_ack[1]),
    .de_addr   (mux_bus_addr[1]),
    .de_nbyte  (mux_bus_nbyte[1]),
    .de_rnw    (mux_bus_rnw[1]),
    .de_w_data (mux_bus_data_write[1]),
    .de_r_data (mux_bus_data_read[1])
);

drawing_gradient u_drawing_dummy_2(
    .clk       (clk),
    .req       (demux_bus_de_req[2]),
    .reset     (reset),
    .ack       (demux_bus_de_ack[2]),
    .busy      (busy_bus[2]),
    .r0        (arguments_i[0]),
    .r1        (arguments_i[1]),
    .r2        (arguments_i[2]),
    .r3        (arguments_i[3]),
    .r4        (arguments_i[4]),
    .r5        (arguments_i[5]),
    .r6        (arguments_i[6]),
    .r7        (arguments_i[7]),
    .display_base(display_base_i),
    .display_height(display_height_i),
    .display_mode(display_mode_i),
    .display_width(display_width_i),  
    .de_req    (mux_bus_req[2]),
    .de_ack    (mux_bus_ack[2]),
    .de_addr   (mux_bus_addr[2]),
    .de_nbyte  (mux_bus_nbyte[2]),
    .de_rnw    (mux_bus_rnw[2]),
    .de_w_data (mux_bus_data_write[2]),
    .de_r_data (mux_bus_data_read[2])
);

drawing_dummy  u_drawing_dummy_3(
    .clk       (clk),
    .reset     (reset),
    .req       (demux_bus_de_req[3]),
    .ack       (demux_bus_de_ack[3]),
    .busy      (busy_bus[3]),
    .r0        (arguments_i[0]),
    .r1        (arguments_i[1]),
    .r2        (arguments_i[2]),
    .r3        (arguments_i[3]),
    .r4        (arguments_i[4]),
    .r5        (arguments_i[5]),
    .r6        (arguments_i[6]),
    .r7        (arguments_i[7]),
    .display_base(display_base_i),
    .display_height(display_height_i),
    .display_mode(display_mode_i),
    .display_width(display_width_i), 
    .de_req    (mux_bus_req[3]),
    .de_ack    (mux_bus_ack[3]),
    .de_addr   (mux_bus_addr[3]),
    .de_nbyte  (mux_bus_nbyte[3]),
    .de_rnw    (mux_bus_rnw[3]),
    .de_w_data (mux_bus_data_write[3]),
    .de_r_data (mux_bus_data_read[3])
);

drawing_dummy  u_drawing_dummy_4(
    .clk       (clk),
    .reset     (reset),
    .req       (demux_bus_de_req[4]),
    .ack       (demux_bus_de_ack[4]),
    .busy      (busy_bus[4]),
    .r0        (arguments_i[0]),
    .r1        (arguments_i[1]),
    .r2        (arguments_i[2]),
    .r3        (arguments_i[3]),
    .r4        (arguments_i[4]),
    .r5        (arguments_i[5]),
    .r6        (arguments_i[6]),
    .r7        (arguments_i[7]),
    .display_base(display_base_i),
    .display_height(display_height_i),
    .display_mode(display_mode_i),
    .display_width(display_width_i), 
    .de_req    (mux_bus_req[4]),
    .de_ack    (mux_bus_ack[4]),
    .de_addr   (mux_bus_addr[4]),
    .de_nbyte  (mux_bus_nbyte[4]),
    .de_rnw    (mux_bus_rnw[4]),
    .de_w_data (mux_bus_data_write[4]),
    .de_r_data (mux_bus_data_read[4])
);

drawing_dummy  u_drawing_dummy_5(
    .clk       (clk),
    .reset     (reset),
    .req       (demux_bus_de_req[5]),
    .ack       (demux_bus_de_ack[5]),
    .busy      (busy_bus[5]),
    .r0        (arguments_i[0]),
    .r1        (arguments_i[1]),
    .r2        (arguments_i[2]),
    .r3        (arguments_i[3]),
    .r4        (arguments_i[4]),
    .r5        (arguments_i[5]),
    .r6        (arguments_i[6]),
    .r7        (arguments_i[7]),
    .display_base(display_base_i),
    .display_height(display_height_i),
    .display_mode(display_mode_i),
    .display_width(display_width_i), 
    .de_req    (mux_bus_req[5]),
    .de_ack    (mux_bus_ack[5]),
    .de_addr   (mux_bus_addr[5]),
    .de_nbyte  (mux_bus_nbyte[5]),
    .de_rnw    (mux_bus_rnw[5]),
    .de_w_data (mux_bus_data_write[5]),
    .de_r_data (mux_bus_data_read[5])
);

drawing_dummy  u_drawing_dummy_6(
    .clk       (clk),
    .reset     (reset),
    .req       (demux_bus_de_req[6]),
    .ack       (demux_bus_de_ack[6]),
    .busy      (busy_bus[6]),
    .r0        (arguments_i[0]),
    .r1        (arguments_i[1]),
    .r2        (arguments_i[2]),
    .r3        (arguments_i[3]),
    .r4        (arguments_i[4]),
    .r5        (arguments_i[5]),
    .r6        (arguments_i[6]),
    .r7        (arguments_i[7]),
    .display_base(display_base_i),
    .display_height(display_height_i),
    .display_mode(display_mode_i),
    .display_width(display_width_i), 
    .de_req    (mux_bus_req[6]),
    .de_ack    (mux_bus_ack[6]),
    .de_addr   (mux_bus_addr[6]),
    .de_nbyte  (mux_bus_nbyte[6]),
    .de_rnw    (mux_bus_rnw[6]),
    .de_w_data (mux_bus_data_write[6]),
    .de_r_data (mux_bus_data_read[6])
);

drawing_dummy  u_drawing_dummy_7(
    .clk       (clk),
    .reset     (reset),
    .req       (demux_bus_de_req[7]),
    .ack       (demux_bus_de_ack[7]),
    .busy      (busy_bus[7]),
    .r0        (arguments_i[0]),
    .r1        (arguments_i[1]),
    .r2        (arguments_i[2]),
    .r3        (arguments_i[3]),
    .r4        (arguments_i[4]),
    .r5        (arguments_i[5]),
    .r6        (arguments_i[6]),
    .r7        (arguments_i[7]),
    .display_base(display_base_i),
    .display_height(display_height_i),
    .display_mode(display_mode_i),
    .display_width(display_width_i), 
    .de_req    (mux_bus_req[7]),
    .de_ack    (mux_bus_ack[7]),
    .de_addr   (mux_bus_addr[7]),
    .de_nbyte  (mux_bus_nbyte[7]),
    .de_rnw    (mux_bus_rnw[7]),
    .de_w_data (mux_bus_data_write[7]),
    .de_r_data (mux_bus_data_read[7])
);

endmodule