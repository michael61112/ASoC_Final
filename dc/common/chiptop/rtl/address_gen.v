module address_gen_fsm
#(  parameter S0 = 2'b00,
	parameter S1 = 2'b01,
	parameter S2 = 2'b10,
	parameter S3 = 2'b11 
)
(
	// Global Signals 
	input   wire                     	clk,
	input   wire                     	rst_n,
	output  wire [1:0] 			 	    state_o,
	
    input   wire [(pADDR_WIDTH-1):0] 	config_write_address,
    input   wire [(pDATA_WIDTH-1):0] 	config_write_data,
	input   wire [9:0]					counter,
	input   wire [31:0]                 data_length,
	input   wire 						sm_tvalid,
	
	output	wire						ap_start,
	output	wire						ap_done,
	output	wire						ap_idle,
	output	wire						fir_start


    input clk;
    input rst_n;
    input            in_valid;
    input [7:0]      K;
    input [7:0]      M;
    input [7:0]      N;
    output  reg      busy;
    output  reg      sa_rst;
    output  reg      A_wr_en;
    output  reg      B_wr_en;
    output  reg      C_wr_en;
    output  reg  [ADDR_BITS-1:0]    C_index;
    output  reg  [DATA_BITS-1:0]    C_data_in;
);
begin
	
	reg [1:0] state;
	assign state_o = state;
	
	reg ;
	reg ;
	reg ;
	reg ;
	
	always@(negedge clk) begin
		if (!rst_n) begin
			state <= S0;
		end else begin
			case(state)
				S0: begin

				end
				S1: begin
						state <= S2;
				end
				S2: begin

				end
				S3: begin
						state <= S3;
				end
				default: begin 
					state <= S0;
				end
			endcase
		end
	end
	
	// Set output value
	always @(posedge axis_clk) begin
		case(state)
			S0: begin ap_start_temp <= 1'b0; ap_done_temp <= 1'b0; ap_idle_temp <= 1'b1; fir_start_temp <= 1'b0; end
                i = 16'b0;
			S1: begin ap_start_temp <= 1'b1; ap_done_temp <= 1'b0; ap_idle_temp <= 1'b0; fir_start_temp <= 1'b0; end
                A_wr_en <= 1'b0;
                A_index <= 16'b0 + i;
                B_wr_en <= 1'b0;
                B_index <= 16'b0 + i;

			S2: begin ap_start_temp <= 1'b0; ap_done_temp <= 1'b0; ap_idle_temp <= 1'b0; fir_start_temp <= 1'b1; 
                A_data_buff[i] <= A_data_out;
                B_data_buff[i] <= B_data_out;
                i = i + 1;
            end
			S3: begin 
                data_ready <= 1'b1;
            end
            S4: begin
                C_wr_en <= 1'b1;
                C_index <= 16'b0 + i;
                C_data_in <= C_data_in_array[i];
                i <= i + 16'b1;
                /*
                gbuff_C[0][31:24] <= result0; gbuff_C[0][23:16] <= result1; gbuff_C[0][15:8] <= result2; gbuff_C[0][7:0] <= result3;
                gbuff_C[1][31:24] <= result4; gbuff_C[1][23:16] <= result5; gbuff_C[1][15:8] <= result6; gbuff_C[1][7:0] <= result7;
                gbuff_C[2][31:24] <= result8; gbuff_C[2][23:16] <= result9; gbuff_C[2][15:8] <= result10; gbuff_C[2][7:0] <= result11;
                gbuff_C[3][31:24] <= result12; gbuff_C[3][23:16] <= result13; gbuff_C[3][15:8] <= result14; gbuff_C[3][7:0] <= result15;
                */
            end
		endcase
	end
    reg [15:0]				 i;
    reg [31:0]A_data_buff[3:0];
    reg [31:0]B_data_buff[3:0];


	assign ap_start = ap_start_temp;
	assign ap_done = ap_done_temp;	
	assign ap_idle = ap_idle_temp;
	assign fir_start = fir_start_temp;

    assign inp_north0 = (addr_n0 >= 0 && addr_n0 < K) ? gbuff_A[0 + addr_n0][31:24] : 8'b0;
    assign inp_north1 = (addr_n1 >= 0 && addr_n1 < K) ? gbuff_A[0 + addr_n1][23:16] : 8'b0;
    assign inp_north2 = (addr_n2 >= 0 && addr_n2 < K) ? gbuff_A[0 + addr_n2][15:8] : 8'b0;
    assign inp_north3 = (addr_n3 >= 0 && addr_n3 < K) ? gbuff_A[0 + addr_n3][7:0] : 8'b0;
	
    assign inp_west0 = (addr_w0 >= 0 && addr_w0 < K) ? gbuff_B[0][31-(addr_w0*8):24-(addr_w0*8)] : 8'b0;
    assign inp_west4 = (addr_w4 >= 0 && addr_w4 < K) ? gbuff_B[1][23-(addr_w4*8):16-(addr_w4*8)] : 8'b0;
    assign inp_west8 = (addr_w8 >= 0 && addr_w8 < K) ? gbuff_B[2][15-(addr_w8*8):8-(addr_w8*8)] : 8'b0;
    assign inp_west12 = (addr_w12 >= 0 && addr_w12 < K) ? gbuff_B[3][7-(addr_w12*8):0-(addr_w12*8)] : 8'b0;

             
end
endmodule