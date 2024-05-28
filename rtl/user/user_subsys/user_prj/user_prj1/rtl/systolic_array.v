/*

MIT License

Copyright (c) 2020 Debtanu Mukherjee

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

//`include "block.v"
module systolic_array
#(  parameter ADDR_BITS=16, 
	parameter DATA_BITS=32,
	parameter DATAC_BITS=128,
	parameter S0 = 3'b000,
	parameter S1 = 3'b001,
	parameter S2 = 3'b010,
	parameter S3 = 3'b011,
	parameter S4 = 3'b100,
	parameter S5 = 3'b101,
	parameter S6 = 3'b110
)
(
	
	input clk,
	input sa_rst_n,
	
	output  wire [2:0] 			 	    state_SA_o,
	input busy,
	output done,

//	debug

	output [7:0] inp_north0_o,
	output [7:0] inp_north1_o,
	output [7:0] inp_north2_o,
	output [7:0] inp_north3_o,
	output [7:0] inp_west0_o, 
	output [7:0] inp_west4_o, 
	output [7:0] inp_west8_o, 
	output [7:0] inp_west12_o,

	output [31:0] result0_o,
//


	input [DATA_BITS-1:0] local_buffer_A0,
	input [DATA_BITS-1:0] local_buffer_A1,
	input [DATA_BITS-1:0] local_buffer_A2,
	input [DATA_BITS-1:0] local_buffer_A3,

	input [DATA_BITS-1:0] local_buffer_B0,
	input [DATA_BITS-1:0] local_buffer_B1,
	input [DATA_BITS-1:0] local_buffer_B2,
	input [DATA_BITS-1:0] local_buffer_B3,

	output [DATAC_BITS-1:0] local_buffer_C0,
	output [DATAC_BITS-1:0] local_buffer_C1,
	output [DATAC_BITS-1:0] local_buffer_C2,
	output [DATAC_BITS-1:0] local_buffer_C3
);

	reg [3:0] count;
	reg [2:0] 							state;
	reg	done_temp;
	
	assign state_SA_o = state;
	assign result0_o = result7;
	wire [7:0] inp_north0, inp_north1, inp_north2, inp_north3;
	wire [7:0] inp_west0, inp_west4, inp_west8, inp_west12;
	wire [7:0] outp_south0, outp_south1, outp_south2, outp_south3, outp_south4, outp_south5, outp_south6, outp_south7, outp_south8, outp_south9, outp_south10, outp_south11, outp_south12, outp_south13, outp_south14, outp_south15;
	wire [7:0] outp_east0, outp_east1, outp_east2, outp_east3, outp_east4, outp_east5, outp_east6, outp_east7, outp_east8, outp_east9, outp_east10, outp_east11, outp_east12, outp_east13, outp_east14, outp_east15;
	wire [31:0] result0, result1, result2, result3, result4, result5, result6, result7, result8, result9, result10, result11, result12, result13, result14, result15;
	// debug

	assign inp_north0_o = inp_north0;
	assign inp_north1_o = inp_north1;
	assign inp_north2_o = inp_north2;
	assign inp_north3_o = inp_north3;
	assign inp_west0_o = inp_west0;
	assign inp_west4_o = inp_west4;
	assign inp_west8_o = inp_west8;
	assign inp_west12_o = inp_west12;

	wire rst;
	assign rst = ~sa_rst_n;
	
	block P0 (inp_north0, inp_west0, clk, rst, outp_south0, outp_east0, result0);
	block P1 (inp_north1, outp_east0, clk, rst, outp_south1, outp_east1, result1);
	block P2 (inp_north2, outp_east1, clk, rst, outp_south2, outp_east2, result2);
	block P3 (inp_north3, outp_east2, clk, rst, outp_south3, outp_east3, result3);
	
	block P4 (outp_south0, inp_west4, clk, rst, outp_south4, outp_east4, result4);
	block P5 (outp_south1, outp_east4, clk, rst, outp_south5, outp_east5, result5);
	block P6 (outp_south2, outp_east5, clk, rst, outp_south6, outp_east6, result6);
	block P7 (outp_south3, outp_east6, clk, rst, outp_south7, outp_east7, result7);

	block P8 (outp_south4, inp_west8, clk, rst, outp_south8, outp_east8, result8);
	block P9 (outp_south5, outp_east8, clk, rst, outp_south9, outp_east9, result9);
	block P10 (outp_south6, outp_east9, clk, rst, outp_south10, outp_east10, result10);
	block P11 (outp_south7, outp_east10, clk, rst, outp_south11, outp_east11, result11);
	
	block P12 (outp_south8, inp_west12, clk, rst, outp_south12, outp_east12, result12);
	block P13 (outp_south9, outp_east12, clk, rst, outp_south13, outp_east13, result13);
	block P14 (outp_south10, outp_east13, clk, rst, outp_south14, outp_east14, result14);
	block P15 (outp_south11, outp_east14, clk, rst, outp_south15, outp_east15, result15);
	

	always@(negedge clk) begin
		if (!sa_rst_n) begin
			state <= S0;
		end else begin
			case(state)
				S0: begin
					if (sa_rst_n) begin
						state <= S1;
					end
					else begin
						state <= S0;
					end
				end
				S1: begin
					if (count == (7+4)) begin
						state <= S2;
					end
					else begin
						state <= S1;
					end
				end
				S2: begin
					state <= S0;
				end
				default: begin 
					state <= S0;
				end
			endcase
		end
	end
/*
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			done <= 0;
			count <= 0;
		end
		else begin
			if(count == count_in) begin
				done <= 1;
				count <= 0;
			end
			else begin
				done <= 0;
				count <= count + 1;
			end
		end	
	end 
	*/

integer addr_n0, addr_n1, addr_n2, addr_n3;
integer addr_w0, addr_w4, addr_w8, addr_w12;

	// Set output value
	always @(posedge clk) begin
		case(state)
			S0: begin 
				addr_n0 <= 0;
				addr_n1 <= -1;
				addr_n2 <= -2;
				addr_n3 <= -3;

				addr_w0 <= 0;
				addr_w4 <= -1;
				addr_w8 <= -2;
				addr_w12 <= -3;

				count <= 0;
				done_temp <= 0;

				local_buffer_A[0] <= local_buffer_A0;
				local_buffer_A[1] <= local_buffer_A1;
				local_buffer_A[2] <= local_buffer_A2;
				local_buffer_A[3] <= local_buffer_A3;

				local_buffer_B[0] <= local_buffer_B0;
				local_buffer_B[1] <= local_buffer_B1;
				local_buffer_B[2] <= local_buffer_B2;
				local_buffer_B[3] <= local_buffer_B3;
			end
			S1: begin 
				addr_n0 <= addr_n0 + 1;
				addr_n1 <= addr_n1 + 1;
				addr_n2 <= addr_n2 + 1;
				addr_n3 <= addr_n3 + 1;

				addr_w0 <= addr_w0 + 1;
				addr_w4 <= addr_w4 + 1;
				addr_w8 <= addr_w8 + 1;
				addr_w12 <= addr_w12 + 1;

				count <= count + 1;
				done_temp <= 0;
				
			end
			S2: begin 
				count <= 0;
				done_temp <= 1;

				local_buffer_C[0] <= {result0, result1, result2, result3};
				local_buffer_C[1] <= {result4, result5, result6, result7};
				local_buffer_C[2] <= {result8, result9, result10, result11};
				local_buffer_C[3] <= {result12, result13, result14, result15};
            end
			default: begin 
				addr_n0 <= 0;
				addr_n1 <= -1;
				addr_n2 <= -2;
				addr_n3 <= -3;

				addr_w0 <= 0;
				addr_w4 <= -1;
				addr_w8 <= -2;
				addr_w12 <= -3;

				count <= 0;
				done_temp <= 0;
            end
		endcase
	end

	//reg [15:0]				 i, j;
    reg [31:0]local_buffer_A[3:0];
    reg [31:0]local_buffer_B[3:0];
	reg [127:0]local_buffer_C[3:0];

	assign local_buffer_C0 = local_buffer_C[0];
	assign local_buffer_C1 = local_buffer_C[1];
	assign local_buffer_C2 = local_buffer_C[2];
	assign local_buffer_C3 = local_buffer_C[3];

	reg [7:0] inp_north0_temp, inp_north1_temp, inp_north2_temp, inp_north3_temp;
	reg [7:0] inp_west0_temp, inp_west4_temp, inp_west8_temp, inp_west12_temp;

	always @(*) begin
		if(addr_n0 >= 0 && addr_n0 < 4) begin
			case (addr_n0)
				0: inp_north0_temp <= local_buffer_B[0][31:24];
				1: inp_north0_temp <= local_buffer_B[1][31:24];
				2: inp_north0_temp <= local_buffer_B[2][31:24];
				3: inp_north0_temp <= local_buffer_B[3][31:24];
			endcase
		end 
		else begin
			inp_north0_temp <= 8'b0;
		end 
		if(addr_n1 >= 0 && addr_n1 < 4) begin
			case (addr_n1)
				0: inp_north1_temp <= local_buffer_B[0][23:16];
				1: inp_north1_temp <= local_buffer_B[1][23:16];
				2: inp_north1_temp <= local_buffer_B[2][23:16];
				3: inp_north1_temp <= local_buffer_B[3][23:16];
			endcase
		end else begin
			inp_north1_temp <= 8'b0;
		end
		if(addr_n2 >= 0 && addr_n2 < 4) begin
			case (addr_n2)
				0: inp_north2_temp <= local_buffer_B[0][15:8];
				1: inp_north2_temp <= local_buffer_B[1][15:8];
				2: inp_north2_temp <= local_buffer_B[2][15:8];
				3: inp_north2_temp <= local_buffer_B[3][15:8];
			endcase
		end else begin
			inp_north2_temp <= 8'b0;
		end
		if(addr_n3 >= 0 && addr_n3 < 4) begin
			case(addr_n3)
				0: inp_north3_temp <= local_buffer_B[0][7:0];
				1: inp_north3_temp <= local_buffer_B[1][7:0];
				2: inp_north3_temp <= local_buffer_B[2][7:0];
				3: inp_north3_temp <= local_buffer_B[3][7:0];
			endcase
		end else begin
			inp_north3_temp <= 8'b0;
		end
	///////////////////////////////////////////////////////////////
		if(addr_w0 >= 0 && addr_w0 < 4) begin
			case (addr_w0)
				0: inp_west0_temp <= local_buffer_A[0][31:24];
				1: inp_west0_temp <= local_buffer_A[1][31:24];
				2: inp_west0_temp <= local_buffer_A[2][31:24];
				3: inp_west0_temp <= local_buffer_A[3][31:24];
			endcase
		end else begin
			inp_west0_temp <= 8'b0;
		end
		if(addr_w4 >= 0 && addr_w4 < 4) begin
			case (addr_w4)
				0: inp_west4_temp <= local_buffer_A[0][23:16];
				1: inp_west4_temp <= local_buffer_A[1][23:16];
				2: inp_west4_temp <= local_buffer_A[2][23:16];
				3: inp_west4_temp <= local_buffer_A[3][23:16];
			endcase
		end else begin
			inp_west4_temp <= 8'b0;
		end
		if(addr_w8 >= 0 && addr_w8 < 4) begin
			case (addr_w8)
				0: inp_west8_temp <= local_buffer_A[0][15:8];
				1: inp_west8_temp <= local_buffer_A[1][15:8];
				2: inp_west8_temp <= local_buffer_A[2][15:8];
				3: inp_west8_temp <= local_buffer_A[3][15:8];
			endcase
		end else begin
			inp_west8_temp <= 8'b0;
		end
		if(addr_w12 >= 0 && addr_w12 < 4) begin
			case (addr_w12)
				0: inp_west12_temp <= local_buffer_A[0][7:0];
				1: inp_west12_temp <= local_buffer_A[1][7:0];
				2: inp_west12_temp <= local_buffer_A[2][7:0];
				3: inp_west12_temp <= local_buffer_A[3][7:0];
			endcase
		end else begin
			inp_west12_temp <= 8'b0;
		end
	end

    assign inp_north0 = inp_north0_temp;
    assign inp_north1 = inp_north1_temp;
    assign inp_north2 = inp_north2_temp;
    assign inp_north3 = inp_north3_temp;
	
    assign inp_west0 = inp_west0_temp;
    assign inp_west4 = inp_west4_temp;
    assign inp_west8 = inp_west8_temp;
    assign inp_west12 = inp_west12_temp;

	assign done = done_temp;

/*
//----------------------------------------------------------------------------//
// Local buffer AB read write behavior                                          //
//----------------------------------------------------------------------------//
  always @ (negedge clk or negedge rst_n) begin
    if(!rst_n)begin
      for(i=0; i<(DEPTH); i=i+1)
        local_buffer_A[i] <= 128'b0;
		local_buffer_B[i] <= 128'b0;
    end
    else begin
      if(Lb_result_w) begin
            local_buffer_A[lb_AB_index] <= local_buffer_Din_A;
			local_buffer_B[lb_AB_index] <= local_buffer_Din_B;
      end
      else begin
			lb_A_Do <= local_buffer_A[lb_AB_index];
			lb_B_Do <= local_buffer_B[lb_AB_index];
      end
    end
  end
//----------------------------------------------------------------------------//
// Local buffer C read write behavior                                          //
//----------------------------------------------------------------------------//
  always @ (negedge clk or negedge rst_n) begin
    if(!rst_n)begin
      for(j=0; i<(DEPTH); j=j+1)
        local_buffer_C[j] <= 128'b0;
    end
    else begin
      if(Lb_result_w) begin
            local_buffer_C[0] <= {result0, result1, result2, result3};
            local_buffer_C[1] <={result4, result5, result6, result7};
            local_buffer_C[2] <={result8, result9, result10, result11};
            local_buffer_C[3] <={result12, result13, result14, result15};
      end
      else begin
        lb_C_Do <= local_buffer_C[lb_result_index];
      end
    end
  end
*/      
endmodule
		      
