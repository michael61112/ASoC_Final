//`include "systolic_array.v"
//`include "TPU_fsm.v"
module TPU
#(  parameter ADDR_BITS=16, 
	parameter DATA_BITS=32,
	parameter DATAC_BITS=128
)(
    clk,
    rst_n,

    in_valid,
    K,
    M,
    N,
    busy,
	ap_done,
	ap_idle,

    A_wr_en,
    A_index,
    //A_data_in,
    A_data_out,

    B_wr_en,
    B_index,
    //B_data_in,
    B_data_out,

    C_wr_en,
    C_index,
    C_data_in,
    //C_data_out
);

input clk;
input rst_n;
input            in_valid;
input [7:0]      K;
input [7:0]      M;
input [7:0]      N;
output           busy;
output           ap_done;
output           ap_idle;

output           A_wr_en;
output [15:0]    A_index;
//output [31:0]    A_data_in;
input  [31:0]    A_data_out;

output           B_wr_en;
output [15:0]    B_index;
//output [31:0]    B_data_in;
input  [31:0]    B_data_out;

output           C_wr_en;
output [15:0]    C_index;
output [127:0]   C_data_in;
//input  [127:0]   C_data_out;

reg     [31:0]  addr_w0;
reg     [31:0]  addr_w1;
reg     [31:0]  addr_w2;
reg     [31:0]  addr_w3;

reg     [31:0]  addr_n0;
reg     [31:0]  addr_n1;
reg     [31:0]  addr_n2;
reg     [31:0]  addr_n3;

wire result_matrix_M;
wire result_matrix_N;
wire accuminate_time_K;
wire offset_K;
wire    [3:0]  count;

wire sa_rst_n;
wire [DATA_BITS-1:0]	local_buffer_A0;
wire [DATA_BITS-1:0]	local_buffer_A1;
wire [DATA_BITS-1:0]	local_buffer_A2;
wire [DATA_BITS-1:0]	local_buffer_A3;
wire [DATA_BITS-1:0]	local_buffer_B0;
wire [DATA_BITS-1:0]	local_buffer_B1;
wire [DATA_BITS-1:0]	local_buffer_B2;
wire [DATA_BITS-1:0]	local_buffer_B3;
wire [DATAC_BITS-1:0]	local_buffer_C0;
wire [DATAC_BITS-1:0]	local_buffer_C1;
wire [DATAC_BITS-1:0]	local_buffer_C2;
wire [DATAC_BITS-1:0]	local_buffer_C3;

TPU_fsm TPU_fsm1(
    .clk(clk),
	.rst_n(rst_n),
    .in_valid(in_valid),
    .done(done),
    .K(K),
    .M(M),
    .N(N),

    .busy(busy),
	.ap_done(ap_done),
	.ap_idle(ap_idle),
    .sa_rst_n(sa_rst_n),
    // Global Buffer A control
	.A_wr_en(A_wr_en),
	.A_index(A_index),
	.A_data_out(A_data_out),
	// Global Buffer B control
	.B_wr_en(B_wr_en),
	.B_index(B_index),
	.B_data_out(B_data_out),
    // Global Buffer C control
	.C_wr_en(C_wr_en),
    .C_index(C_index),
    .C_data_in(C_data_in),
    // Local Buffer A control
	.local_buffer_A0(local_buffer_A0),
	.local_buffer_A1(local_buffer_A1),
	.local_buffer_A2(local_buffer_A2),
	.local_buffer_A3(local_buffer_A3),
    // Local Buffer B control
	.local_buffer_B0(local_buffer_B0),
	.local_buffer_B1(local_buffer_B1),
	.local_buffer_B2(local_buffer_B2),
	.local_buffer_B3(local_buffer_B3),
    // Local Buffer C control
	.local_buffer_C0(local_buffer_C0),
	.local_buffer_C1(local_buffer_C1),
	.local_buffer_C2(local_buffer_C2),
	.local_buffer_C3(local_buffer_C3)
);

systolic_array systolic_array1(
	
	.clk(clk),
	.sa_rst_n(sa_rst_n),
    .state_SA_o(state_SA_o),
    .busy(busy),
	.done(done),

	.local_buffer_A0(local_buffer_A0),
	.local_buffer_A1(local_buffer_A1),
	.local_buffer_A2(local_buffer_A2),
	.local_buffer_A3(local_buffer_A3),

	.local_buffer_B0(local_buffer_B0),
	.local_buffer_B1(local_buffer_B1),
	.local_buffer_B2(local_buffer_B2),
	.local_buffer_B3(local_buffer_B3),

	.local_buffer_C0(local_buffer_C0),
	.local_buffer_C1(local_buffer_C1),
	.local_buffer_C2(local_buffer_C2),
	.local_buffer_C3(local_buffer_C3)
);


endmodule
