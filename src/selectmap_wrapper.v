// ---------------------------------------------------------------------------------------
// Copyright (c) 2024 john_tito All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ---------------------------------------------------------------------------------------

// +FHEADER-------------------------------------------------------------------------------
// Author        : john_tito
// Module Name   : selectmap_wrapper
// ---------------------------------------------------------------------------------------
// Revision      : 1.0
// Description   : File Created
// ---------------------------------------------------------------------------------------
// Synthesizable : Yes
// Clock Domains : clk
// Reset Strategy: sync reset
// -FHEADER-------------------------------------------------------------------------------

// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module selectmap_wrapper #(
    parameter integer C_APB_ADDR_WIDTH = 16,  // address width
    parameter integer C_APB_DATA_WIDTH = 32,  // data width
    parameter integer DATA_TBYTES      = 1    //data with in byte num of SelectMap interface
) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_APB:S_AXIS:M_SELECTMAP, ASSOCIATED_RESET aresetn" *)
    input  wire                       aclk,           // clock, better no more than 100Mhz
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire                       aresetn,        // sync reset, active low level
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PADDR" *)
    input  wire [ C_APB_ADDR_WIDTH:0] s_paddr,        // Address (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSEL" *)
    input  wire                       s_psel,         // Slave Select (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PENABLE" *)
    input  wire                       s_penable,      // Enable (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PWRITE" *)
    input  wire                       s_pwrite,       // Write Control (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PWDATA" *)
    input  wire [ C_APB_DATA_WIDTH:0] s_pwdata,       // Write Data (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PREADY" *)
    output wire                       s_pready,       // Slave Ready (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PRDATA" *)
    output wire [ C_APB_DATA_WIDTH:0] s_prdata,       // Read Data (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSLVERR" *)
    output wire                       s_pslverr,      // Slave Error Response (required)
    //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
    input  wire [(DATA_TBYTES*8-1):0] s_axis_tdata,   // Transfer Data (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
    input  wire                       s_axis_tvalid,  // Transfer valid (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TKEEP" *)
    input  wire                       s_axis_tkeep,   // Transfer Null Byte Indicators (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *)
    output wire                       s_axis_tready,  // Transfer ready (optional)
    //
    input  wire                       fifo_empty,     //
    //
    (* X_INTERFACE_INFO = "john_tito:interface:selectMap:1.1 M_SELECTMAP cfg_clk" *)
    output wire                       cfg_clk,        // clock of SelectMap interface, integer divide of clk
    (* X_INTERFACE_INFO = "john_tito:interface:selectMap:1.1 M_SELECTMAP cfg_data" *)
    output wire [(DATA_TBYTES*8-1):0] cfg_data,       // data bus of SelectMap interface
    (* X_INTERFACE_INFO = "john_tito:interface:selectMap:1.1 M_SELECTMAP cfg_cs_n" *)
    output wire                       cfg_cs_n,       // chip select of SelectMap interface, low active
    (* X_INTERFACE_INFO = "john_tito:interface:selectMap:1.1 M_SELECTMAP cfg_prog_n" *)
    output wire                       cfg_prog_n,     // config reset, low active
    (* X_INTERFACE_INFO = "john_tito:interface:selectMap:1.1 M_SELECTMAP cfg_init_n" *)
    input  wire                       cfg_init_n,     // config crc error state, low active
    (* X_INTERFACE_INFO = "john_tito:interface:selectMap:1.1 M_SELECTMAP cfg_rw_n" *)
    output wire                       cfg_rw_n,       // config read or write control
    (* X_INTERFACE_INFO = "john_tito:interface:selectMap:1.1 M_SELECTMAP cfg_done" *)
    input  wire                       cfg_done,       // config done state, high active
    (* X_INTERFACE_INFO = "john_tito:interface:selectMap:1.1 M_SELECTMAP cfg_bm" *)
    output wire [                2:0] cfg_bm,         // config mode select, 110 for SelectMap
    (* X_INTERFACE_INFO = "john_tito:interface:selectMap:1.1 M_SELECTMAP cfg_rst_n" *)
    output wire                       cfg_rst_n,      // fpga logic reset for user application
    (* X_INTERFACE_INFO = "john_tito:interface:selectMap:1.1 M_SELECTMAP cfg_oe" *)
    output wire                       cfg_oe          //
);

    wire        soft_rst;
    wire        busy;
    wire        clk_en;
    wire        step_en;
    wire        baud_load;
    wire [31:0] baud_div;

    // handle state and control signal of M_SELECTMAP inetrface
    selectmap_ui #(
        .C_APB_DATA_WIDTH(C_APB_DATA_WIDTH),
        .C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH)
    ) selectmap_ui_inst (
        .clk       (aclk),
        .rstn      (aresetn),
        .s_paddr   (s_paddr),
        .s_psel    (s_psel),
        .s_penable (s_penable),
        .s_pwrite  (s_pwrite),
        .s_pwdata  (s_pwdata),
        .s_pready  (s_pready),
        .s_prdata  (s_prdata),
        .s_pslverr (s_pslverr),
        .soft_rst  (soft_rst),
        .baud_load (baud_load),
        .baud_div  (baud_div),
        .busy      (busy),
        .fifo_empty(fifo_empty),
        .cfg_oe    (cfg_oe),
        .cfg_done  (cfg_done),
        .cfg_init_n(cfg_init_n),
        .cfg_rst_n (cfg_rst_n),
        .cfg_prog_n(cfg_prog_n),
        .cfg_rw_n  (cfg_rw_n),
        .cfg_bm    (cfg_bm)
    );

    // generate clock for SelectMap inetrface
    tx_clk_gen #(
        .CPOL(1'b0),
        .CPHA(1'b0)
    ) tx_clk_gen_inst (
        .clk      (aclk),
        .rst      (soft_rst),
        .en       (clk_en),
        .baud_load(baud_load),
        .baud_div (baud_div),
        .shift_en (step_en),
        .sync_clk (cfg_clk)
    );

    // generate timing for SelectMap inetrface
    selectmap_timing #(
        .DATA_TBYTES(DATA_TBYTES)
    ) selectmap_timing_inst (
        .clk          (aclk),
        .rst          (soft_rst),
        .en           (cfg_oe),
        .busy         (busy),
        .step_en      (step_en),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tkeep (s_axis_tkeep),
        .s_axis_tready(s_axis_tready),
        .cfg_clk_en   (clk_en),
        .cfg_data     (cfg_data),
        .cfg_cs_n     (cfg_cs_n)
    );

endmodule

// verilog_format: off
`resetall
// verilog_format: on
