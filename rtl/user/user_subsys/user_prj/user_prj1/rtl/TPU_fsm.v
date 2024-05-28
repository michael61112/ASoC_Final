module TPU_fsm
#(  parameter ADDR_BITS=16, 
	parameter DATA_BITS=32,
	parameter DATAC_BITS=128,
	parameter S0 = 4'b0000,
	parameter S1 = 4'b0001,
	parameter S2 = 4'b0010,
	parameter S3 = 4'b0011,
	parameter S4 = 4'b0100,
	parameter S5 = 4'b0101,
	parameter S6 = 4'b0110,
	parameter S7 = 4'b0111,
	parameter S8 = 4'b1000,
	parameter S9 = 4'b1001
)
(
	// Global Signals 
	input   wire                     	clk,
	input   wire                     	rst_n,
	output  wire [3:0] 			 	    state_TPU_o,
    input            					in_valid,
	input								done,
    input [7:0]      					K,
    input [7:0]     					M,
    input [7:0]      					N,


    output     							busy,
    output      						sa_rst_n,

	output      						A_wr_en,
	output [15:0]    					A_index,
	input  [31:0]    					A_data_out,
	
	output      						B_wr_en,
	output [15:0]    					B_index,
	input  [31:0]    					B_data_out,
    
	output      						C_wr_en,
    output  [ADDR_BITS-1:0]    			C_index,
    output  [DATAC_BITS-1:0]    		C_data_in,

	output [DATA_BITS-1:0] local_buffer_A0,
	output [DATA_BITS-1:0] local_buffer_A1,
	output [DATA_BITS-1:0] local_buffer_A2,
	output [DATA_BITS-1:0] local_buffer_A3,
	output [DATA_BITS-1:0] local_buffer_B0,
	output [DATA_BITS-1:0] local_buffer_B1,
	output [DATA_BITS-1:0] local_buffer_B2,
	output [DATA_BITS-1:0] local_buffer_B3,

	input [DATAC_BITS-1:0] local_buffer_C0,
	input [DATAC_BITS-1:0] local_buffer_C1,
	input [DATAC_BITS-1:0] local_buffer_C2,
	input [DATAC_BITS-1:0] local_buffer_C3
);

	reg [15:0]				 			i, j;
	integer								t;
	reg [3:0] 							state;
	assign state_TPU_o = state;
	
	reg A_wr_en_temp;
	reg B_wr_en_temp;
	reg C_wr_en_temp;
	reg busy_temp;
	reg sa_rst_n_temp;

	reg [DATAC_BITS-1:0] result[3:0];
	wire [DATAC_BITS-1:0] result_temp[3:0];
	
	assign result_temp[0] = local_buffer_C0;
	assign result_temp[1] = local_buffer_C1;
	assign result_temp[2] = local_buffer_C2;

	reg [7:0]    K_reg;
	reg [7:0]    M_reg;
	reg [7:0]    N_reg;

	assign result_temp[3] = local_buffer_C3;

	reg [5:0] check_Koffset_times;
	reg [5:0] check_Moffset_times;
	reg [5:0] check_Noffset_times;

	reg [5:0] Koffset_times;
	reg [5:0] Moffset_times;
	reg [5:0] Noffset_times;

	reg [7:0] Koffset;
	reg [7:0] Moffset;
	reg [7:0] Noffset;

	reg [ADDR_BITS-1:0] Moffset_index_o;
	reg [ADDR_BITS-1:0] Noffset_index_o;
	//assign check_Koffset_times = (K==4) ? 0 : (K>>2);
always @(posedge clk) begin
		if(in_valid) begin
			K_reg <= K;
			M_reg <= M;
			N_reg <= N;
			check_Koffset_times <= (K==4) ? 0 : (K>>2);
			check_Moffset_times <= (M==4) ? 0 : (M>>2);
			check_Noffset_times <= (N==4) ? 0 : (N>>2);
		end
end

	assign A_wr_en = A_wr_en_temp;
	assign B_wr_en = B_wr_en_temp;
	assign C_wr_en = C_wr_en_temp;
	assign busy = busy_temp;	
	assign sa_rst_n = sa_rst_n_temp;


	reg [ADDR_BITS-1:0]    			A_index_temp;
	reg [ADDR_BITS-1:0]    			B_index_temp;
	reg [ADDR_BITS-1:0]    			C_index_temp;
	reg [DATAC_BITS-1:0]			C_data_in_temp;

	assign	A_index = A_index_temp;
	assign	B_index = B_index_temp;
	assign	C_index = C_index_temp;
	assign 	C_data_in = C_data_in_temp;

	reg [DATA_BITS-1:0]	local_buffer_A[3:0];
	reg [DATA_BITS-1:0]	local_buffer_B[3:0];

	assign local_buffer_A0 = local_buffer_A[0];
	assign local_buffer_A1 = local_buffer_A[1];
	assign local_buffer_A2 = local_buffer_A[2];
	assign local_buffer_A3 = local_buffer_A[3];

	assign local_buffer_B0 = local_buffer_B[0];
	assign local_buffer_B1 = local_buffer_B[1];
	assign local_buffer_B2 = local_buffer_B[2];
	assign local_buffer_B3 = local_buffer_B[3];

	always@(negedge clk) begin
		if (!rst_n) begin
			state <= S0;
		end else begin
			case(state)
				S0: begin
					if (in_valid) begin
						state <= S1;
					end
					else begin
						state <= S0;
					end
				end
				S1: begin
					if (i == 4) begin
						state <= S3;
					end
					else begin
						state <= S2;
					end
				end
				S2: begin
					state <= S1;
				end
				S3: begin
					if (done) begin
						state <= S6;
					end
					else begin
						state <= S3;
					end
				end
				S4: begin
					if (j == 4) begin
						if (Moffset_times == check_Moffset_times) begin
							if (Noffset_times == check_Noffset_times) begin
								state <= S0;
							end
							else begin
								state <= S9;
							end
						end	
						else begin
							state <= S8;
						end
					end
					else begin
						state <= S5;
					end
				end
				S5: begin
					state <= S4;
				end
				S6: begin
					if(Koffset_times == check_Koffset_times) begin
						state <= S4;
					end
					else begin
						state <= S7;
					end
				end
				S7: begin
					state <= S1;
				end
				S8: begin
					state <= S1;
				end
				S9: begin
					state <= S1;
				end
				default: begin 
					state <= S0;
				end
			endcase
		end
	end
	
	// Set output value
	always @(posedge clk) begin
		case(state)
			S0: begin
				A_wr_en_temp <= 1'b0;
				B_wr_en_temp <= 1'b0;
				C_wr_en_temp <= 1'b0;
				busy_temp <= 1'b0;
				sa_rst_n_temp <= 1'b0;
				i=0;
				j=0;
				for (t = 0; t <4; t = t + 1)
					result[t] <= 128'b0;
				Koffset_times <= 0;
				Koffset <= 0;
				
				Moffset_times <= 0;
				Moffset <= 0;
				Moffset_index_o <= 0;

				Noffset_times <= 0;
				Noffset <= 0;
				Noffset_index_o <= 0;
			end
			S1: begin
				A_wr_en_temp <= 1'b0;
				B_wr_en_temp <= 1'b0;
				C_wr_en_temp <= 1'b0;
				busy_temp <= 1'b1;
				sa_rst_n_temp <= 1'b0;

				A_index_temp <= i + Koffset + Moffset;
				B_index_temp <= i + Koffset + Noffset;
			end
			S2: begin
				A_wr_en_temp <= 1'b0;
				B_wr_en_temp <= 1'b0;
				C_wr_en_temp <= 1'b0;
				busy_temp <= 1'b1;
				sa_rst_n_temp <= 1'b0;
				if ( A_index_temp < K_reg * (Moffset_times+1)) begin
					local_buffer_A[i] <= A_data_out;
					local_buffer_B[i] <= B_data_out;
				end
				else begin
					local_buffer_A[i] <= 32'b0;
					local_buffer_B[i] <= 32'b0;
				end
				i <= i + 1;
			end
			S3: begin
				A_wr_en_temp <= 1'b0;
				B_wr_en_temp <= 1'b0;
				C_wr_en_temp <= 1'b0;
				busy_temp <= 1'b1;
				sa_rst_n_temp <= 1'b1;
			end
			S4: begin
				A_wr_en_temp <= 1'b0;
				B_wr_en_temp <= 1'b0;
				C_wr_en_temp <= 1'b1;
				busy_temp <= 1'b1;
				sa_rst_n_temp <= 1'b1;

				C_index_temp = j + Moffset_index_o + Noffset_index_o;
			end
			S5: begin
				A_wr_en_temp <= 1'b0;
				B_wr_en_temp <= 1'b0;
				C_wr_en_temp <= 1'b1;
				busy_temp <= 1'b1;
				sa_rst_n_temp <= 1'b1;

				C_data_in_temp <= result[j];
				j <= j + 1;
			end
			S6: begin
				A_wr_en_temp <= 1'b0;
				B_wr_en_temp <= 1'b0;
				C_wr_en_temp <= 1'b0;
				busy_temp <= 1'b1;
				sa_rst_n_temp <= 1'b0;

				for (t = 0; t < 4; t = t + 1)
					result[t] <= result[t] + result_temp[t];
				
			end
			S7: begin
				A_wr_en_temp <= 1'b0;
				B_wr_en_temp <= 1'b0;
				C_wr_en_temp <= 1'b0;
				busy_temp <= 1'b1;
				sa_rst_n_temp <= 1'b0;

				Koffset_times <= Koffset_times + 1;
				Koffset <= Koffset + 4;
				i <= 0;
			end
			S8: begin
				A_wr_en_temp <= 1'b0;
				B_wr_en_temp <= 1'b0;
				C_wr_en_temp <= 1'b0;
				busy_temp <= 1'b1;
				sa_rst_n_temp <= 1'b0;
				i=0;
				j=0;
				for (t = 0; t <4; t = t + 1)
					result[t] <= 128'b0;
				Koffset_times <= 0;
				Koffset <= 0;

				Moffset_times <= Moffset_times + 1;
				Moffset <= Moffset + K_reg;
				Moffset_index_o <= Moffset_index_o + 4;
			end
			S9: begin
				A_wr_en_temp <= 1'b0;
				B_wr_en_temp <= 1'b0;
				C_wr_en_temp <= 1'b0;
				busy_temp <= 1'b1;
				sa_rst_n_temp <= 1'b0;
				i=0;
				j=0;
				for (t = 0; t <4; t = t + 1)
					result[t] <= 128'b0;
				Koffset_times <= 0;
				Koffset <= 0;

				Moffset_times <= 0;
				Moffset <= 0;
				Moffset_index_o <= 0;

				Noffset_times <= Noffset_times + 1;
				Noffset <= Noffset + K_reg;
				Noffset_index_o <= Noffset_index_o + M_reg;
			end
		endcase
	end


endmodule