// This code snippet was auto generated by xls2vlog.py from source file: ./user_project_wrapper.xlsx
// User: josh
// Date: Sep-22-23



module USER_PRJ1 #( parameter pUSER_PROJECT_SIDEBAND_WIDTH   = 5,
          parameter pADDR_WIDTH   = 12,
                   parameter pDATA_WIDTH   = 32,
          parameter gfADDR_WIDTH = 6
                 )
(
  output wire                        awready,
  output wire                        arready,
  output wire                        wready,
  output wire                        rvalid,
  output wire  [(pDATA_WIDTH-1) : 0] rdata,
  input  wire                        awvalid,
  input  wire                [11: 0] awaddr,
  input  wire                        arvalid,
  input  wire                [11: 0] araddr,
  input  wire                        wvalid,
  input  wire                 [3: 0] wstrb,
  input  wire  [(pDATA_WIDTH-1) : 0] wdata,
  input  wire                        rready,
  input  wire                        ss_tvalid,
  input  wire  [(pDATA_WIDTH-1) : 0] ss_tdata,
  input  wire                 [1: 0] ss_tuser,
    `ifdef USER_PROJECT_SIDEBAND_SUPPORT
  input  wire                 [pUSER_PROJECT_SIDEBAND_WIDTH-1: 0] ss_tupsb,
  `endif
  input  wire                 [3: 0] ss_tstrb,
  input  wire                 [3: 0] ss_tkeep,
  input  wire                        ss_tlast,
  input  wire                        sm_tready,
  output wire                        ss_tready,
  output wire                        sm_tvalid,
  output wire  [(pDATA_WIDTH-1) : 0] sm_tdata,
  output wire                 [2: 0] sm_tid,
  `ifdef USER_PROJECT_SIDEBAND_SUPPORT
  output  wire                 [pUSER_PROJECT_SIDEBAND_WIDTH-1: 0] sm_tupsb,
  `endif
  output wire                 [3: 0] sm_tstrb,
  output wire                 [3: 0] sm_tkeep,
  output wire                        sm_tlast,
  output wire                        low__pri_irq,
  output wire                        High_pri_req,
  output wire                [23: 0] la_data_o,
  input  wire                        axi_clk,
  input  wire                        axis_clk,
  input  wire                        axi_reset_n,
  input  wire                        axis_rst_n,
  input  wire                        user_clock2,
  input  wire                        uck2_rst_n
);

reg rvalid_r;
reg ap_start;
wire ap_idle, ap_done;
reg task_r, task_w;

reg [7:0] M, K, N;
reg [1:0] buf_sel;
reg [15:0] buf_sizeA, buf_sizeB, buf_sizeC;

// AXIlite
reg [(pADDR_WIDTH-1):0] addr_r, addr_w;
reg [(pDATA_WIDTH-1) : 0] rdata_r;
reg [(gfADDR_WIDTH-1):0]  buf_A_address, buf_B_address, buf_C_address;

wire [(pDATA_WIDTH-1) : 0] A_data_in, B_data_in, A_data_out, B_data_out;
reg [(pDATA_WIDTH-1) : 0] buf_A_din, buf_B_din;
reg [(pDATA_WIDTH*4-1) : 0] buf_C_dout;
wire [(pDATA_WIDTH*4-1) : 0] C_data_in, C_data_out;

wire [(gfADDR_WIDTH-1):0]  A_index, B_index, C_index;
wire [(gfADDR_WIDTH-1):0]  A_index_mux, B_index_mux, C_index_mux;

wire busy;
wire A_wr_en, B_wr_en, C_wr_en;
//=====================================================================
//   DATA PATH & CONTROL
//=====================================================================
//---------- AXI-lite slave Interface ----------
// Address map
// 0x00: config ([2]ap_idle, [1]ap_done, [0]ap_start)
// 
// 0x10: M
// 0x14: K
// 0x18: N
//
// 0x20: buf_A_address
// 0x24: buf_A_din
//
// 0x30: buf_B_address
// 0x34: buf_B_din
//
// 0x40: buf_C_address
// 0x44: buf_C_dout_0
// 0x48: buf_C_dout_1
// 0x4c: buf_C_dout_2
// 0x50: buf_C_dout_3

// Read: read mmio / tap RAM
// Address read channel
assign arready = ~task_r;
always @(posedge axi_clk or negedge axis_rst_n) begin
    if (~axis_rst_n)
        addr_r <= 'd0;
    else begin
        if (arvalid & arready)
            addr_r <= araddr;
    end
end
always @(posedge axi_clk or negedge axis_rst_n) begin
    if (~axis_rst_n)
        task_r <= 1'b0;
    else begin
        case (task_r)
            1'b0: begin
                if (arvalid)
                    task_r <= 1'b1;
            end
            1'b1: begin
                if (rready & rvalid)
                    task_r <= 1'b0;
            end
        endcase
    end
end
// Read channel     * What happen if host acess tap_RAM in run state?
// assign rvalid_r = task_r;
always @(*) begin
    if (task_r) begin
        case (addr_r)
            'h00: begin
                rvalid_r = 1'b1;
                rdata_r = {5'b0, ap_idle, ap_done, ap_start};
            end
            'h10: begin
                rvalid_r = 1'b1;
                rdata_r = M;
            end
            'h14: begin
                rvalid_r = 1'b1;
                rdata_r = K;
            end
            'h18: begin
                rvalid_r = 1'b1;
                rdata_r = N;
            end
            'h20: begin
                rvalid_r = 1'b1;
                rdata_r = buf_A_address;
            end
            'h24: begin
                rvalid_r = 1'b1;
                rdata_r = buf_A_din;
            end
            'h30: begin
                rvalid_r = 1'b1;
                rdata_r = buf_B_address;
            end
            'h34: begin
                rvalid_r = 1'b1;
                rdata_r = buf_B_din;
            end
            'h40: begin
                rvalid_r = 1'b1;
                rdata_r = buf_C_address;
            end
            'h44: begin
                rvalid_r = 1'b1;
                rdata_r = C_data_out[31:0];
            end
            'h48: begin
                rvalid_r = 1'b1;
                rdata_r = C_data_out[63:32];
            end
            'h4c: begin
                rvalid_r = 1'b1;
                rdata_r = C_data_out[95:64];
            end
            'h50: begin
                rvalid_r = 1'b1;
                rdata_r = C_data_out[127:96];
            end
            default: begin
                // read tap bram
                rvalid_r = 1'b0;
                rdata_r = 'd0;
            end
        endcase
    end
    else begin
        rvalid_r = 1'b0;
        rdata_r = 'd0;
    end
end

// Write: write configation to mmio / tap RAM
// Address write channel
assign awready = ~task_w;
always @(posedge axi_clk or negedge axis_rst_n) begin
    if (~axis_rst_n)
        addr_w <= 'd0;
    else begin
        if (awvalid)
            addr_w <= awaddr;
    end
end
always @(posedge axi_clk or negedge axis_rst_n) begin
    if (~axis_rst_n)
        task_w <= 1'b0;
    else begin
        case (task_w)
            1'b0: begin
                if (awvalid)
                    task_w <= 1'b1;
            end
            1'b1: begin
                if (wvalid)
                    task_w <= 1'b0;
            end
        endcase
    end
end
// Write channel
assign wready = task_w;

//---------- Block level protocol ----------
// ap_start: axilite slave write
always @(posedge axi_clk or negedge axis_rst_n) begin
    if (~axis_rst_n)
        ap_start <= 1'b0;
    else begin
        // set by host
        if (task_w & wvalid) begin
            ap_start <= (addr_w == 'h00) ? wdata[0] : ap_start;
        end
        // reset by engine
        else if (ap_start)
            ap_start <= 1'b0;
    end
end

//---------- Port level protocol ----------
// len: axilite slave write
always @(posedge axi_clk or negedge axis_rst_n) begin
    if (~axis_rst_n) begin
        M <= 'd0;
        K <= 'd0;
        N <= 'd0;
        buf_A_address <= 'h0;
        buf_A_din <= 'h0;
        buf_B_address <= 'h0;
        buf_B_din <= 'h0;
        buf_C_address <= 'h0;
        //buf_C_dout <= 'h0;
    end
    else begin
        if (task_w & wvalid) begin
            M <= (addr_w == 'h10) ? wdata : M;
            K <= (addr_w == 'h14) ? wdata : K;
            N <= (addr_w == 'h18) ? wdata : N;
            buf_A_address <= (addr_w == 'h20) ? wdata : buf_A_address;
            buf_A_din <= (addr_w == 'h24) ? wdata : buf_A_din;
            buf_B_address <= (addr_w == 'h30) ? wdata : buf_B_address;
            buf_B_din <= (addr_w == 'h34) ? wdata : buf_B_din;
            buf_C_address <= (addr_w == 'h40) ? wdata : buf_C_address;
            //buf_C_dout <= (addr_w == 'h44) ? wdata : buf_C_dout;
        end
    end
end

assign rvalid = rvalid_r;
assign rdata = rdata_r;

assign A_index_mux = (busy == 1'b1) ? A_index : buf_A_address;
assign B_index_mux = (busy == 1'b1) ? B_index : buf_B_address;
assign C_index_mux = (busy == 1'b1) ? C_index : buf_C_address;

assign A_wr_en_mux = (busy == 1'b1) ? A_wr_en : 1'b1;
assign B_wr_en_mux = (busy == 1'b1) ? B_wr_en : 1'b1;
assign C_wr_en_mux = (busy == 1'b1) ? C_wr_en : 1'b0;

  global_buffer #(
      .ADDR_BITS(gfADDR_WIDTH),
      .DATA_BITS(pDATA_WIDTH)
  ) gbuff_A (
      .clk(axi_clk),
      .rst_n(axi_reset_n),
      .wr_en(A_wr_en_mux),
      .index(A_index_mux),
      .data_in(buf_A_din), // from testbench
      .data_out(A_data_out) // to TPU
  );

  global_buffer #(
      .ADDR_BITS(gfADDR_WIDTH),
      .DATA_BITS(pDATA_WIDTH)
  ) gbuff_B (
      .clk(axi_clk),
      .rst_n(axi_reset_n),
      .wr_en(B_wr_en_mux),
      .index(B_index_mux),
      .data_in(buf_B_din), // from testbench
      .data_out(B_data_out)  // to TPU
  );

  global_buffer #(
      .ADDR_BITS(gfADDR_WIDTH),
      .DATA_BITS(pDATA_WIDTH << 2)
  ) gbuff_C (
      .clk(axi_clk),
      .rst_n(axi_reset_n),
      .wr_en(C_wr_en_mux),
      .index(C_index_mux),
      .data_in(C_data_in),
      .data_out(C_data_out)
  );

  TPU #(
    .ADDR_BITS(gfADDR_WIDTH)
  ) My_TPU (
      .clk        (axi_clk),
      .rst_n      (axi_reset_n),
      .in_valid   (ap_start),
      .K          (K),
      .M          (M),
      .N          (N),
      .busy       (busy),
      .ap_done    (ap_done),
      .ap_idle    (ap_idle),
      .A_wr_en    (A_wr_en),
      .A_index    (A_index),
      //.A_data_in  (A_data_in_TPU),
      .A_data_out (A_data_out),
      .B_wr_en    (B_wr_en),
      .B_index    (B_index),
      //.B_data_in  (B_data_in_TPU),
      .B_data_out (B_data_out),
      .C_wr_en    (C_wr_en),
      .C_index    (C_index),
      .C_data_in  (C_data_in)
      //.C_data_out (C_data_out),
      //.inputOffset(inputOffset)
  );

endmodule // USER_PRJ1
