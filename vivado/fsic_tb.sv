`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2023 03:49:21 PM
// Design Name: 
// Module Name: fsic_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define SHOW_HEART_BEAT 1
//`define DEBUG 1 //
import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;
import design_1_axi_vip_1_0_pkg::*;
import design_1_axi_vip_2_0_pkg::*;
import design_1_axi_vip_3_0_pkg::*;

bit resetb_0 = 0, sys_clock = 0, sys_reset = 0, keepChk = 1;
xil_axi_resp_t resp;
bit[11:0] offset;
bit[31:0] data, base_addr = 32'h6000_0000;
xil_axi_ulong addrm = 32'h44A0_0000;
xil_axi_ulong addri = 32'h4500_0000;
xil_axi_ulong addro = 32'h4508_0000;
integer index, fd;
 
event system_reset_event, peripheral_reset_event, caravel_reset_event, fw_worked_event, is_txen_event, ladma_done, error_event;
event fw_mb_st_event, fw_mb_wd_event, userdma_done;

module fsic_tb();

    localparam  ReadCyc = 1'b0;
    localparam  WriteCyc = 1'b1;
    localparam  SOC_UP = 16'h0000;
    localparam  SOC_LA = 16'h1000;
    localparam  PL_AA_MB = 16'h2000;
    localparam  PL_AA = 16'h2100;
    localparam  SOC_IS = 16'h3000;
    localparam  SOC_AS = 16'h4000;
    localparam  SOC_CC = 16'h5000;
    localparam  PL_AS = 16'h6000;
    localparam  PL_IS = 16'h7000;
    localparam  PL_DMA = 16'h8000;
    localparam  PL_UPDMA = 16'h9000;

    design_1_wrapper DUT
    (
        .resetb_0(resetb_0),
        .sys_clock(sys_clock),
        .sys_reset(sys_reset)
    );
    
    //always #4ns sys_clock = ~sys_clock;     //Period 8ns, 125MHz
    always #2ns sys_clock = ~sys_clock;     //Period 4ns, 250Mhz                 
        
    design_1_axi_vip_0_0_mst_t  master_agent;
    design_1_axi_vip_1_0_slv_mem_t  slave_agent;
    design_1_axi_vip_2_0_slv_mem_t  slave_agent2;
    design_1_axi_vip_3_0_slv_mem_t  slave_agent3;

    `ifdef SHOW_HEART_BEAT
      reg [31:0] repeat_cnt;
      reg finish_flag;
      reg timeout_flag;
      initial begin
        $timeformat (-9, 3, " ns", 13); 
        //$dumpfile("top_bench.vcd");
        //$dumpvars(0, top_bench);
        finish_flag = 0; 
        repeat_cnt = 0; 
        timeout_flag = 0;
        do begin
          repeat_cnt = repeat_cnt + 1; 
          repeat (100000) @(posedge sys_clock);
          $display("%t MSG %m, +100000 cycles, finish_flag=%b,  repeat_cnt=%04d", $time, finish_flag, repeat_cnt);
        end  
        while(finish_flag == 0 && repeat_cnt <= 330 );
        timeout_flag = 1;
      end   
    `endif //SHOW_HEART_BEAT

    initial begin
        $dumpfile("log.vcd");
        $dumpvars(0,fsic_tb);
    end

    initial begin    
        fork
            system_reset_t();
            peripheral_reset_t();  
            caravel_reset_t();
            fw_worked_t();
            is_txen_t(); 
            error_t();           
        join_none    
        
        @(system_reset_event);
        @(peripheral_reset_event);
        @(caravel_reset_event);
        @(fw_worked_event);           
    end 
    
    initial begin
        master_agent = new("master vip agent", DUT.design_1_i.axi_vip_0.inst.IF);
        master_agent.start_master();
        
        slave_agent = new("slave vip agent", DUT.design_1_i.axi_vip_1.inst.IF);
        slave_agent.start_slave();

        slave_agent2 = new("slave vip agent", DUT.design_1_i.axi_vip_2.inst.IF);
        slave_agent2.start_slave();

        slave_agent3 = new("slave vip agent", DUT.design_1_i.axi_vip_3.inst.IF);
        slave_agent3.start_slave();

        @(is_txen_event);      
        $display($time, "=> Starting test...");

        $display("TPU test from FPGA side");
        TPU_test_pattern_FPGA(0);
        TPU_test_pattern_FPGA(1);
        TPU_test_pattern_FPGA(2);
        TPU_test_pattern_FPGA(3);

        $display("=============================================================================================");
        $display("=============================================================================================");
        $display("=============================================================================================");

        #500us    
        $display($time, "=> End of the test...");                         
        $finish;
    end

//////////////////////////////////////////////////////////////////
integer PATNUM;

integer in_fd;
integer patcount;
integer nrow;
integer i, j, k;
integer err;
integer temp;


reg [127:0] GOLDEN [65535:0];

reg [7:0] rbuf [3:0];
reg [31:0] goldenbuf [3:0];
reg [7:0] K_golden;
reg [7:0] M_golden;
reg [7:0] N_golden;

reg [7:0]    M, K, N;

parameter TPU_CTRL_OFFSET = 8'h00;

parameter TPU_M_OFFSET = 8'h10;
parameter TPU_K_OFFSET = 8'h14;
parameter TPU_N_OFFSET = 8'h18;

parameter TPU_BUFF_A_ADDR_OFFSET = 8'h20;
parameter TPU_BUFF_A_DIN_OFFSET = 8'h24;
parameter TPU_BUFF_B_ADDR_OFFSET = 8'h30;
parameter TPU_BUFF_B_DIN_OFFSET = 8'h34;
parameter TPU_BUFF_C_ADDR_OFFSET = 8'h40;
parameter TPU_BUFF_C_DOUT_0_OFFSET = 8'h44;
parameter TPU_BUFF_C_DOUT_1_OFFSET = 8'h48;
parameter TPU_BUFF_C_DOUT_2_OFFSET = 8'h4c;
parameter TPU_BUFF_C_DOUT_3_OFFSET = 8'h50;

reg [31:0] read_data;
reg [31:0] gbuff_A [65535:0];
reg [31:0] gbuff_B [65535:0];
reg [127:0] gbuff_C [65535:0];

//assign read_data = data;

task TPU_test_pattern_FPGA;
  input [1:0] patternID;

  $display("fsic_system_initial"); // Done by initial stage

  $display("Enable TPU IP");
  user_project_select(1);

  $display("Program ap_start=0");
  fpga_axilite_write_req(TPU_CTRL_OFFSET,  4'b1111, 32'd0); // in_valid = 1'b0;

  $display("Wait TPU is idle");
  tpu_waitIdle();

  case (patternID)
    2'b00: begin
      in_fd = $fopen("../../../../../pattern/pattern0/input.txt", "r");
    end
    2'b01: begin
      in_fd = $fopen("../../../../../pattern/pattern1/input.txt", "r");
    end
    2'b10: begin
      in_fd = $fopen("../../../../../pattern/pattern2/input.txt", "r");
    end
    2'b11: begin
      in_fd = $fopen("../../../../../pattern/pattern3/input.txt", "r");
    end
  endcase

// PATNUM
  temp = $fscanf(in_fd, "%d", PATNUM);

  for(patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin

      // read input
      read_and_write_cfg_to_userprj_fpga;
      repeat(100) @ (posedge sys_clock);    //TODO fpga wait for write to soc

      // start to feed data
      repeat(3) @(negedge sys_clock);
      $display("patcount[%d] ap_start = 1", patcount);
      @(posedge sys_clock) fpga_axilite_write_req(TPU_CTRL_OFFSET, 4'b0001, 32'd1); // in_valid = 1'b1;

      @(negedge sys_clock);
      $display("patcount[%d] ap_start = 0", patcount);
      @(posedge sys_clock) fpga_axilite_write_req(TPU_CTRL_OFFSET, 4'b0001, 32'd0); // in_valid = 1'b0;


      wait_finished;

      golden_check;

      repeat(5) @(negedge sys_clock);
  end

  YOU_PASS_task;

	endtask

///////////////////////////////////////////////////////////////////////////////

// Wait TPU is idle
task tpu_waitIdle;
  begin
    fpga_axilite_read_req(TPU_CTRL_OFFSET, read_data);
    while (read_data[2] != 1'b1) begin
      @(posedge sys_clock);
      fpga_axilite_read_req(TPU_CTRL_OFFSET, read_data);
    end
  end
endtask

task read_and_write_cfg_to_userprj_soc;

  // read_KMN
  temp = $fscanf(in_fd, "%h", K_golden);
  temp = $fscanf(in_fd, "%h", M_golden);
  temp = $fscanf(in_fd, "%h", N_golden);
  $display("M: %d, K: %d N: %d", M_golden, K_golden, N_golden);

  fpga_axilite_write_req(TPU_M_OFFSET, 4'b1111, M_golden);
  fpga_axilite_write_req(TPU_K_OFFSET, 4'b1111, K_golden);
  fpga_axilite_write_req(TPU_N_OFFSET, 4'b1111, N_golden);

  // read_A_Matrix
  nrow = (M_golden[1:0] !== 2'b00) ?  K_golden * ((M_golden>>2) + 1) : K_golden * (M_golden>>2);

  for(i=0;i<nrow;i=i+1) begin
    temp = $fscanf(in_fd, "%h %h %h %h", rbuf[3], rbuf[2], rbuf[1], rbuf[0]);
    gbuff_A[i] = {rbuf[3], rbuf[2], rbuf[1], rbuf[0]};
    $display("A[%d] = %h", i, gbuff_A[i]);

    fpga_axilite_write_req(TPU_BUFF_A_ADDR_OFFSET, 4'b1111, i);
    fpga_axilite_write_req(TPU_BUFF_A_DIN_OFFSET, 4'b1111, gbuff_A[i]);
  end

  // read_B_Matrix
  nrow = (N_golden[1:0] !== 2'b00) ? K_golden * ((N_golden >> 2) + 1) : K_golden * (N_golden >> 2);

  for(i=0;i<nrow;i=i+1) begin
      temp = $fscanf(in_fd, "%h %h %h %h", rbuf[3], rbuf[2], rbuf[1], rbuf[0]);
      gbuff_B[i] = {rbuf[3], rbuf[2], rbuf[1], rbuf[0]};
      $display("B[%d] = %h", i, gbuff_B[i]);

      fpga_axilite_write_req(TPU_BUFF_B_ADDR_OFFSET, 4'b1111, i);
      fpga_axilite_write_req(TPU_BUFF_B_DIN_OFFSET, 4'b1111, gbuff_B[i]);
  end

  //read_golden
  nrow = (N_golden[1:0] !== 2'b00) ? M_golden * ((N_golden>>2) + 1) : M_golden * (N_golden>>2);

  for(i=0;i<nrow;i=i+1) begin
      temp = $fscanf(in_fd, "%h %h %h %h", goldenbuf[3], goldenbuf[2], goldenbuf[1], goldenbuf[0]);
      GOLDEN[i] = {goldenbuf[3], goldenbuf[2], goldenbuf[1], goldenbuf[0]};
      $display("GOLDEN[%d] = %h %h %h %h", i, GOLDEN[i][127:96],  GOLDEN[i][95:64],  GOLDEN[i][63:32],  GOLDEN[i][31:0]);
  end

endtask

task read_and_write_cfg_to_userprj_fpga;

  // read_KMN
  temp = $fscanf(in_fd, "%h", K_golden);
  temp = $fscanf(in_fd, "%h", M_golden);
  temp = $fscanf(in_fd, "%h", N_golden);
  $display("M: %d, K: %d N: %d", M_golden, K_golden, N_golden);

  fpga_axilite_write_req(TPU_M_OFFSET,  4'b1111, M_golden);
  fpga_axilite_write_req(TPU_K_OFFSET,  4'b1111, K_golden);
  fpga_axilite_write_req(TPU_N_OFFSET,  4'b1111, N_golden);

  // read_A_Matrix
  nrow = (M_golden[1:0] !== 2'b00) ?  K_golden * ((M_golden>>2) + 1) : K_golden * (M_golden>>2);

  for(i=0;i<nrow;i=i+1) begin
      temp = $fscanf(in_fd, "%h %h %h %h", rbuf[3], rbuf[2], rbuf[1], rbuf[0]);
      gbuff_A[i] = {rbuf[3], rbuf[2], rbuf[1], rbuf[0]};
      $display("A[%d] = %h", i, gbuff_A[i]);

      fpga_axilite_write_req(TPU_BUFF_A_ADDR_OFFSET,  4'b1111, i);
      fpga_axilite_write_req(TPU_BUFF_A_DIN_OFFSET,  4'b1111, gbuff_A[i]);
  end

  // read_B_Matrix
  nrow = (N_golden[1:0] !== 2'b00) ? K_golden * ((N_golden >> 2) + 1) : K_golden * (N_golden >> 2);

  for(i=0;i<nrow;i=i+1) begin
      temp = $fscanf(in_fd, "%h %h %h %h", rbuf[3], rbuf[2], rbuf[1], rbuf[0]);
      gbuff_B[i] = {rbuf[3], rbuf[2], rbuf[1], rbuf[0]};
      $display("B[%d] = %h", i, gbuff_B[i]);

      fpga_axilite_write_req(TPU_BUFF_B_ADDR_OFFSET,  4'b1111, i);
      fpga_axilite_write_req(TPU_BUFF_B_DIN_OFFSET,  4'b1111, gbuff_B[i]);
  end

  //read_golden
  nrow = (N_golden[1:0] !== 2'b00) ? M_golden * ((N_golden>>2) + 1) : M_golden * (N_golden>>2);

  for(i=0;i<nrow;i=i+1) begin
      temp = $fscanf(in_fd, "%h %h %h %h", goldenbuf[3], goldenbuf[2], goldenbuf[1], goldenbuf[0]);
      GOLDEN[i] = {goldenbuf[3], goldenbuf[2], goldenbuf[1], goldenbuf[0]};
      $display("GOLDEN[%d] = %h %h %h %h", i, GOLDEN[i][127:96],  GOLDEN[i][95:64],  GOLDEN[i][63:32],  GOLDEN[i][31:0]);
  end

endtask

task wait_finished; begin

    fpga_axilite_read_req(TPU_CTRL_OFFSET, read_data);
    while (read_data[1] != 1'b1) begin // ap_done == 1'b1

        fpga_axilite_read_req(TPU_CTRL_OFFSET, read_data);
    end

end endtask


task golden_check; begin

    err = 0;

    // Read C Buffer
    for(i=0;i<nrow;i=i+1) begin
      fpga_axilite_write_req(TPU_BUFF_C_ADDR_OFFSET, 4'b1111, i);
      repeat (100) @(posedge sys_clock);
      fpga_axilite_read_req(TPU_BUFF_C_DOUT_0_OFFSET, read_data);
			gbuff_C[i][31:0] = read_data;
      fpga_axilite_read_req(TPU_BUFF_C_DOUT_1_OFFSET, read_data);
			gbuff_C[i][63:32] = read_data;
      fpga_axilite_read_req(TPU_BUFF_C_DOUT_2_OFFSET, read_data);
			gbuff_C[i][95:64] = read_data;
      fpga_axilite_read_req(TPU_BUFF_C_DOUT_3_OFFSET, read_data);
			gbuff_C[i][127:96] = read_data;

      $display("C[%d] = %h", i, gbuff_C[i]);
    end

    nrow = (N_golden[1:0] !== 2'b00) ? M_golden * ((N_golden>>2) + 1) : M_golden * (N_golden>>2);
    for(i = 0; i < nrow; i=i+1) begin
        if(GOLDEN[i][127:96] !== gbuff_C[i][127:96]) begin
            $display("gbuff[%d][127:96] = %8h, expect = %8h", i, gbuff_C[i][127:96], GOLDEN[i][127:96]);
            err = err + 1;
        end

        if(GOLDEN[i][95:64] !== gbuff_C[i][95:64]) begin
            $display("gbuff[%d][95:64] = %8h, expect = %8h", i, gbuff_C[i][95:64], GOLDEN[i][95:64]);
            err = err + 1;
        end

        if(GOLDEN[i][63:32] !== gbuff_C[i][63:32]) begin
            $display("gbuff[%d][63:32] = %8h, expect = %8h", i, gbuff_C[i][63:32], GOLDEN[i][63:32]);
            err = err + 1;
        end

        if(GOLDEN[i][31:0] !== gbuff_C[i][31:0]) begin
            $display("gbuff[%d][31:0] = %8h, expect = %8h", i, gbuff_C[i][31:0], GOLDEN[i][31:0]);
            err = err + 1;
        end
    end

    if(err != 0) begin
        wrong_ans;
    end
end endtask


task wrong_ans; begin
    $display("-------------------------------------This is wrong answer-------------------------------------");
    $finish;
end endtask

task YOU_PASS_task; begin
    $display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Yes, you pass answoer   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
end endtask
// ***************************************************************

task user_project_select;
    input [4:0] up_index;
    begin
        $display($time, "=> Fpga2Soc_Write: SOC_CC");
        offset = 0;
        data = up_index;
        axil_cycles_gen(WriteCyc, SOC_CC, offset, data, 1);

        `ifdef DEBUG
            axil_cycles_gen(ReadCyc, SOC_CC, offset, data, 1);
            if(data == up_index) begin
                $display($time, "=> Fpga2Soc_Write SOC_CC offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write SOC_CC offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end
            $display($time, "=> user_project %d is enable", up_index);
        `endif
    end
endtask

task fpga_axilite_write_req;
    input [27:0] address;
    input [3:0] BE;
    input [31:0] in_data;

    offset = {BE,address};

    $display($time, "=> WriteCyc, offset %h = %h, PASS", offset, in_data);
    axil_cycles_gen(WriteCyc, SOC_UP, offset, in_data, 1);

    `ifdef DEBUG
        $display($time, "=> ReadCyc");
        axil_cycles_gen(ReadCyc, SOC_UP, offset, data, 1);
        $display($time, "=> ReadCyc done");
        if(data == in_data) begin
            $display($time, "=> Fpga2Soc_Write offset %h = %h, PASS", offset, data);
        end else begin
            $display($time, "=> Fpga2Soc_Write offset %h = %h, FAIL", offset, data);
           // ->> error_event;
        end
    `endif
endtask

task fpga_axilite_read_req;
    input [11:0] offset;
    output [31:0] data;

    axil_cycles_gen(ReadCyc, SOC_UP, offset, data, 1);
    
    `ifdef DEBUG
            $display($time, "=> Fpga2Soc_Read SOC_UP offset %h = %h, PASS", offset, data);
    `endif
endtask

//////////////////////////////////////////////////////////////////
    task system_reset_t;
        begin
            sys_reset = 0;
            #200ns
            sys_reset = 1;
            $display($time, "=> sys_rest = %01b", sys_reset);            
            ->> system_reset_event;
        end
    endtask
    
    task peripheral_reset_t;
        begin
            wait(DUT.design_1_i.rst_clk_wiz_0_5M_peripheral_aresetn == 1'b1);
            $display($time, "=> rst_clk_wiz_0_5M_peripheral_aresetn = %01b", DUT.design_1_i.rst_clk_wiz_0_5M_peripheral_aresetn);            
            ->> peripheral_reset_event;
        end
    endtask

    task caravel_reset_t;
        begin
            @(peripheral_reset_event);                 
            #200us
            resetb_0 = 1;
            $display($time, "=> CaravelSoC resetb_0 = %01b", resetb_0);    
            ->> caravel_reset_event;        
        end
    endtask          

    task fw_worked_t;
        begin
            wait(DUT.design_1_i.caravel_0_mprj_o[37] == 1'b1);
            $display($time, "=> FW working, caravel_0_mprj_o[37] = %0b", DUT.design_1_i.caravel_0_mprj_o[37]);
            ->> fw_worked_event;        
        end
    endtask

    task error_t;
        begin
            @(error_event);
            $display($time, "=> Testbench Failed, End of the test.");
            #100us
            $finish;
        end
    endtask    

    task is_txen_t;
        begin
            @(fw_worked_event);
            $display($time, "=> PL_IS enabling..."); 
            data = 1;   
            axil_cycles_gen(WriteCyc, PL_IS, 0, data, 1);
            #10us
            data = 3;
            axil_cycles_gen(WriteCyc, PL_IS, 0, data, 1);
            #10us            
            axil_cycles_gen(ReadCyc, PL_IS, 0, data, 1);
            $display($time, "=> PL_IS enables: = %h", data);
            if(data == 32'h0000_0003)                             
                ->> is_txen_event;
            else 
                ->> error_event;                        
        end
    endtask    
    
    task Fpga2Soc_CfgRead;
        begin
            $display($time, "=> Starting Fpga2Soc_CfgRead() test...");
            $display($time, "=> =======================================================================");

            $display($time, "=> Fpga2Soc_Read testing: SOC_CC"); 
            offset = 0;            
            axil_cycles_gen(ReadCyc, SOC_CC, offset, data, 1);
            #10us            
            if(data == 32'h0000_001F) begin
                $display($time, "=> Fpga2Soc_Read SOC_CC offset %h = %h, PASS", offset, data);            
            end else begin
                $display($time, "=> Fpga2Soc_Read SOC_CC offset %h = %h, FAIL", offset, data);
                ->> error_event;            
            end

            $display($time, "=> Fpga2Soc_Read testing: SOC_AS");
            offset = 0;                         
            axil_cycles_gen(ReadCyc, SOC_AS, offset, data, 1);
            #10us            
            if(data == 32'h0000_0006) begin
                $display($time, "=> Fpga2Soc_Read SOC_AS = %h, PASS", data);            
            end else begin
                $display($time, "=> Fpga2Soc_Read SOC_AS = %h, FAIL", data);            
                ->> error_event;            
            end

            $display($time, "=> Fpga2Soc_Read testing: SOC_IS");
            offset = 0;                         
            axil_cycles_gen(ReadCyc, SOC_IS, offset, data, 1);
            #10us            
            if(data == 32'h0000_0001) begin
                $display($time, "=> Fpga2Soc_Read SOC_IS = %h, PASS", data);            
            end else begin
                $display($time, "=> Fpga2Soc_Read SOC_IS = %h, FAIL", data);            
                ->> error_event;            
            end     
            
            $display($time, "=> Fpga2Soc_Read testing: SOC_LA");
            offset = 0;                         
            axil_cycles_gen(ReadCyc, SOC_LA, offset, data, 1);
            #10us            
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Read SOC_LA = %h, PASS", data);            
            end else begin
                $display($time, "=> Fpga2Soc_Read SOC_LA = %h, FAIL", data);            
                ->> error_event;            
            end

            $display($time, "=> End Fpga2Soc_CfgRead() test...");
            $display($time, "=> =======================================================================");

        end
    endtask    
    
    task Fpga2Soc_CfgWrite;
        begin
            $display($time, "=> Starting Fpga2Soc_CfgWrite() test...");
            $display($time, "=> =======================================================================");

            $display($time, "=> Fpga2Soc_Write testing: SOC_CC"); 
            offset = 0;
            
            for (index = 0; index < 8'h5 ; index=index+1) begin
                data = index;
                axil_cycles_gen(WriteCyc, SOC_CC, offset, data, 1);
                //#20us            
                axil_cycles_gen(ReadCyc, SOC_CC, offset, data, 1);
                //#20us                
                if(data == index) begin
                    $display($time, "=> #%h, Fpga2Soc_Write SOC_CC offset %h = %h, PASS", index, offset, data);            
                end else begin
                    $display($time, "=> #%h, Fpga2Soc_Write SOC_CC offset %h = %h, FAIL", index, offset, data);            
                    ->> error_event;
                end
                if (index==0) begin
                    `ifdef USE_EDGEDETECT_IP
                        $display($time, "=> Fpga2Soc_Read testing: SOC_UP");
                        offset = 0;
                        axil_cycles_gen(ReadCyc, SOC_UP, offset, data, 1);
                        #10us
                        if(data == 32'h0000_0000) begin
                            $display($time, "=> Fpga2Soc_Read SOC_UP offset %h = %h, PASS", offset, data);
                        end else begin
                            $display($time, "=> Fpga2Soc_Read SOC_UP offset %h = %h, FAIL", offset, data);
                            ->> error_event;
                        end

                        $display($time, "=> Fpga2Soc_Read testing: SOC_UP");
                        offset = 4;
                        axil_cycles_gen(ReadCyc, SOC_UP, offset, data, 1);
                        #10us
                        if(data == 32'h0000_0280) begin
                            $display($time, "=> Fpga2Soc_Read SOC_UP offset %h = %h, PASS", offset, data);
                        end else begin
                            $display($time, "=> Fpga2Soc_Read SOC_UP offset %h = %h, FAIL", offset, data);
                            ->> error_event;
                        end

                        $display($time, "=> Fpga2Soc_Read testing: SOC_UP");
                        offset = 8;
                        axil_cycles_gen(ReadCyc, SOC_UP, offset, data, 1);
                        #10us
                        if(data == 32'h0000_01E0) begin
                            $display($time, "=> Fpga2Soc_Read SOC_UP offset %h = %h, PASS", offset, data);
                        end else begin
                            $display($time, "=> Fpga2Soc_Read SOC_UP offset %h = %h, FAIL", offset, data);
                            ->> error_event;
                        end

                        $display($time, "=> Fpga2Soc_Read testing: SOC_UP");
                        offset = 12;
                        axil_cycles_gen(ReadCyc, SOC_UP, offset, data, 1);
                        #10us
                        if(data == 32'h0000_0001) begin
                            $display($time, "=> Fpga2Soc_Read SOC_UP offset %h = %h, PASS", offset, data);
                        end else begin
                            $display($time, "=> Fpga2Soc_Read SOC_UP offset %h = %h, FAIL", offset, data);
                            ->> error_event;
                        end
                    `else   //USE_EDGEDETECT_IP
                        $display($time, "=> Fpga2Soc_Read testing: SOC_UP");
                        offset = 0;
                        axil_cycles_gen(ReadCyc, SOC_UP, offset, data, 1);
                        #10us
                        if(data == 32'haa55_aa55) begin
                            $display($time, "=> Fpga2Soc_Read SOC_UP offset %h = %h, PASS", offset, data);
                        end else begin
                            $display($time, "=> Fpga2Soc_Read SOC_UP offset %h = %h, FAIL", offset, data);
                            ->> error_event;
                        end

                    `endif
                    offset = 0;
                end
            end

            $display($time, "=> End Fpga2Soc_CfgWrite() test...");
            $display($time, "=> =======================================================================");

        end
    endtask

    task SocLa2DmaPath;
        begin
            $display($time, "=> Starting SocLa2DmaPath() test...");
            $display($time, "=> =======================================================================");
            //Setup ladma
            $display($time, "=> FpgaLocal_Write: PL_DMA, exit clear...");
            offset = 32'h0000_0020;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, PL_DMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_DMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_DMA, set buffer length...");
            offset = 32'h0000_0028;
            data = 32'h0000_0400;
            axil_cycles_gen(WriteCyc, PL_DMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_DMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_0400) begin
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_DMA, set trigger condition...");
            offset = 32'h0000_0030;
            data = 32'h0000_0200;
            axil_cycles_gen(WriteCyc, PL_DMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_DMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_0200) begin
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_DMA, set buffer low...");
            offset = 32'h0000_0038;
            data = 32'h44A0_0000;
            axil_cycles_gen(WriteCyc, PL_DMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_DMA, offset, data, 1);
            //#20us
            if(data == 32'h44A0_0000) begin
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_DMA, set buffer high...");
            offset = 32'h0000_003C;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, PL_DMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_DMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_DMA, set ap_start...");
            offset = 32'h0000_0000;
            data = 32'h0000_0001;
            axil_cycles_gen(WriteCyc, PL_DMA, offset, data, 1);

            $display($time, "=> Fpga2Soc_Write: SOC_LA");
            offset = 0;
            data = 32'h00FF_FFFF;
            axil_cycles_gen(WriteCyc, SOC_LA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, SOC_LA, offset, data, 1);
            //#20us
            if(data == 32'h00FF_FFFF) begin
                $display($time, "=> Fpga2Soc_Write SOC_LA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write SOC_LA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            //Select fake user project for la_data_o generation
            $display($time, "=> Fpga2Soc_Write: SOC_CC");
            offset = 0;
            data = 32'h0000_0003;
            axil_cycles_gen(WriteCyc, SOC_CC, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, SOC_CC, offset, data, 1);
            //#20us
            if(data == 32'h0000_0003) begin
                $display($time, "=> Fpga2Soc_Write SOC_CC offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write SOC_CC offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            fork
                CheckLaDMADone();
            join_none

            @(ladma_done);

            offset = 0;
            axil_cycles_gen(ReadCyc, SOC_LA, offset, data, 1);
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Write SOC_LA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write SOC_LA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            offset = 0;
            axil_cycles_gen(ReadCyc, SOC_CC, offset, data, 1);
            if(data == 32'h0000_0001) begin
                $display($time, "=> Fpga2Soc_Write SOC_CC offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write SOC_CC offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> End SocLa2DmaPath() test...");
            $display($time, "=> =======================================================================");
        end
    endtask

  task CheckLaDMADone;
        begin
            $display($time, "=> Starting CheckLaDMADone()...");
            $display($time, "=> =======================================================================");
            $display($time, "=> FpgaLocal_Read: PL_DMA");

            keepChk = 1;
            offset = 32'h0000_0010;
            $display($time, "=> Wating buffer transfer done...");
            while (keepChk) begin
                #10us
                axil_cycles_gen(ReadCyc, PL_DMA, offset, data, 0);
                if(data == 32'h0000_0001) begin
                    $display($time, "=> Buffer transfer done. offset %h = %h, PASS", offset, data);
                    keepChk = 0;

                    //disable LA
                    $display($time, "=> Fpga2Soc_Write: SOC_LA");
                    offset = 0;
                    data = 32'h0000_0000;
                    axil_cycles_gen(WriteCyc, SOC_LA, offset, data, 1);

                    //Select a empty user project
                    $display($time, "=> Fpga2Soc_Write: SOC_CC");
                    offset = 0;
                    data = 32'h0000_0001;
                    axil_cycles_gen(WriteCyc, SOC_CC, offset, data, 1);

                    //log ladma_capatured
                    fd = $fopen ("../../../../../ladma_captured.log", "w");
                    for (index = 0; index < 16'h1000; index +=4) begin
                         $fdisplay(fd, "%08h", slave_agent.mem_model.backdoor_memory_read_4byte(addrm+index));
                    end
                    $fclose(fd);
                end
            end

            //ladma - workaround
            //clear transfer done
            $display($time, "=> FpgaLocal_Write: PL_DMA");
            offset = 32'h0000_0020;
            data = 32'h0000_0001;
            axil_cycles_gen(WriteCyc, PL_DMA, offset, data, 1);
            //start
            $display($time, "=> FpgaLocal_Write: PL_DMA");
            offset = 32'h0000_0000;
            data = 32'h0000_0001;
            axil_cycles_gen(WriteCyc, PL_DMA, offset, data, 1);
            //Wait buffer transfer don to be cleared
            offset = 32'h0000_0010;
            keepChk = 1'b1;
            $display($time, "=> Wating buffer transfer done to be clear...");
            while (keepChk) begin
                #10us
                axil_cycles_gen(ReadCyc, PL_DMA, offset, data, 0);
                if(data == 32'h0000_0000) begin
                    $display($time, "=> Buffer transfer done cleared. offset %h = %h, PASS", offset, data);
                    keepChk = 0;
                end
            end
            //exit clear
            $display($time, "=> FpgaLocal_Write: PL_DMA");
            offset = 32'h0000_0020;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, PL_DMA, offset, data, 1);
            //start
            $display($time, "=> FpgaLocal_Write: PL_DMA");
            offset = 32'h0000_0000;
            data = 32'h0000_0001;
            axil_cycles_gen(WriteCyc, PL_DMA, offset, data, 1);
            //stop
            $display($time, "=> FpgaLocal_Write: PL_DMA");
            offset = 32'h0000_0000;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, PL_DMA, offset, data, 1);
            axil_cycles_gen(ReadCyc, PL_DMA, offset, data, 1);
            if(data == 32'h0000_000b) begin     //32'h0000_000b for all tasks execution temporary
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_DMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end
            //ladma - workaround

            ->> ladma_done;
            $display($time, "=> End CheckLaDMADone()...");
            $display($time, "=> =======================================================================");

        end
    endtask

    task FpgaLocal_CfgRead;
        begin
            $display($time, "=> Starting FpgaLocal_CfgRead() test...");
            $display($time, "=> =======================================================================");

            $display($time, "=> FpgaLocal_CfgRead testing: PL_AS");
            offset = 0;
            axil_cycles_gen(ReadCyc, PL_AS, offset, data, 1);
            #10us
            if(data == 32'h0000_0006) begin
                $display($time, "=> FpgaLocal_CfgRead PL_AS offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> FpgaLocal_CfgRead PL_AS offset %h = %h, PASS", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_CfgRead testing: PL_IS");
            offset = 0;
            axil_cycles_gen(ReadCyc, PL_IS, offset, data, 1);
            #10us
            if(data == 32'h0000_0003) begin
                $display($time, "=> FpgaLocal_CfgRead PL_IS = %h, PASS", data);
            end else begin
                $display($time, "=> FpgaLocal_CfgRead PL_IS = %h, FAIL", data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_CfgRead testing: PL_DMA");
            offset = 0;
            axil_cycles_gen(ReadCyc, PL_DMA, offset, data, 1);
            #10us
            if(data == 32'h0000_0004) begin
                $display($time, "=> FpgaLocal_CfgRead PL_DMA = %h, PASS", data);
            end else begin
                $display($time, "=> FpgaLocal_CfgRead PL_DMA = %h, FAIL", data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_CfgRead testing: PL_AA");
            offset = 0;
            axil_cycles_gen(ReadCyc, PL_AA, offset, data, 1);
            #10us
            if(data == 32'h0000_0000) begin
                $display($time, "=> FpgaLocal_CfgRead PL_AA = %h, PASS", data);
            end else begin
                $display($time, "=> FpgaLocal_CfgRead PL_AA = %h, FAIL", data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_CfgRead testing: PL_UPDMA");
            offset = 0;
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            #10us
            if(data == 32'h0000_0004) begin
                $display($time, "=> FpgaLocal_CfgRead PL_UPDMA = %h, PASS", data);
            end else begin
                $display($time, "=> FpgaLocal_CfgRead PL_UPDMA = %h, FAIL", data);
                ->> error_event;
            end

            $display($time, "=> End FpgaLocal_CfgRead() test...");
            $display($time, "=> =======================================================================");
        end
    endtask

    task fw_mb_st_t;
        begin
            wait(DUT.design_1_i.caravel_0_mprj_o[37] == 1'b0);
            $display($time, "=> FW starts MB writing, caravel_0_mprj_o[37] = %0b", DUT.design_1_i.caravel_0_mprj_o[37]);
            ->> fw_mb_st_event;
        end
    endtask

    task fw_mb_wd_t;
        begin
            wait(DUT.design_1_i.caravel_0_mprj_o[37] == 1'b1);
            $display($time, "=> FW finishs MB writing, caravel_0_mprj_o[37] = %0b", DUT.design_1_i.caravel_0_mprj_o[37]);
            ->> fw_mb_wd_event;
        end
    endtask

    task SocLocal_MbWrite;
        begin
            $display($time, "=> Starting SocLocal_MbWrite() test...");
            $display($time, "=> =======================================================================");

            $display($time, "=> FpgaLocal_Write : PL_AA");
            offset = 0;
            data = 32'h0000_0001;
            axil_cycles_gen(WriteCyc, PL_AA, offset, data, 1);
            axil_cycles_gen(ReadCyc, PL_AA, offset, data, 1);
            //#20us
            if(data == 32'h0000_00001) begin
                $display($time, "=> FpgaLocal_Write PL_AA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> FpgaLocal_Write PL_AA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> Fpga2Soc_Write : SOC_CC");
            offset = 0;
            data = 32'h0000_0005;
            axil_cycles_gen(WriteCyc, SOC_CC, offset, data, 1);

            fork
                fw_mb_st_t();
            join_none

            @(fw_mb_st_event);

            fork
                fw_mb_wd_t();
            join_none

            @(fw_mb_wd_event);

            $display($time, "=> Fpga2Soc_Read: SOC_CC");
            offset = 0;
            axil_cycles_gen(ReadCyc, SOC_CC, offset, data, 1);
            if(data == 32'h0000_0004) begin
                $display($time, "=> Fpga2Soc_Read SOC_CC = %h, PASS", data);
            end else begin
                $display($time, "=> Fpga2Soc_Read SOC_CC = %h, FAIL", data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Read: PL_AA_MB");
            offset = 0;
            axil_cycles_gen(ReadCyc, PL_AA_MB, offset, data, 1);
            if(data == 32'h5a5a_5a5a) begin
                $display($time, "=> FpgaLocal_Read PL_AA_MB = %h, PASS", data);
            end else begin
                $display($time, "=> FpgaLocal_Read PL_AA_MB = %h, FAIL", data);
                ->> error_event;
            end

            $display($time, "=> aa_mb_irq status = %0b", DUT.design_1_i.ps_axil_0.aa_mb_irq);
            $display($time, "=> FpgaLocal_Read: PL_AA");
            offset = 4;
            axil_cycles_gen(ReadCyc, PL_AA, offset, data, 1);
            if(data == 32'h0000_0001) begin
                $display($time, "=> FpgaLocal_Read PL_AA = %h, PASS", data);
            end else begin
                $display($time, "=> FpgaLocal_Read PL_AA = %h, FAIL", data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write : PL_AA");
            offset = 4;
            data = 32'h0000_0001;
            axil_cycles_gen(WriteCyc, PL_AA, offset, data, 1);
            axil_cycles_gen(ReadCyc, PL_AA, offset, data, 1);
            //#20us
            if(data == 32'h0000_00000) begin
                $display($time, "=> FpgaLocal_Write PL_AA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> FpgaLocal_Write PL_AA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> End SocLocal_MbWrite() test...");
            $display($time, "=> =======================================================================");
        end
    endtask

    task FpgaLocal_MbWrite;
        begin
            $display($time, "=> Starting FpgaLocal_MbWrite() test...");
            $display($time, "=> =======================================================================");

            $display($time, "=> Fpga2Soc_Write: SOC_CC");
            offset = 0;
            data = 32'h0000_0006;
            axil_cycles_gen(WriteCyc, SOC_CC, offset, data, 1);
            $display($time, "=> Wating FW complete the request enabling aa irq...");
            keepChk = 1;
            offset = 32'h0000_0000;
            while (keepChk) begin
                #10us
                axil_cycles_gen(ReadCyc, SOC_CC, offset, data, 0);
                if(data == 32'h0000_0004) begin
                    $display($time, "=> FW complete the request. offset %h = %h, PASS", offset, data);
                    keepChk = 0;
                end
            end
            if (DUT.design_1_i.caravel_0_mprj_o[37] == 0) begin
                $display($time, "=> caravel_0_mprj_o[37] = %0b, PASS", DUT.design_1_i.caravel_0_mprj_o[37]);
            end else begin
                $display($time, "=> caravel_0_mprj_o[37] = %0b, FAIL", DUT.design_1_i.caravel_0_mprj_o[37]);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write : PL_AA_MB");
            offset = 0;
            data = 32'h5555_aaaa;
            axil_cycles_gen(WriteCyc, PL_AA_MB, offset, data, 1);
            data = 32'h0000_0000;
            axil_cycles_gen(ReadCyc, PL_AA_MB, offset, data, 1);
            if (data == 32'h5555_aaaa) begin
                $display($time, "=> FpgaLocal_Read PL_AA_MB = %h, PASS", data);
            end else begin
                $display($time, "=> FpgaLocal_Read PL_AA_MB = %h, FAIL", data);
                ->> error_event;
            end

            $display($time, "=> Fpga2Soc_Write: SOC_CC");
            offset = 0;
            data = 32'h0000_0007;
            axil_cycles_gen(WriteCyc, SOC_CC, offset, data, 1);
            $display($time, "=> Wating FW complete the request SocLocal MB data checking ...");
            keepChk = 1;
            offset = 32'h0000_0000;
            while (keepChk) begin
                #10us
                axil_cycles_gen(ReadCyc, SOC_CC, offset, data, 0);
                if(data == 32'h0000_0004) begin
                    $display($time, "=> FW complete the request. offset %h = %h, PASS", offset, data);
                    keepChk = 0;
                end
            end
            if (DUT.design_1_i.caravel_0_mprj_o[37] == 0) begin
                $display($time, "=> caravel_0_mprj_o[37] = %0b, PASS", DUT.design_1_i.caravel_0_mprj_o[37]);
            end else begin
                $display($time, "=> caravel_0_mprj_o[37] = %0b, FAIL", DUT.design_1_i.caravel_0_mprj_o[37]);
                ->> error_event;
            end

            $display($time, "=> Fpga2Soc_Write: SOC_CC");
            offset = 0;
            data = 32'h0000_0008;
            axil_cycles_gen(WriteCyc, SOC_CC, offset, data, 1);
            $display($time, "=> Wating FW complete the request clear SocLocal aa irq...");
            keepChk = 1;
            offset = 32'h0000_0000;
            while (keepChk) begin
                #10us
                axil_cycles_gen(ReadCyc, SOC_CC, offset, data, 0);
                if(data == 32'h0000_0004) begin
                    $display($time, "=> FW complete the request. offset %h = %h, PASS", offset, data);
                    keepChk = 0;
                end
            end
            if (DUT.design_1_i.caravel_0_mprj_o[37] == 0) begin
                $display($time, "=> caravel_0_mprj_o[37] = %0b, PASS", DUT.design_1_i.caravel_0_mprj_o[37]);
            end else begin
                $display($time, "=> caravel_0_mprj_o[37] = %0b, FAIL", DUT.design_1_i.caravel_0_mprj_o[37]);
                ->> error_event;
            end

            $display($time, "=> End FpgaLocal_MbWrite() test...");
            $display($time, "=> =======================================================================");
        end
    endtask

    reg [7:0] updma_img [0:230399];
    reg [31:0] updma_data;
    task SocUp2DmaPath;
        begin
            $display($time, "=> Starting SocUp2DmaPath() test...");
            $display($time, "=> =======================================================================");

            $readmemh("../../../../../in_img.hex", updma_img);

            fd = $fopen ("../../../../../updma_input.log", "w");
            for (index = 0; index < 230400; index +=4) begin
                updma_data |= updma_img[index];
                updma_data |= updma_img[index+1] << 8;
                updma_data |= updma_img[index+2] << 16;
                updma_data |= updma_img[index+3] << 24;
                slave_agent3.mem_model.backdoor_memory_write_4byte(addri+index,updma_data,4'b1111);
                updma_data = 0;
                $fdisplay(fd, "%08h", slave_agent3.mem_model.backdoor_memory_read_4byte(addri+index));
            end
            $fclose(fd);

            $readmemh("../../../../../out_img.hex", updma_img);

            fd = $fopen ("../../../../../updma_output_gold.log", "w");
            for (index = 0; index < 230400; index +=4) begin
                updma_data |= updma_img[index];
                updma_data |= updma_img[index+1] << 8;
                updma_data |= updma_img[index+2] << 16;
                updma_data |= updma_img[index+3] << 24;
                slave_agent2.mem_model.backdoor_memory_write_4byte(addro+index,updma_data,4'b1111);
                updma_data = 0;
                $fdisplay(fd, "%08h", slave_agent2.mem_model.backdoor_memory_read_4byte(addro+index));
            end
            $fclose(fd);

            //Setup userdma
            $display($time, "=> FpgaLocal_Write: PL_UPDMA, s2m exit clear...");
            offset = 32'h0000_0020;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_UPDMA, s2m disable to clear...");
            offset = 32'h0000_0030;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_UPDMA, m2s exit clear...");
            offset = 32'h0000_0078;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_UPDMA, m2s disable to clear...");
            offset = 32'h0000_0088;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_UPDMA, s2m set buffer length...");
            offset = 32'h0000_0028;
            data = 32'h0000_E100;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            //#20us230400
            if(data == 32'h0000_E100) begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_UPDMA, s2m set buffer low...");
            offset = 32'h0000_0038;
            data = 32'h4508_0000;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            //#20us
            if(data == 32'h4508_0000) begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_UPDMA, s2m set buffer high...");
            offset = 32'h0000_003C;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_UPDMA, set image width...");
            offset = 32'h0000_0054;
            data = 32'h0000_00A0;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_00A0) begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_UPDMA, m2s set buffer low...");
            offset = 32'h0000_005C;
            data = 32'h4500_0000;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            //#20us
            if(data == 32'h4500_0000) begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_UPDMA, m2s set buffer high...");
            offset = 32'h0000_0060;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_UPDMA, m2s set buffer length...");
            offset = 32'h0000_0080;
            data = 32'h0000_E100;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 1);
            //#20us
            if(data == 32'h0000_E100) begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write PL_UPDMA offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            //Select EdgeDetection IP user project
            $display($time, "=> Fpga2Soc_Write: SOC_CC");
            offset = 0;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, SOC_CC, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, SOC_CC, offset, data, 1);
            //#20us
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Write SOC_CC offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write SOC_CC offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            //Configure EdgeDetection IP
            $display($time, "=> Fpga2Soc_Write: SOC_UP");
            offset = 4;
            data = 32'h0000_0280;
            axil_cycles_gen(ReadCyc, SOC_UP, offset, data, 1);
            //#20us
            if(data == 32'h0000_0280) begin
                $display($time, "=> Fpga2Soc_Write SOC_UP offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write SOC_UP offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> Fpga2Soc_Write: SOC_UP");
            offset = 8;
            data = 32'h0000_0168;
            axil_cycles_gen(WriteCyc, SOC_UP, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, SOC_UP, offset, data, 1);
            //#20us
            if(data == 32'h0000_0168) begin
                $display($time, "=> Fpga2Soc_Write SOC_UP offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write SOC_UP offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> Fpga2Soc_Write: SOC_CC");
            offset = 0;
            data = 32'h0000_0000;
            axil_cycles_gen(WriteCyc, SOC_CC, offset, data, 1);
            //#20us
            axil_cycles_gen(ReadCyc, SOC_CC, offset, data, 1);
            //#20us
            if(data == 32'h0000_0000) begin
                $display($time, "=> Fpga2Soc_Write SOC_CC offset %h = %h, PASS", offset, data);
            end else begin
                $display($time, "=> Fpga2Soc_Write SOC_CC offset %h = %h, FAIL", offset, data);
                ->> error_event;
            end

            $display($time, "=> FpgaLocal_Write: PL_UPDMA, set ap_start...");
            offset = 32'h0000_0000;
            data = 32'h0000_0001;
            axil_cycles_gen(WriteCyc, PL_UPDMA, offset, data, 1);

            fork
                CheckuserDMADone();
            join_none

            @(userdma_done);

            $display($time, "=> End SocUp2DmaPath() test...");
            $display($time, "=> =======================================================================");
        end
    endtask

    task CheckuserDMADone;
        begin
            $display($time, "=> Starting CheckuserDMADone()...");
            $display($time, "=> =======================================================================");
            $display($time, "=> FpgaLocal_Read: PL_UPDMA");

            keepChk = 1;
            offset = 32'h0000_0010;
            $display($time, "=> Wating buffer transfer done...");
            while (keepChk) begin
                #10us
                axil_cycles_gen(ReadCyc, PL_UPDMA, offset, data, 0);
                if(data == 32'h0000_0001 || timeout_flag==1 ) begin
                    if ( timeout_flag ) $display($time, "=> ERROR: Time Out - force quiti!!!");
                    else $display($time, "=> Buffer transfer done. offset %h = %h, PASS", offset, data);
                    keepChk = 0;

                    fd = $fopen ("../../../../../updma_output.log", "w");
                    for (index = 0; index < 230400; index +=4) begin
                        $fdisplay(fd, "%08h", slave_agent2.mem_model.backdoor_memory_read_4byte(addro+index));
                    end

                    $fclose(fd);
                end
            end

            ->> userdma_done;
            $display($time, "=> End CheckuserDMADone()...");
            $display($time, "=> =======================================================================");

        end
    endtask

    task axil_cycles_gen;
        input types;
        input [15:0] target;
        input [11:0] offset;
        inout [31:0] data;
        input msg;
 
        begin
            if (types) begin
                master_agent.AXI4LITE_WRITE_BURST(base_addr + target + offset, 0, data, resp);
                if (msg)
                    $display($time, "=> AXI4LITE_WRITE_BURST %04h, value: %04h, resp: %02b", base_addr + target + offset, data, resp);
            end else begin
                master_agent.AXI4LITE_READ_BURST(base_addr + target + offset, 0, data, resp);
                if (msg)
                    $display($time, "=> AXI4LITE_READ_BURST %04h, value: %04h, resp: %02b", base_addr + target + offset, data, resp);
            end     
        end
    endtask
        
endmodule
