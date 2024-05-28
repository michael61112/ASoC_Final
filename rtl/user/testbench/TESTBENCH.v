//============================================================================//
// AAML2022 LAB1 - TPU design                                                 //
// file: TESTNEMCJ.v                                                          //
// description: testbench for tpu top module                                  //
// authors: nober  (nobertai.c@nycu.edu.tw                                    //
//============================================================================//

`timescale 1ns/10ps
//`include "PATTERN.v"
//`include "TPU.v"



module TESTBENCH;



//* CHIP io wires
wire            clk, rst_n;
wire [3:0]      state_TPU_o;
wire [2:0]      state_SA_o;


wire [31:0] local_buffer_A0_o;
wire [31:0] local_buffer_A1_o;
wire [31:0] local_buffer_A2_o;
wire [31:0] local_buffer_A3_o;

wire [31:0] local_buffer_B0_o;
wire [31:0] local_buffer_B1_o;
wire [31:0] local_buffer_B2_o;
wire [31:0] local_buffer_B3_o;

wire [127:0] local_buffer_C0_o;
wire [127:0] local_buffer_C1_o;
wire [127:0] local_buffer_C2_o;
wire [127:0] local_buffer_C3_o;

wire [31:0] result0_o;

wire [7:0] inp_north0_o;
wire [7:0] inp_north1_o;
wire [7:0] inp_north2_o;
wire [7:0] inp_north3_o;
wire [7:0] inp_west0_o;
wire [7:0] inp_west4_o; 
wire [7:0] inp_west8_o; 
wire [7:0] inp_west12_o;

wire            in_valid;
wire [7:0]      K;
wire [7:0]      M;
wire [7:0]      N;
wire            busy;
wire            A_wr_en;
wire [15:0]     A_index;
wire [31:0]     A_data_in;
wire [31:0]     A_data_out;
wire            B_wr_en;
wire [15:0]     B_index;
wire [31:0]     B_data_in;
wire [31:0]     B_data_out;
wire            C_wr_en;
wire [15:0]     C_index;
wire [127:0]    C_data_in;
wire [127:0]    C_data_out;


initial begin
    `ifdef RTL
        // $fsdbDumpfile("TPU.fsdb");
        // $fsdbDumpvars(0,"+mda");
    // `elsif GATE
        // $sdf_annotate("TPU_SYN.sdf",U_TPU);
        // $fsdbDumpfile("TPU.fsdb");
        // $fsdbDumpvars(0,"+mda");
    // `elsif POST
        // $sdf_annotate("CHIP.sdf", U_CHIP);
        // $fsdbDumpfile("CHIP.fsdb");
        // $fsdbDumpvars(0,"+mda");
    `endif
end


PATTERN My_Pattern(
    .clk            (clk),     
    .rst_n          (rst_n),     
    .in_valid       (in_valid),         
    .K              (K), 
    .M              (M), 
    .N              (N), 
    .busy           (busy),     
    .A_wr_en        (A_wr_en),         
    .A_index        (A_index),         
    .A_data_in      (A_data_in),         
    .A_data_out     (A_data_out),         
    .B_wr_en        (B_wr_en),         
    .B_index        (B_index),         
    .B_data_in      (B_data_in),         
    .B_data_out     (B_data_out),         
    .C_wr_en        (C_wr_en),         
    .C_index        (C_index),         
    .C_data_in      (C_data_in),         
    .C_data_out     (C_data_out)         
);




TPU My_TPU(
    .clk            (clk),     
    .rst_n          (rst_n),     
    .state_TPU_o    (state_TPU_o),
    .state_SA_o     (state_SA_o),

    .local_buffer_A0_o(local_buffer_A0_o),
    .local_buffer_A1_o(local_buffer_A1_o),
    .local_buffer_A2_o(local_buffer_A2_o),
    .local_buffer_A3_o(local_buffer_A3_o),

    .local_buffer_B0_o(local_buffer_B0_o),
    .local_buffer_B1_o(local_buffer_B1_o),
    .local_buffer_B2_o(local_buffer_B2_o),
    .local_buffer_B3_o(local_buffer_B3_o),

    .local_buffer_C0_o(local_buffer_C0_o),
    .local_buffer_C1_o(local_buffer_C1_o),
    .local_buffer_C2_o(local_buffer_C2_o),
    .local_buffer_C3_o(local_buffer_C3_o),

    .result0_o(result0_o),
	.inp_north0_o(inp_north0_o),
	.inp_north1_o(inp_north1_o),
	.inp_north2_o(inp_north2_o),
	.inp_north3_o(inp_north3_o),
	.inp_west0_o(inp_west0_o), 
	.inp_west4_o(inp_west4_o), 
	.inp_west8_o(inp_west8_o), 
	.inp_west12_o(inp_west12_o),

    .in_valid       (in_valid),         
    .K              (K), 
    .M              (M), 
    .N              (N), 
    .busy           (busy),     
    .A_wr_en        (A_wr_en),         
    .A_index        (A_index),         
    .A_data_in      (A_data_in),         
    .A_data_out     (A_data_out),         
    .B_wr_en        (B_wr_en),         
    .B_index        (B_index),         
    .B_data_in      (B_data_in),         
    .B_data_out     (B_data_out),         
    .C_wr_en        (C_wr_en),         
    .C_index        (C_index),         
    .C_data_in      (C_data_in),         
    .C_data_out     (C_data_out)         
);




endmodule



