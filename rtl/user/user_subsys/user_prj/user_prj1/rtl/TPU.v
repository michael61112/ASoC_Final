//`include "systolic_array.v"
//`include "TPU_fsm.v"
module TPU
#(  parameter ADDR_BITS=16, 
	parameter DATA_BITS=32,
	parameter DATAC_BITS=128
)(
    clk,
    rst_n,

    state_TPU_o,
    state_SA_o,

    local_buffer_A0_o,
    local_buffer_A1_o,
    local_buffer_A2_o,
    local_buffer_A3_o,

    local_buffer_B0_o,
    local_buffer_B1_o,
    local_buffer_B2_o,
    local_buffer_B3_o,

    local_buffer_C0_o,
    local_buffer_C1_o,
    local_buffer_C2_o,
    local_buffer_C3_o,

    result0_o,

	inp_north0_o,
	inp_north1_o,
	inp_north2_o,
	inp_north3_o,
	inp_west0_o, 
	inp_west4_o, 
	inp_west8_o, 
	inp_west12_o,

    in_valid,
    K,
    M,
    N,
    busy,

    A_wr_en,
    A_index,
    A_data_in,
    A_data_out,

    B_wr_en,
    B_index,
    B_data_in,
    B_data_out,

    C_wr_en,
    C_index,
    C_data_in,
    C_data_out
);


input clk;
input rst_n;
input            in_valid;
input [7:0]      K;
input [7:0]      M;
input [7:0]      N;
output           busy;
output [3:0]     state_TPU_o;
output [2:0]     state_SA_o;


output [DATA_BITS-1:0] local_buffer_A0_o;
output [DATA_BITS-1:0] local_buffer_A1_o;
output [DATA_BITS-1:0] local_buffer_A2_o;
output [DATA_BITS-1:0] local_buffer_A3_o;

output [DATA_BITS-1:0] local_buffer_B0_o;
output [DATA_BITS-1:0] local_buffer_B1_o;
output [DATA_BITS-1:0] local_buffer_B2_o;
output [DATA_BITS-1:0] local_buffer_B3_o;

output [DATAC_BITS-1:0] local_buffer_C0_o;
output [DATAC_BITS-1:0] local_buffer_C1_o;
output [DATAC_BITS-1:0] local_buffer_C2_o;
output [DATAC_BITS-1:0] local_buffer_C3_o;

output [31:0] result0_o;

output [7:0] inp_north0_o;
output [7:0] inp_north1_o;
output [7:0] inp_north2_o;
output [7:0] inp_north3_o;
output [7:0] inp_west0_o;
output [7:0] inp_west4_o; 
output [7:0] inp_west8_o; 
output [7:0] inp_west12_o;

output           A_wr_en;
output [15:0]    A_index;
output [31:0]    A_data_in;
input  [31:0]    A_data_out;

output           B_wr_en;
output [15:0]    B_index;
output [31:0]    B_data_in;
input  [31:0]    B_data_out;

output           C_wr_en;
output [15:0]    C_index;
output [127:0]   C_data_in;
input  [127:0]   C_data_out;





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


assign local_buffer_A0_o = local_buffer_A0;
assign local_buffer_A1_o = local_buffer_A1;
assign local_buffer_A2_o = local_buffer_A2;
assign local_buffer_A3_o = local_buffer_A3;

assign local_buffer_B0_o = local_buffer_B0;
assign local_buffer_B1_o = local_buffer_B1;
assign local_buffer_B2_o = local_buffer_B2;
assign local_buffer_B3_o = local_buffer_B3;

assign local_buffer_C0_o = local_buffer_C0;
assign local_buffer_C1_o = local_buffer_C1;
assign local_buffer_C2_o = local_buffer_C2;
assign local_buffer_C3_o = local_buffer_C3;
//assign busy = 1'b0;
/*
always@(*) begin
    busy = 1'b0;
end
assign A_wr_en = 1'b0;
assign B_wr_en = 1'b0;

assign result_matrix_M = (M==4) ? 1 : (M>>2) + 1;
assign result_matrix_N = (N==4) ? 1 : (N>>2) + 1;
assign accuminate_time_K = (K>>2);
assign offset_K = accuminate_time_K;
assign count
*/
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
	.state_TPU_o(state_TPU_o),
    .in_valid(in_valid),
    .done(done),
    .K(K),
    .M(M),
    .N(N),


    .busy(busy),
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

// debug
	.inp_north0_o(inp_north0_o),
	.inp_north1_o(inp_north1_o),
	.inp_north2_o(inp_north2_o),
	.inp_north3_o(inp_north3_o),
	.inp_west0_o(inp_west0_o), 
	.inp_west4_o(inp_west4_o), 
	.inp_west8_o(inp_west8_o), 
	.inp_west12_o(inp_west12_o),

    .result0_o(result0_o),
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
