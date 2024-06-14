`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2023 11:55:15 AM
// Design Name: 
// Module Name: tb_fsic
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
//20230804 1. use #0 for create event to avoid potencial race condition. I didn't found issue right now, just update the code to improve it.
//  reference https://blog.csdn.net/seabeam/article/details/41078023, the source is come from http://www.deepchip.com/items/0466-07.html
//   Not using #0 is a good guideline, except for event data types.  In Verilog, there is no way to defer the event triggering to the nonblocking event queue.
//`define USER_PROJECT_SIDEBAND_SUPPORT 1

module tb_fsic #( parameter BITS=32,
    `ifdef USER_PROJECT_SIDEBAND_SUPPORT
      parameter pUSER_PROJECT_SIDEBAND_WIDTH   = 5,
      parameter pSERIALIO_WIDTH   = 13,
    `else //USER_PROJECT_SIDEBAND_SUPPORT
      parameter pUSER_PROJECT_SIDEBAND_WIDTH   = 0,
      parameter pSERIALIO_WIDTH   = 12,
    `endif //USER_PROJECT_SIDEBAND_SUPPORT
    parameter pADDR_WIDTH   = 15,
    parameter pDATA_WIDTH   = 32,
    parameter IOCLK_Period  = 10,
    // parameter DLYCLK_Period  = 1,
    parameter SHIFT_DEPTH = 5,
    parameter pRxFIFO_DEPTH = 5,
    parameter pCLK_RATIO = 4
  )
(
);

    localparam CoreClkPhaseLoop  = 4;

    localparam UP_BASE=32'h3000_0000;
    localparam AA_BASE=32'h3000_2000;
    localparam IS_BASE=32'h3000_3000;

    localparam SOC_to_FPGA_MailBox_Base=28'h000_2000;
    localparam FPGA_to_SOC_UP_BASE=28'h000_0000;
    localparam FPGA_to_SOC_AA_BASE=28'h000_2000;
    localparam FPGA_to_SOC_IS_BASE=28'h000_3000;
    
    localparam AA_MailBox_Reg_Offset=12'h000;
    localparam AA_Internal_Reg_Offset=12'h100;
    
    localparam TUSER_AXIS = 2'b00;
    localparam TUSER_AXILITE_WRITE = 2'b01;
    localparam TUSER_AXILITE_READ_REQ = 2'b10;
    localparam TUSER_AXILITE_READ_CPL = 2'b11;

    localparam TID_DN_UP = 2'b00;
    localparam TID_DN_AA = 2'b01;
    localparam TID_UP_UP = 2'b00;
    localparam TID_UP_AA = 2'b01;
    localparam TID_UP_LA = 2'b10;

    localparam fpga_axis_test_length = 16;

    localparam BASE_OFFSET = 8;
    localparam RXD_OFFSET = BASE_OFFSET;
    localparam RXCLK_OFFSET = RXD_OFFSET + pSERIALIO_WIDTH;
    localparam TXD_OFFSET = RXCLK_OFFSET + 1;
    localparam TXCLK_OFFSET = TXD_OFFSET + pSERIALIO_WIDTH;
    localparam IOCLK_OFFSET = TXCLK_OFFSET + 1;
    localparam TXRX_WIDTH = IOCLK_OFFSET - BASE_OFFSET + 1;
    
    real ioclk_pd = IOCLK_Period;

  wire           wb_rst;
  wire           wb_clk;
  reg   [31: 0] wbs_adr;
  reg   [31: 0] wbs_wdata;
  reg    [3: 0] wbs_sel;
  reg           wbs_cyc;
  reg           wbs_stb;
  reg           wbs_we;
  reg  [127: 0] la_data_in;
  reg  [127: 0] la_oenb;
  wire   [37: 0] io_in;
  `ifdef USE_POWER_PINS
  reg           vccd1;
  reg           vccd2;
  reg           vssd1;
  reg           vssd2;
  `endif //USE_POWER_PINS
  reg           user_clock2;
  reg           ioclk_source;
  
  wire  [37: 0] io_oeb;  
  wire  [37: 0] io_out;  
  
  wire soc_coreclk;
  wire fpga_coreclk;
  
  wire [37:0] mprj_io;
  wire  [127: 0] la_data_out;
  wire    [2: 0] user_irq;
  
//-------------------------------------------------------------------------------------
  
  reg[31:0] cfg_read_data_expect_value;
  reg[31:0] cfg_read_data_captured;
  event soc_cfg_read_event;
  
  reg[27:0] soc_to_fpga_mailbox_write_addr_expect_value;
  reg[3:0] soc_to_fpga_mailbox_write_addr_BE_expect_value;
  reg[31:0] soc_to_fpga_mailbox_write_data_expect_value;
  reg [31:0] soc_to_fpga_mailbox_write_addr_captured;
  reg [31:0] soc_to_fpga_mailbox_write_data_captured;
  event soc_to_fpga_mailbox_write_event;

  reg stream_data_addr_or_data; //0: address, 1: data, use to identify the write transaction from AA.

  reg [31:0] soc_to_fpga_axilite_read_cpl_expect_value;
  reg [31:0] soc_to_fpga_axilite_read_cpl_captured;
  event soc_to_fpga_axilite_read_cpl_event;



  reg [6:0] soc_to_fpga_axis_expect_count;
  `ifdef USER_PROJECT_SIDEBAND_SUPPORT
    reg [(pUSER_PROJECT_SIDEBAND_WIDTH+4+4+1+32-1):0] soc_to_fpga_axis_expect_value[127:0];
  `else //USER_PROJECT_SIDEBAND_SUPPORT
    reg [(4+4+1+32-1):0] soc_to_fpga_axis_expect_value[127:0];
  `endif //USER_PROJECT_SIDEBAND_SUPPORT
      
  reg [6:0] soc_to_fpga_axis_captured_count;
  `ifdef USER_PROJECT_SIDEBAND_SUPPORT
    reg [(pUSER_PROJECT_SIDEBAND_WIDTH+4+4+1+32-1):0] soc_to_fpga_axis_captured[127:0];
  `else //USER_PROJECT_SIDEBAND_SUPPORT
    reg [(4+4+1+32-1):0] soc_to_fpga_axis_captured[127:0];
  `endif //USER_PROJECT_SIDEBAND_SUPPORT
  
  event soc_to_fpga_axis_event;

  reg [31:0] error_cnt;
  reg [31:0] check_cnt;
//-------------------------------------------------------------------------------------  
  //reg soc_rst;
  reg fpga_rst;
  reg soc_resetb;    //POR reset
  reg fpga_resetb;  //POR reset  

  //write addr channel
  reg fpga_axi_awvalid;
  reg [pADDR_WIDTH-1:0] fpga_axi_awaddr;
  wire fpga_axi_awready;
  
  //write data channel
  reg   fpga_axi_wvalid;
  reg   [pDATA_WIDTH-1:0] fpga_axi_wdata;
  reg   [3:0] fpga_axi_wstrb;
  wire  fpga_axi_wready;
  
  //read addr channel
  reg   fpga_axi_arvalid;
  reg   [pADDR_WIDTH-1:0] fpga_axi_araddr;
  wire   fpga_axi_arready;
  
  //read data channel
  wire   fpga_axi_rvalid;
  wire   [pDATA_WIDTH-1:0] fpga_axi_rdata;
  reg   fpga_axi_rready;
  
  reg   fpga_cc_is_enable;    //axi_lite enable

  wire [pSERIALIO_WIDTH-1:0] soc_serial_txd;
  wire soc_txclk;
  wire fpga_txclk;
  
  reg [pDATA_WIDTH-1:0] fpga_as_is_tdata;
  `ifdef USER_PROJECT_SIDEBAND_SUPPORT
    reg   [pUSER_PROJECT_SIDEBAND_WIDTH-1:0] fpga_as_is_tupsb;
  `endif //USER_PROJECT_SIDEBAND_SUPPORT
  reg [3:0] fpga_as_is_tstrb;
  reg [3:0] fpga_as_is_tkeep;
  reg fpga_as_is_tlast;
  reg [1:0] fpga_as_is_tid;
  reg fpga_as_is_tvalid;
  reg [1:0] fpga_as_is_tuser;
  reg fpga_as_is_tready;    //when local side axis switch Rxfifo size <= threshold then as_is_tready=0; this flow control mechanism is for notify remote side do not provide data with is_as_tvalid=1

  wire [pSERIALIO_WIDTH-1:0] fpga_serial_txd;

  wire [pDATA_WIDTH-1:0] fpga_is_as_tdata;
  `ifdef USER_PROJECT_SIDEBAND_SUPPORT
    wire   [pUSER_PROJECT_SIDEBAND_WIDTH-1:0] fpga_is_as_tupsb;
  `endif //USER_PROJECT_SIDEBAND_SUPPORT
  wire [3:0] fpga_is_as_tstrb;
  wire [3:0] fpga_is_as_tkeep;
  wire fpga_is_as_tlast;
  wire [1:0] fpga_is_as_tid;
  wire fpga_is_as_tvalid;
  wire [1:0] fpga_is_as_tuser;
  wire fpga_is_as_tready;    //when remote side axis switch Rxfifo size <= threshold then is_as_tready=0, this flow control mechanism is for notify local side do not provide data with as_is_tvalid=1

  wire  wbs_ack;
  wire  [pDATA_WIDTH-1: 0] wbs_rdata;

//-------------------------------------------------------------------------------------  
  fsic_clock_div soc_clock_div (
  .resetb(soc_resetb),
  .in(ioclk_source),
  .out(soc_coreclk)
  );

  fsic_clock_div fpga_clock_div (
  .resetb(fpga_resetb),
  .in(ioclk_source),
  .out(fpga_coreclk)
  );

FSIC #(
    .pUSER_PROJECT_SIDEBAND_WIDTH(pUSER_PROJECT_SIDEBAND_WIDTH),
    .pSERIALIO_WIDTH(pSERIALIO_WIDTH),
    .pADDR_WIDTH(pADDR_WIDTH),
    .pDATA_WIDTH(pDATA_WIDTH),
    .pRxFIFO_DEPTH(pRxFIFO_DEPTH),
    .pCLK_RATIO(pCLK_RATIO)
  )
  dut (
    //.serial_tclk(soc_txclk),
    //.serial_rclk(fpga_txclk),
    //.serial_txd(soc_serial_txd),
    //.serial_rxd(fpga_serial_txd),
    .wb_rst(wb_rst),
    .wb_clk(wb_clk),
    .wbs_adr(wbs_adr),
    .wbs_wdata(wbs_wdata),
    .wbs_sel(wbs_sel),
    .wbs_cyc(wbs_cyc),
    .wbs_stb(wbs_stb),
    .wbs_we(wbs_we),
    //.la_data_in(la_data_in),
    //.la_oenb(la_oenb),
    .io_in(io_in),
    `ifdef USE_POWER_PINS        
    .vccd1(vccd1),
    .vccd2(vccd2),
    .vssd1(vssd1),
    .vssd2(vssd2),
    `endif //USE_POWER_PINS        
    .wbs_ack(wbs_ack),
    .wbs_rdata(wbs_rdata),    
    //.la_data_out(la_data_out),
    .user_irq(user_irq),
    .io_out(io_out),
    .io_oeb(io_oeb),
    .user_clock2(user_clock2)
  );

  fpga  #(
    .pUSER_PROJECT_SIDEBAND_WIDTH(pUSER_PROJECT_SIDEBAND_WIDTH),
    .pSERIALIO_WIDTH(pSERIALIO_WIDTH),
    .pADDR_WIDTH(pADDR_WIDTH),
    .pDATA_WIDTH(pDATA_WIDTH),
    .pRxFIFO_DEPTH(pRxFIFO_DEPTH),
    .pCLK_RATIO(pCLK_RATIO)
  )
  fpga_fsic(
    .axis_rst_n(~fpga_rst),
    .axi_reset_n(~fpga_rst),
    .serial_tclk(fpga_txclk),
    .serial_rclk(soc_txclk),
    .ioclk(ioclk_source),
    .axis_clk(fpga_coreclk),
    .axi_clk(fpga_coreclk),
    
    //write addr channel
    .axi_awvalid_s_awvalid(fpga_axi_awvalid),
    .axi_awaddr_s_awaddr(fpga_axi_awaddr),
    .axi_awready_axi_awready3(fpga_axi_awready),

    //write data channel
    .axi_wvalid_s_wvalid(fpga_axi_wvalid),
    .axi_wdata_s_wdata(fpga_axi_wdata),
    .axi_wstrb_s_wstrb(fpga_axi_wstrb),
    .axi_wready_axi_wready3(fpga_axi_wready),

    //read addr channel
    .axi_arvalid_s_arvalid(fpga_axi_arvalid),
    .axi_araddr_s_araddr(fpga_axi_araddr),
    .axi_arready_axi_arready3(fpga_axi_arready),
    
    //read data channel
    .axi_rvalid_axi_rvalid3(fpga_axi_rvalid),
    .axi_rdata_axi_rdata3(fpga_axi_rdata),
    .axi_rready_s_rready(fpga_axi_rready),
    
    .cc_is_enable(fpga_cc_is_enable),


    .as_is_tdata(fpga_as_is_tdata),
    `ifdef USER_PROJECT_SIDEBAND_SUPPORT
      .as_is_tupsb(fpga_as_is_tupsb),
    `endif //USER_PROJECT_SIDEBAND_SUPPORT
    .as_is_tstrb(fpga_as_is_tstrb),
    .as_is_tkeep(fpga_as_is_tkeep),
    .as_is_tlast(fpga_as_is_tlast),
    .as_is_tid(fpga_as_is_tid),
    .as_is_tvalid(fpga_as_is_tvalid),
    .as_is_tuser(fpga_as_is_tuser),
    .as_is_tready(fpga_as_is_tready),
    .serial_txd(fpga_serial_txd),
    .serial_rxd(soc_serial_txd),
    .is_as_tdata(fpga_is_as_tdata),
    `ifdef USER_PROJECT_SIDEBAND_SUPPORT
      .is_as_tupsb(fpga_is_as_tupsb),
    `endif //USER_PROJECT_SIDEBAND_SUPPORT
    .is_as_tstrb(fpga_is_as_tstrb),
    .is_as_tkeep(fpga_is_as_tkeep),
    .is_as_tlast(fpga_is_as_tlast),
    .is_as_tid(fpga_is_as_tid),
    .is_as_tvalid(fpga_is_as_tvalid),
    .is_as_tuser(fpga_is_as_tuser),
    .is_as_tready(fpga_is_as_tready)
  );

  assign wb_clk = soc_coreclk;
  assign wb_rst = ~soc_resetb;    //wb_rst is high active
  //assign ioclk = ioclk_source;
  
  assign mprj_io[IOCLK_OFFSET] = ioclk_source;
  assign mprj_io[RXCLK_OFFSET] = fpga_txclk;
  assign mprj_io[RXD_OFFSET +: pSERIALIO_WIDTH] = fpga_serial_txd;

  assign soc_txclk = mprj_io[TXCLK_OFFSET];
  assign soc_serial_txd = mprj_io[TXD_OFFSET +: pSERIALIO_WIDTH];

  //connect input part : mprj_io to io_in
  assign io_in[IOCLK_OFFSET] = mprj_io[IOCLK_OFFSET];
  assign io_in[RXCLK_OFFSET] = mprj_io[RXCLK_OFFSET];
  assign io_in[RXD_OFFSET +: pSERIALIO_WIDTH] = mprj_io[RXD_OFFSET +: pSERIALIO_WIDTH];

  //connect output part : io_out to mprj_io
  assign mprj_io[TXCLK_OFFSET] = io_out[TXCLK_OFFSET];
  assign mprj_io[TXD_OFFSET +: pSERIALIO_WIDTH] = io_out[TXD_OFFSET +: pSERIALIO_WIDTH];
  
  initial begin
    $dumpfile("log.vcd");
    $dumpvars(0,tb_fsic);
  end

  initial begin
  ioclk_source=0;
      soc_resetb = 0;
  wbs_adr = 0;
  wbs_wdata = 0;
  wbs_sel = 0;
  wbs_cyc = 0;
  wbs_stb = 0;
  wbs_we = 0;
  la_data_in = 0;
  la_oenb = 0;
      `ifdef USE_POWER_PINS
      vccd1 = 1;
      vccd2 = 1;
      vssd1 = 1;
      vssd2 = 1;
      `endif //USE_POWER_PINS    
  user_clock2 = 0;
  error_cnt = 0;
  check_cnt = 0;

	$display("TPU test from SoC side");
  TPU_test_pattern(0);
  TPU_test_pattern(1);
  TPU_test_pattern(2);
  TPU_test_pattern(3);

	$display("TPU test from FPGA side");
  TPU_test_pattern_FPGA(0);
  TPU_test_pattern_FPGA(1);
  TPU_test_pattern_FPGA(2);
  TPU_test_pattern_FPGA(3);


  $display("=============================================================================================");
  $display("=============================================================================================");
  $display("=============================================================================================");

  $finish;
      
  end
    
  //WB Master wb_ack_o handling
  always @( posedge wb_clk or posedge wb_rst) begin
    if ( wb_rst ) begin
      wbs_adr <= 32'h0;
      wbs_wdata <= 32'h0;
      wbs_sel <= 4'b0;
      wbs_cyc <= 1'b0;
      wbs_stb <= 1'b0;
      wbs_we <= 1'b0;      
    end else begin 
      if ( wbs_ack ) begin
        wbs_adr <= 32'h0;
        wbs_wdata <= 32'h0;
        wbs_sel <= 4'b0;
        wbs_cyc <= 1'b0;
        wbs_stb <= 1'b0;
        wbs_we <= 1'b0;
      end
    end
  end    
  
  always #(ioclk_pd/2) ioclk_source = ~ioclk_source;

  initial begin    //get soc wishbone read data result.
    while (1) begin
      @(posedge soc_coreclk);
      if (wbs_ack==1 && wbs_we == 0) begin
        //$display($time, "=> get wishbone read data result be : cfg_read_data_captured =%x, wbs_rdata=%x", cfg_read_data_captured, wbs_rdata);
        cfg_read_data_captured = wbs_rdata ;    //use block assignment
        //$display($time, "=> get wishbone read data result af : cfg_read_data_captured =%x, wbs_rdata=%x", cfg_read_data_captured, wbs_rdata);
        #0 -> soc_cfg_read_event;
        `ifdef DEBUG
        $display($time, "=> soc wishbone read data result : send soc_cfg_read_event");
        `endif
      end  
    end
  end

  initial begin    //when soc cfg write to AA, then AA in soc generate soc_to_fpga_mailbox_write, 
     stream_data_addr_or_data = 0;
    while (1) begin
      @(posedge fpga_coreclk);
      //New AA version, all stream data with last = 1.  
      if (fpga_is_as_tvalid == 1 && fpga_is_as_tid == TID_UP_AA && fpga_is_as_tuser == TUSER_AXILITE_WRITE && fpga_is_as_tlast == 1) begin
      
                if(stream_data_addr_or_data == 1'b0) begin
                    //Address
                    $display($time, "=> get soc_to_fpga_mailbox_write_addr_captured be : soc_to_fpga_mailbox_write_addr_captured =%x, fpga_is_as_tdata=%x", soc_to_fpga_mailbox_write_addr_captured, fpga_is_as_tdata);
                    soc_to_fpga_mailbox_write_addr_captured = fpga_is_as_tdata ;    //use block assignment
                    $display($time, "=> get soc_to_fpga_mailbox_write_addr_captured af : soc_to_fpga_mailbox_write_addr_captured =%x, fpga_is_as_tdata=%x", soc_to_fpga_mailbox_write_addr_captured, fpga_is_as_tdata);
                    //Next should be data
                    stream_data_addr_or_data = 1; 
                end else begin
                    //Data
                    $display($time, "=> get soc_to_fpga_mailbox_write_data_captured be : soc_to_fpga_mailbox_write_data_captured =%x, fpga_is_as_tdata=%x", soc_to_fpga_mailbox_write_data_captured, fpga_is_as_tdata);
                    soc_to_fpga_mailbox_write_data_captured = fpga_is_as_tdata ;    //use block assignment
                    $display($time, "=> get soc_to_fpga_mailbox_write_data_captured af : soc_to_fpga_mailbox_write_data_captured =%x, fpga_is_as_tdata=%x", soc_to_fpga_mailbox_write_data_captured, fpga_is_as_tdata);
                    #0 -> soc_to_fpga_mailbox_write_event;
                    $display($time, "=> soc_to_fpga_mailbox_write_data_captured : send soc_to_fpga_mailbox_write_event");                    
                    //Next should be address
                    stream_data_addr_or_data = 0;
                end
      end  
      
      
    end
  end

  initial begin    //get upstream soc_to_fpga_axilite_read_completion
    while (1) begin
      @(posedge fpga_coreclk);
      if (fpga_is_as_tvalid == 1 && fpga_is_as_tid == TID_UP_AA && fpga_is_as_tuser == TUSER_AXILITE_READ_CPL) begin
        $display($time, "=> get soc_to_fpga_axilite_read_cpl_captured be : soc_to_fpga_axilite_read_cpl_captured =%x, fpga_is_as_tdata=%x", soc_to_fpga_axilite_read_cpl_captured, fpga_is_as_tdata);
        soc_to_fpga_axilite_read_cpl_captured = fpga_is_as_tdata ;    //use block assignment
        $display($time, "=> get soc_to_fpga_axilite_read_cpl_captured af : soc_to_fpga_axilite_read_cpl_captured =%x, fpga_is_as_tdata=%x", soc_to_fpga_axilite_read_cpl_captured, fpga_is_as_tdata);
        #0 -> soc_to_fpga_axilite_read_cpl_event;
        $display($time, "=> soc_to_fpga_axilite_read_cpl_captured : send soc_to_fpga_axilite_read_cpl_event");
      end  
    end
  end

    reg soc_to_fpga_axis_event_triggered;

  initial begin    //get upstream soc_to_fpga_axis - for loop back test
        soc_to_fpga_axis_captured_count = 0;
        soc_to_fpga_axis_event_triggered = 0;
    while (1) begin
      @(posedge fpga_coreclk);
      `ifdef USER_PROJECT_SIDEBAND_SUPPORT
        if (fpga_is_as_tvalid == 1 && fpga_is_as_tid == TID_UP_UP && fpga_is_as_tuser == TUSER_AXIS) begin
          $display($time, "=> get soc_to_fpga_axis be : soc_to_fpga_axis_captured_count=%d,  soc_to_fpga_axis_captured[%d] =%x, fpga_is_as_tupsb=%x, fpga_is_as_tstrb=%x, fpga_is_as_tkeep=%x , fpga_is_as_tlast=%x, fpga_is_as_tdata=%x", soc_to_fpga_axis_captured_count, soc_to_fpga_axis_captured_count, soc_to_fpga_axis_captured[soc_to_fpga_axis_captured_count], fpga_is_as_tupsb, fpga_is_as_tstrb, fpga_is_as_tkeep , fpga_is_as_tlast, fpga_is_as_tdata);
          soc_to_fpga_axis_captured[soc_to_fpga_axis_captured_count] = {fpga_is_as_tupsb, fpga_is_as_tstrb, fpga_is_as_tkeep , fpga_is_as_tlast, fpga_is_as_tdata} ;    //use block assignment
          $display($time, "=> get soc_to_fpga_axis af : soc_to_fpga_axis_captured_count=%d,  soc_to_fpga_axis_captured[%d] =%x, fpga_is_as_tupsb=%x, fpga_is_as_tstrb=%x, fpga_is_as_tkeep=%x , fpga_is_as_tlast=%x, fpga_is_as_tdata=%x", soc_to_fpga_axis_captured_count, soc_to_fpga_axis_captured_count, soc_to_fpga_axis_captured[soc_to_fpga_axis_captured_count], fpga_is_as_tupsb, fpga_is_as_tstrb, fpga_is_as_tkeep , fpga_is_as_tlast, fpga_is_as_tdata);
          soc_to_fpga_axis_captured_count = soc_to_fpga_axis_captured_count+1;
        end  
        if ( (soc_to_fpga_axis_captured_count == fpga_axis_test_length) && !soc_to_fpga_axis_event_triggered) begin
          $display($time, "=> soc_to_fpga_axis_captured : send soc_to_fpga_axiis_event");
          #0 -> soc_to_fpga_axis_event;
          soc_to_fpga_axis_event_triggered = 1;
        end 
      `else //USER_PROJECT_SIDEBAND_SUPPORT
        if (fpga_is_as_tvalid == 1 && fpga_is_as_tid == TID_UP_UP && fpga_is_as_tuser == TUSER_AXIS) begin
          $display($time, "=> get soc_to_fpga_axis be : soc_to_fpga_axis_captured_count=%d,  soc_to_fpga_axis_captured[%d] =%x, fpga_is_as_tstrb=%x, fpga_is_as_tkeep=%x , fpga_is_as_tlast=%x, fpga_is_as_tdata=%x", soc_to_fpga_axis_captured_count, soc_to_fpga_axis_captured_count, soc_to_fpga_axis_captured[soc_to_fpga_axis_captured_count], fpga_is_as_tstrb, fpga_is_as_tkeep , fpga_is_as_tlast, fpga_is_as_tdata);
          soc_to_fpga_axis_captured[soc_to_fpga_axis_captured_count] = {fpga_is_as_tstrb, fpga_is_as_tkeep , fpga_is_as_tlast, fpga_is_as_tdata} ;    //use block assignment
          $display($time, "=> get soc_to_fpga_axis af : soc_to_fpga_axis_captured_count=%d,  soc_to_fpga_axis_captured[%d] =%x, fpga_is_as_tstrb=%x, fpga_is_as_tkeep=%x , fpga_is_as_tlast=%x, fpga_is_as_tdata=%x", soc_to_fpga_axis_captured_count, soc_to_fpga_axis_captured_count, soc_to_fpga_axis_captured[soc_to_fpga_axis_captured_count], fpga_is_as_tstrb, fpga_is_as_tkeep , fpga_is_as_tlast, fpga_is_as_tdata);
          soc_to_fpga_axis_captured_count = soc_to_fpga_axis_captured_count+1;
        end  
        if ( (soc_to_fpga_axis_captured_count == fpga_axis_test_length) && !soc_to_fpga_axis_event_triggered) begin
          $display($time, "=> soc_to_fpga_axis_captured : send soc_to_fpga_axiis_event");
          #0 -> soc_to_fpga_axis_event;
          soc_to_fpga_axis_event_triggered = 1;
        end 
      `endif //USER_PROJECT_SIDEBAND_SUPPORT

      
            if (soc_to_fpga_axis_captured_count != fpga_axis_test_length)
                soc_to_fpga_axis_event_triggered = 0;

    end
  end

  reg[31:0]idx1;


  task fpga_axilite_write;
    input [27:0] address;
    input [3:0] BE;
    input [31:0] data;
    begin
      fpga_as_is_tdata <= (BE<<28) + address;  //for axilite write address phase
      //$strobe($time, "=> fpga_as_is_tdata in address phase = %x", fpga_as_is_tdata);
      `ifdef USER_PROJECT_SIDEBAND_SUPPORT
        fpga_as_is_tupsb <=  5'b00000;
      `endif //USER_PROJECT_SIDEBAND_SUPPORT
      fpga_as_is_tstrb <=  4'b0000;
      fpga_as_is_tkeep <=  4'b0000;
      fpga_as_is_tid <=  TID_DN_AA ;    //target to Axis-Axilite
      fpga_as_is_tuser <=  TUSER_AXILITE_WRITE;    //for axilite write
      fpga_as_is_tlast <=  1'b0;
      fpga_as_is_tvalid <= 1;

      @ (posedge fpga_coreclk);
      while (fpga_is_as_tready == 0) begin    // wait util fpga_is_as_tready == 1 then change data
          @ (posedge fpga_coreclk);
      end

      fpga_as_is_tdata <=  data;  //for axilite write data phase
      `ifdef USER_PROJECT_SIDEBAND_SUPPORT
        fpga_as_is_tupsb <=  5'b00000;
      `endif //USER_PROJECT_SIDEBAND_SUPPORT
      fpga_as_is_tstrb <=  4'b0000;
      fpga_as_is_tkeep <=  4'b0000;
      fpga_as_is_tid <=  TID_DN_AA;    //target to Axis-Axilite
      fpga_as_is_tuser <=  TUSER_AXILITE_WRITE;    //for axilite write
      fpga_as_is_tlast <=  1'b0;
      fpga_as_is_tvalid <= 1;

      @ (posedge fpga_coreclk);
      while (fpga_is_as_tready == 0) begin    // wait util fpga_is_as_tready == 1 then change data
          @ (posedge fpga_coreclk);
      end
      fpga_as_is_tvalid <= 0;
    
    end
  endtask

  task fpga_as_to_is_init;
    //input [7:0] compare_data;

    begin
      //init fpga as to is signal, set fpga_as_is_tready = 1 for receives data from soc
      @ (posedge fpga_coreclk);
      fpga_as_is_tdata <=  32'h0;
      `ifdef USER_PROJECT_SIDEBAND_SUPPORT
        fpga_as_is_tupsb <=  5'b00000;
      `endif //USER_PROJECT_SIDEBAND_SUPPORT
      fpga_as_is_tstrb <=  4'b0000;
      fpga_as_is_tkeep <=  4'b0000;
      fpga_as_is_tid <=  TID_DN_UP;
      fpga_as_is_tuser <=  TUSER_AXIS;
      fpga_as_is_tlast <=  1'b0;
      fpga_as_is_tvalid <= 0;
      fpga_as_is_tready <= 1;
      $display($time, "=> fpga_as_to_is_init done");
    end
  endtask

  task fpga_axilite_read_req;
    input [31:0] address;
    begin
      fpga_as_is_tdata <= address;  //for axilite read address req phase
      $strobe($time, "=> fpga_axilite_read_req in address req phase = %x - tvalid", fpga_as_is_tdata);
      `ifdef USER_PROJECT_SIDEBAND_SUPPORT
        fpga_as_is_tupsb <=  5'b00000;
      `endif //USER_PROJECT_SIDEBAND_SUPPORT
      fpga_as_is_tstrb <=  4'b0000;
      fpga_as_is_tkeep <=  4'b0000;
      fpga_as_is_tid <=  TID_DN_AA;    //target to Axis-Axilite
      fpga_as_is_tuser <=  TUSER_AXILITE_READ_REQ;    //for axilite read req
      fpga_as_is_tlast <=  1'b0;
      fpga_as_is_tvalid <= 1;

      @ (posedge fpga_coreclk);
      while (fpga_is_as_tready == 0) begin    // wait util fpga_is_as_tready == 1 then change data
          @ (posedge fpga_coreclk);
      end
      $display($time, "=> fpga_axilite_read_req in address req phase = %x - transfer", fpga_as_is_tdata);
      fpga_as_is_tvalid <= 0;
    
    end
  endtask

  task fpga_is_as_data_valid;
    // input [31:0] address;
    begin
      fpga_as_is_tready <= 1;    //TODO change to other location for set fpga_as_is_tready
      
      $strobe($time, "=> fpga_is_as_data_valid wait fpga_is_as_tvalid");
      @ (posedge fpga_coreclk);
      while (fpga_is_as_tvalid == 0) begin    // wait util fpga_is_as_tvalid == 1 
          @ (posedge fpga_coreclk);
      end
      $strobe($time, "=> fpga_is_as_data_valid wait fpga_is_as_tvalid done, fpga_is_as_tvalid = %b", fpga_is_as_tvalid);
    
    end
  endtask


  task fpga_axis_req;
    input [31:0] data;
    input [1:0] tid;
    input mode;  //o ffor noram, 1 for random data
    reg [31:0] tdata;
    `ifdef USER_PROJECT_SIDEBAND_SUPPORT
      reg [pUSER_PROJECT_SIDEBAND_WIDTH-1:0]tupsb;
    `endif //USER_PROJECT_SIDEBAND_SUPPORT
    reg [3:0] tstrb;
    reg [3:0] tkeep;
    reg tlast;
    
    begin
      if (mode) begin    //for random data
        tdata = $random;
        `ifdef USER_PROJECT_SIDEBAND_SUPPORT
          tupsb = $random;
        `endif //USER_PROJECT_SIDEBAND_SUPPORT
        tstrb = $random;
        tkeep = $random;
        tlast = $random;
      end
      else begin
        tdata = data;
        `ifdef USER_PROJECT_SIDEBAND_SUPPORT
          //tupsb = 5'b00000;
          tupsb = tdata[4:0];
        `endif //USER_PROJECT_SIDEBAND_SUPPORT
        tstrb = 4'b0000;
        tkeep = 4'b0000;
        tlast = 1'b0;
      end
      `ifdef USER_PROJECT_SIDEBAND_SUPPORT
        fpga_as_is_tupsb <= tupsb;
      `endif //USER_PROJECT_SIDEBAND_SUPPORT
      fpga_as_is_tstrb <=  tstrb;
      fpga_as_is_tkeep <=  tkeep;
      fpga_as_is_tlast <=  tlast;
      fpga_as_is_tdata <= tdata;  //for axis write data
      `ifdef USER_PROJECT_SIDEBAND_SUPPORT
        $strobe($time, "=> fpga_axis_req send data, fpga_as_is_tupsb = %b, fpga_as_is_tstrb = %b, fpga_as_is_tkeep = %b, fpga_as_is_tlast = %b, fpga_as_is_tdata = %x", fpga_as_is_tupsb, fpga_as_is_tstrb, fpga_as_is_tkeep, fpga_as_is_tlast, fpga_as_is_tdata);
      `else //USER_PROJECT_SIDEBAND_SUPPORT 
        $strobe($time, "=> fpga_axis_req send data, fpga_as_is_tstrb = %b, fpga_as_is_tkeep = %b, fpga_as_is_tlast = %b, fpga_as_is_tdata = %x", fpga_as_is_tstrb, fpga_as_is_tkeep, fpga_as_is_tlast, fpga_as_is_tdata);
      `endif //USER_PROJECT_SIDEBAND_SUPPORT
      
      fpga_as_is_tid <=  tid;    //set target
      fpga_as_is_tuser <=  TUSER_AXIS;    //for axis req
      fpga_as_is_tvalid <= 1;
      `ifdef USER_PROJECT_SIDEBAND_SUPPORT
        soc_to_fpga_axis_expect_value[soc_to_fpga_axis_expect_count] <= {tupsb, tstrb, tkeep, tlast, tdata};
      `else //USER_PROJECT_SIDEBAND_SUPPORT 
        soc_to_fpga_axis_expect_value[soc_to_fpga_axis_expect_count] <= {tstrb, tkeep, tlast, tdata};
      `endif //USER_PROJECT_SIDEBAND_SUPPORT
      soc_to_fpga_axis_expect_count <= soc_to_fpga_axis_expect_count+1;

      @ (posedge fpga_coreclk);
      while (fpga_is_as_tready == 0) begin    // wait util fpga_is_as_tready == 1 then change data
          @ (posedge fpga_coreclk);
      end
      fpga_as_is_tvalid <= 0;
    
    end
  endtask

  task fpga_axilite_write_req;
    input [27:0] address;
    input [3:0] BE;
    input [31:0] data;

    begin
      fpga_as_is_tdata[27:0] <= address;  //for axilite write address phase
      fpga_as_is_tdata[31:28] <= BE;  
      $strobe($time, "=> fpga_axilite_write_req in address phase = %x - tvalid", fpga_as_is_tdata);
      `ifdef USER_PROJECT_SIDEBAND_SUPPORT
        fpga_as_is_tupsb <=  5'b00000;
      `endif //USER_PROJECT_SIDEBAND_SUPPORT
      fpga_as_is_tstrb <=  4'b0000;
      fpga_as_is_tkeep <=  4'b0000;
      fpga_as_is_tid <=  TID_DN_AA;    //target to Axis-Axilite
      fpga_as_is_tuser <=  TUSER_AXILITE_WRITE;    //for axilite write req
      fpga_as_is_tlast <=  1'b0;
      fpga_as_is_tvalid <= 1;

      @ (posedge fpga_coreclk);
      while (fpga_is_as_tready == 0) begin    // wait util fpga_is_as_tready == 1 then change data
          @ (posedge fpga_coreclk);
      end
      $display($time, "=> fpga_axilite_write_req in address phase = %x - transfer", fpga_as_is_tdata);

      fpga_as_is_tdata <= data;  //for axilite write data phase
      $strobe($time, "=> fpga_axilite_write_req in data phase = %x - tvalid", fpga_as_is_tdata);
      `ifdef USER_PROJECT_SIDEBAND_SUPPORT
        fpga_as_is_tupsb <=  5'b00000;
      `endif //USER_PROJECT_SIDEBAND_SUPPORT
      fpga_as_is_tstrb <=  4'b0000;
      fpga_as_is_tkeep <=  4'b0000;
      fpga_as_is_tid <=  TID_DN_AA;    //target to Axis-Axilite
      fpga_as_is_tuser <=  TUSER_AXILITE_WRITE;    //for axilite write req
      fpga_as_is_tlast <=  1'b1;    //tlast = 1
      fpga_as_is_tvalid <= 1;

      @ (posedge fpga_coreclk);
      while (fpga_is_as_tready == 0) begin    // wait util fpga_is_as_tready == 1 then change data
          @ (posedge fpga_coreclk);
      end
      $display($time, "=> fpga_axilite_write_req in data phase = %x - transfer", fpga_as_is_tdata);
      
      
      fpga_as_is_tvalid <= 0;
    
    end
  endtask

  //apply reset
  task soc_apply_reset;
    input real delta1;    // for POR De-Assert
    input real delta2;    // for reset De-Assert
    begin
      #(40);
      $display($time, "=> soc POR Assert"); 
      soc_resetb = 0;
      //$display($time, "=> soc reset Assert"); 
      //soc_rst = 1;
      #(delta1);

      $display($time, "=> soc POR De-Assert"); 
      soc_resetb = 1;

      #(delta2);
      //$display($time, "=> soc reset De-Assert"); 
      //soc_rst = 0;
    end  
  endtask
  
  task fpga_apply_reset;
    input real delta1;    // for POR De-Assert
    input real delta2;    // for reset De-Assert
    begin
      #(40);
      $display($time, "=> fpga POR Assert"); 
      fpga_resetb = 0;
      $display($time, "=> fpga reset Assert"); 
      fpga_rst = 1;
      #(delta1);

      $display($time, "=> fpga POR De-Assert"); 
      fpga_resetb = 1;

      #(delta2);
      $display($time, "=> fpga reset De-Assert"); 
      fpga_rst = 0;
    end
  endtask

  task soc_is_cfg_write;
    input [11:0] offset;    //4K range
    input [3:0] sel;
    input [31:0] data;
    
    begin
      @ (posedge soc_coreclk);    
      wbs_adr <= IS_BASE;      
      wbs_adr[11:2] <= offset[11:2];  //only provide DW address 
      
      wbs_wdata <= data;
      wbs_sel <= sel;
      wbs_cyc <= 1'b1;
      wbs_stb <= 1'b1;
      wbs_we <= 1'b1;  

      @(posedge soc_coreclk);
      while(wbs_ack==0) begin
        @(posedge soc_coreclk);
      end

      $display($time, "=> soc_is_cfg_write : wbs_adr=%x, wbs_sel=%b, wbs_wdata=%x", wbs_adr, wbs_sel, wbs_wdata); 
    end
  endtask

  task soc_is_cfg_read;
    input [11:0] offset;    //4K range
    input [3:0] sel;
    
    begin
      @ (posedge soc_coreclk);    
      wbs_adr <= IS_BASE;      
      wbs_adr[11:2] <= offset[11:2];  //only provide DW address 
      
      wbs_sel <= sel;
      wbs_cyc <= 1'b1;
      wbs_stb <= 1'b1;
      wbs_we <= 1'b0;  

      @(posedge soc_coreclk);
      while(wbs_ack==0) begin
        @(posedge soc_coreclk);
      end

      $display($time, "=> soc_is_cfg_read : wbs_adr=%x, wbs_sel=%b", wbs_adr, wbs_sel); 
      //#1;    //add delay to make sure cfg_read_data_captured get the correct data 
      @(soc_cfg_read_event);
      $display($time, "=> soc_is_cfg_read : got soc_cfg_read_event"); 
    end
  endtask

  task soc_aa_cfg_write;
    input [11:0] offset;    //4K range
    input [3:0] sel;
    input [31:0] data;
    
    begin
      @ (posedge soc_coreclk);    
      wbs_adr <= AA_BASE;
      wbs_adr[11:2] <= offset[11:2];  //only provide DW address 
      
      wbs_wdata <= data;
      wbs_sel <= sel;
      wbs_cyc <= 1'b1;
      wbs_stb <= 1'b1;
      wbs_we <= 1'b1;  
      
      @(posedge soc_coreclk);
      while(wbs_ack==0) begin
        @(posedge soc_coreclk);
      end

      $display($time, "=> soc_aa_cfg_write : wbs_adr=%x, wbs_sel=%b, wbs_wdata=%x", wbs_adr, wbs_sel, wbs_wdata); 
    end
  endtask

  task soc_aa_cfg_read;
    input [11:0] offset;    //4K range
    input [3:0] sel;
    
    begin
      @ (posedge soc_coreclk);    
      wbs_adr <= AA_BASE;
      wbs_adr[11:2] <= offset[11:2];  //only provide DW address 
      
      wbs_sel <= sel;
      wbs_cyc <= 1'b1;
      wbs_stb <= 1'b1;
      wbs_we <= 1'b0;    
      
      @(posedge soc_coreclk);
      while(wbs_ack==0) begin
        @(posedge soc_coreclk);
      end
      $display($time, "=> soc_aa_cfg_read : wbs_adr=%x, wbs_sel=%b", wbs_adr, wbs_sel); 
      //#1;    //add delay to make sure cfg_read_data_captured get the correct data 
      @(soc_cfg_read_event);
      $display($time, "=> soc_aa_cfg_read : got soc_cfg_read_event"); 
    end
  endtask
  
  task soc_up_cfg_write;
    input [11:0] offset;    //4K range
    input [3:0] sel;
    input [31:0] data;
    
    begin
      @ (posedge soc_coreclk);    
      wbs_adr <= UP_BASE;
      wbs_adr[11:2] <= offset[11:2];  //only provide DW address 
      
      wbs_wdata <= data;
      wbs_sel <= sel;
      wbs_cyc <= 1'b1;
      wbs_stb <= 1'b1;
      wbs_we <= 1'b1;  
      
      @(posedge soc_coreclk);
      while(wbs_ack==0) begin
        @(posedge soc_coreclk);
      end
      `ifdef DEBUG
      $display($time, "=> soc_up_cfg_write : wbs_adr=%x, wbs_sel=%b, wbs_wdata=%x", wbs_adr, wbs_sel, wbs_wdata);
      `endif
    end
  endtask  

  task soc_up_cfg_read;
    input [11:0] offset;    //4K range
    input [3:0] sel;
    
    begin
      @ (posedge soc_coreclk);    
      wbs_adr <= UP_BASE;
      wbs_adr[11:2] <= offset[11:2];  //only provide DW address 
      
      wbs_sel <= sel;
      wbs_cyc <= 1'b1;
      wbs_stb <= 1'b1;
      wbs_we <= 1'b0;    
      
      @(posedge soc_coreclk);
      while(wbs_ack==0) begin
        @(posedge soc_coreclk);
      end
      
      `ifdef DEBUG
      $display($time, "=> soc_up_cfg_read : wbs_adr=%x, wbs_sel=%b", wbs_adr, wbs_sel);
      `endif
      //#1;    //add delay to make sure cfg_read_data_captured get the correct data 
      @(soc_cfg_read_event);

      `ifdef DEBUG
      $display($time, "=> soc_up_cfg_read : got soc_cfg_read_event"); 
      `endif
    end
  endtask


  task fpga_cfg_write;    //input addr, data, strb and valid_delay 
    input [pADDR_WIDTH-1:0] axi_awaddr;
    input [pDATA_WIDTH-1:0] axi_wdata;
    input [3:0] axi_wstrb;
    input [7:0] valid_delay;
    
    begin
      fpga_axi_awaddr <= axi_awaddr;
      fpga_axi_awvalid <= 0;
      fpga_axi_wdata <= axi_wdata;
      fpga_axi_wstrb <= axi_wstrb;
      fpga_axi_wvalid <= 0;
      //$display($time, "=> fpga_delay_valid before : valid_delay=%x", valid_delay); 
      repeat (valid_delay) @ (posedge fpga_coreclk);
      //$display($time, "=> fpga_delay_valid after  : valid_delay=%x", valid_delay); 
      fpga_axi_awvalid <= 1;
      fpga_axi_wvalid <= 1;
      @ (posedge fpga_coreclk);
      while (fpga_axi_awready == 0) begin    //assume both fpga_axi_awready and fpga_axi_wready assert as the same time.
          @ (posedge fpga_coreclk);
      end
      $display($time, "=> fpga_cfg_write : fpga_axi_awaddr=%x, fpga_axi_awvalid=%b, fpga_axi_awready=%b, fpga_axi_wdata=%x, axi_wstrb=%x, fpga_axi_wvalid=%b, fpga_axi_wready=%b", fpga_axi_awaddr, fpga_axi_awvalid, fpga_axi_awready, fpga_axi_wdata, axi_wstrb, fpga_axi_wvalid, fpga_axi_wready); 
      fpga_axi_awvalid <= 0;
      fpga_axi_wvalid <= 0;
    end
    
  endtask

	task fsic_system_initial;
		begin
			fork
				soc_apply_reset(40, 40);	// reset SoC
				fpga_apply_reset(40, 40);	// reset FPGA
			join
			#40;
			fpga_as_to_is_init();	// initial FPGA AS -> IS axis signal
			fpga_cc_is_enable = 1;	// enable FPGA IS to receive axis data
			fork
				soc_is_cfg_write(0, 4'b0001, 1); // SoC rx enable
				fpga_cfg_write(0, 1, 1, 0);		 // FPGA rx enable
			join
			#400;
			fork
				soc_is_cfg_write(0, 4'b0001, 3); // SoC tx enable
				fpga_cfg_write(0, 3, 1, 0);		 // FPGA tx enable
			join
		end
	endtask

  task user_project_select;
		input [4:0] up_index;
		begin
			@ (posedge soc_coreclk);		
			wbs_adr <= 32'h3000_5000;
			
			wbs_wdata <= {27'd0, up_index};
			wbs_sel <= 4'b1111;
			wbs_cyc <= 1'b1;
			wbs_stb <= 1'b1;
			wbs_we <= 1'b1;	

			@(posedge soc_coreclk);
			while(wbs_ack==0) begin
				@(posedge soc_coreclk);
			end
      `ifdef DEBUG
			$display($time, "=> user_project %d is enable", up_index); 
      `endif
		end
	endtask


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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


reg [31:0] gbuff_A [65535:0];
reg [31:0] gbuff_B [65535:0];
reg [127:0] gbuff_C [65535:0];

task TPU_test_pattern;
  input [1:0] patternID;

  $display("fsic_system_initial");
  fsic_system_initial();  // rst_n = 1'b1;
  
  $display("Enable TPU IP");
  user_project_select(1);
  
  $display("Program ap_start=0");
	@(posedge soc_coreclk) soc_up_cfg_write(TPU_CTRL_OFFSET, 4'b0001, 32'd0); // in_valid = 1'b0;

  $display("Wait TPU is idle");
  tpu_waitIdle();  // reset_task;


  case (patternID)
    2'b00: begin
      in_fd = $fopen("./pattern/pattern0/input.txt", "r");
    end
    2'b01: begin
      in_fd = $fopen("./pattern/pattern1/input.txt", "r");
    end
    2'b10: begin
      in_fd = $fopen("./pattern/pattern2/input.txt", "r");
    end
    2'b11: begin
      in_fd = $fopen("./pattern/pattern3/input.txt", "r");
    end
  endcase

  // PATNUM
  temp = $fscanf(in_fd, "%d", PATNUM);

  for(patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin

      // read input
      read_and_write_cfg_to_userprj_soc;

      // start to feed data
      repeat(3) @(negedge soc_coreclk);
      $display("patcount[%d] ap_start = 1", patcount);
      @(posedge soc_coreclk) soc_up_cfg_write(TPU_CTRL_OFFSET, 4'b0001, 32'd1); // in_valid = 1'b1;

      @(negedge soc_coreclk);
      $display("patcount[%d] ap_start = 0", patcount);
      @(posedge soc_coreclk) soc_up_cfg_write(TPU_CTRL_OFFSET, 4'b0001, 32'd0); // in_valid = 1'b0;


      wait_finished;
      
      golden_check;

      repeat(5) @(negedge soc_coreclk);
  end

  YOU_PASS_task;

endtask

	task TPU_test_pattern_FPGA;
	  input [1:0] patternID;

  $display("fsic_system_initial");
  fsic_system_initial();  // rst_n = 1'b1;
  
  $display("Enable TPU IP");
  user_project_select(1);

  $display("Program ap_start=0");
  fpga_axilite_write_req(FPGA_to_SOC_UP_BASE + TPU_CTRL_OFFSET,  4'b1111, 32'd0); // in_valid = 1'b0;

  $display("Wait TPU is idle");
  tpu_waitIdle();

  case (patternID)
    2'b00: begin
      in_fd = $fopen("./pattern/pattern0/input.txt", "r");
    end
    2'b01: begin
      in_fd = $fopen("./pattern/pattern1/input.txt", "r");
    end
    2'b10: begin
      in_fd = $fopen("./pattern/pattern2/input.txt", "r");
    end
    2'b11: begin
      in_fd = $fopen("./pattern/pattern3/input.txt", "r");
    end
  endcase

// PATNUM
  temp = $fscanf(in_fd, "%d", PATNUM);

  for(patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin

      // read input
      read_and_write_cfg_to_userprj_fpga;
      repeat(100) @ (posedge fpga_coreclk);    //TODO fpga wait for write to soc

      // start to feed data
      repeat(3) @(negedge soc_coreclk);
      $display("patcount[%d] ap_start = 1", patcount);
      @(posedge soc_coreclk) soc_up_cfg_write(TPU_CTRL_OFFSET, 4'b0001, 32'd1); // in_valid = 1'b1;

      @(negedge soc_coreclk);
      $display("patcount[%d] ap_start = 0", patcount);
      @(posedge soc_coreclk) soc_up_cfg_write(TPU_CTRL_OFFSET, 4'b0001, 32'd0); // in_valid = 1'b0;


      wait_finished;
      
      golden_check;

      repeat(5) @(negedge soc_coreclk);
  end

  YOU_PASS_task;

	endtask

///////////////////////////////////////////////////////////////////////////////

// Wait TPU is idle
task tpu_waitIdle;
  begin
    soc_up_cfg_read(TPU_CTRL_OFFSET, 4'b0001);
    while (cfg_read_data_captured[2] != 1'b1) begin
      @(posedge soc_coreclk);
      soc_up_cfg_read(TPU_CTRL_OFFSET, 4'b0001);
    end
  end
endtask

task read_and_write_cfg_to_userprj_soc;

  // read_KMN
  temp = $fscanf(in_fd, "%h", K_golden);
  temp = $fscanf(in_fd, "%h", M_golden);
  temp = $fscanf(in_fd, "%h", N_golden);
  $display("M: %d, K: %d N: %d", M_golden, K_golden, N_golden);

  soc_up_cfg_write(TPU_M_OFFSET, 4'b1111, M_golden);
  soc_up_cfg_write(TPU_K_OFFSET, 4'b1111, K_golden);
  soc_up_cfg_write(TPU_N_OFFSET, 4'b1111, N_golden);

  // read_A_Matrix
  nrow = (M_golden[1:0] !== 2'b00) ?  K_golden * ((M_golden>>2) + 1) : K_golden * (M_golden>>2);

  for(i=0;i<nrow;i=i+1) begin
    temp = $fscanf(in_fd, "%h %h %h %h", rbuf[3], rbuf[2], rbuf[1], rbuf[0]);
    gbuff_A[i] = {rbuf[3], rbuf[2], rbuf[1], rbuf[0]};
    $display("A[%d] = %h", i, gbuff_A[i]);

    soc_up_cfg_write(TPU_BUFF_A_ADDR_OFFSET, 4'b1111, i);
    soc_up_cfg_write(TPU_BUFF_A_DIN_OFFSET, 4'b1111, gbuff_A[i]);
  end

  // read_B_Matrix
  nrow = (N_golden[1:0] !== 2'b00) ? K_golden * ((N_golden >> 2) + 1) : K_golden * (N_golden >> 2);

  for(i=0;i<nrow;i=i+1) begin
      temp = $fscanf(in_fd, "%h %h %h %h", rbuf[3], rbuf[2], rbuf[1], rbuf[0]);
      gbuff_B[i] = {rbuf[3], rbuf[2], rbuf[1], rbuf[0]};
      $display("B[%d] = %h", i, gbuff_B[i]);

      soc_up_cfg_write(TPU_BUFF_B_ADDR_OFFSET, 4'b1111, i);
      soc_up_cfg_write(TPU_BUFF_B_DIN_OFFSET, 4'b1111, gbuff_B[i]);
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

  fpga_axilite_write_req(FPGA_to_SOC_UP_BASE + TPU_M_OFFSET,  4'b1111, M_golden);
  fpga_axilite_write_req(FPGA_to_SOC_UP_BASE + TPU_K_OFFSET,  4'b1111, K_golden);
  fpga_axilite_write_req(FPGA_to_SOC_UP_BASE + TPU_N_OFFSET,  4'b1111, N_golden);

  // read_A_Matrix
  nrow = (M_golden[1:0] !== 2'b00) ?  K_golden * ((M_golden>>2) + 1) : K_golden * (M_golden>>2);

  for(i=0;i<nrow;i=i+1) begin
      temp = $fscanf(in_fd, "%h %h %h %h", rbuf[3], rbuf[2], rbuf[1], rbuf[0]);
      gbuff_A[i] = {rbuf[3], rbuf[2], rbuf[1], rbuf[0]};
      $display("A[%d] = %h", i, gbuff_A[i]);

      fpga_axilite_write_req(FPGA_to_SOC_UP_BASE + TPU_BUFF_A_ADDR_OFFSET,  4'b1111, i);
      fpga_axilite_write_req(FPGA_to_SOC_UP_BASE + TPU_BUFF_A_DIN_OFFSET,  4'b1111, gbuff_A[i]);
  end

  //repeat(100) @ (posedge fpga_coreclk);    //TODO fpga wait for write to soc

  // read_B_Matrix
  nrow = (N_golden[1:0] !== 2'b00) ? K_golden * ((N_golden >> 2) + 1) : K_golden * (N_golden >> 2);

  for(i=0;i<nrow;i=i+1) begin
      temp = $fscanf(in_fd, "%h %h %h %h", rbuf[3], rbuf[2], rbuf[1], rbuf[0]);
      gbuff_B[i] = {rbuf[3], rbuf[2], rbuf[1], rbuf[0]};
      $display("B[%d] = %h", i, gbuff_B[i]);

      fpga_axilite_write_req(FPGA_to_SOC_UP_BASE + TPU_BUFF_B_ADDR_OFFSET,  4'b1111, i);
      fpga_axilite_write_req(FPGA_to_SOC_UP_BASE + TPU_BUFF_B_DIN_OFFSET,  4'b1111, gbuff_B[i]);
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

    soc_up_cfg_read(TPU_CTRL_OFFSET, 4'b0001);
    while (cfg_read_data_captured[1] != 1'b1) begin // ap_done == 1'b1

        soc_up_cfg_read(TPU_CTRL_OFFSET, 4'b0001);
    end

end endtask


task golden_check; begin

    err = 0;

    // Read C Buffer
    for(i=0;i<nrow;i=i+1) begin
      soc_up_cfg_write(TPU_BUFF_C_ADDR_OFFSET, 4'b1111, i);

      soc_up_cfg_read(TPU_BUFF_C_DOUT_0_OFFSET, 4'b0001);
			gbuff_C[i][31:0] = cfg_read_data_captured;
      soc_up_cfg_read(TPU_BUFF_C_DOUT_1_OFFSET, 4'b0001);
			gbuff_C[i][63:32] = cfg_read_data_captured;
      soc_up_cfg_read(TPU_BUFF_C_DOUT_2_OFFSET, 4'b0001);
			gbuff_C[i][95:64] = cfg_read_data_captured;
      soc_up_cfg_read(TPU_BUFF_C_DOUT_3_OFFSET, 4'b0001);
			gbuff_C[i][127:96] = cfg_read_data_captured;

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

endmodule






