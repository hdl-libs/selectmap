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
// Module Name   : selectmap_ui
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

module selectmap_ui #(
    parameter integer C_APB_DATA_WIDTH = 32,
    parameter integer C_APB_ADDR_WIDTH = 16
) (
    input  wire                      clk,         //
    input  wire                      rstn,        //
    //
    input  wire [C_APB_ADDR_WIDTH:0] s_paddr,
    input  wire                      s_psel,
    input  wire                      s_penable,
    input  wire                      s_pwrite,
    input  wire [C_APB_DATA_WIDTH:0] s_pwdata,
    output wire                      s_pready,
    output wire [C_APB_DATA_WIDTH:0] s_prdata,
    output wire                      s_pslverr,
    //
    output reg                       soft_rst,    // software reset
    output reg                       baud_load,   // baud rate load
    output reg  [              31:0] baud_div,    // baud rate divider
    output wire                      cfg_oe,      // selectmap configuration enable
    input  wire                      busy,        // selectmap configuration busy
    input  wire                      fifo_empty,  // data fifo empty
    //
    input  wire                      cfg_done,
    input  wire                      cfg_init_n,
    output wire                      cfg_rst_n,
    output wire                      cfg_prog_n,
    output wire                      cfg_rw_n,
    output wire [               2:0] cfg_bm
);

    wire                        wr_active;
    wire                        rd_active;

    wire                        user_reg_rreq;
    wire                        user_reg_wreq;
    wire [C_APB_ADDR_WIDTH-1:0] user_reg_raddr;
    reg  [C_APB_DATA_WIDTH-1:0] user_reg_rdata;
    wire [C_APB_ADDR_WIDTH-1:0] user_reg_waddr;
    wire [C_APB_DATA_WIDTH-1:0] user_reg_wdata;

    user_register_interface #(
        .C_APB_DATA_WIDTH(C_APB_DATA_WIDTH),
        .C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH)
    ) user_register_interface_inst (
        .clk           (clk),
        .s_pwrite      (s_pwrite),
        .s_psel        (s_psel),
        .s_penable     (s_penable),
        .s_paddr       (s_paddr),
        .s_pready      (s_pready),
        .s_prdata      (s_prdata),
        .s_pwdata      (s_pwdata),
        .s_pslverr     (s_pslverr),
        .user_reg_rreq (user_reg_rreq),
        .user_reg_wreq (user_reg_wreq),
        .user_reg_raddr(user_reg_raddr),
        .user_reg_waddr(user_reg_waddr),
        .user_reg_wdata(user_reg_wdata),
        .user_reg_rdata(user_reg_rdata)
    );

    // {cfg_rst_n, cfg_prog_n, cfg_rw_n, cfg_bm, cfg_oe}
    reg [6:0] cfg_reg = {1'b0, 1'b1, 1'b0, 3'b001, 1'b0};

    always @(posedge clk) begin
        if (!rstn) begin
            soft_rst <= 1'b1;
        end else begin
            if ((user_reg_wreq == 1'b1) && (user_reg_waddr == 16'h0010)) begin
                soft_rst <= |user_reg_wdata;
            end else begin
                soft_rst <= 1'b0;
            end
        end
    end

    // ***********************************************************************************
    // read
    // ***********************************************************************************
    always @(posedge clk) begin
        if (!rstn) begin
            user_reg_rdata <= 0;
        end else begin
            user_reg_rdata <= 0;
            if (user_reg_rreq) begin
                case (user_reg_raddr)
                    16'h0000: user_reg_rdata <= 32'hF7DEC7A5;
                    16'h0004: user_reg_rdata <= {fifo_empty, cfg_done, cfg_init_n, busy, cfg_reg};
                    16'h0008: user_reg_rdata <= baud_div;
                    16'h000C: user_reg_rdata <= baud_load;
                    16'h0010: user_reg_rdata <= soft_rst;
                    default:  user_reg_rdata <= 32'hdeadbeef;
                endcase
            end
        end
    end

    assign {cfg_rst_n, cfg_prog_n, cfg_rw_n, cfg_bm, cfg_oe} = cfg_reg[6:0];
    always @(posedge clk) begin
        if (!rstn) begin
            cfg_reg <= {1'b0, 1'b1, 1'b0, 3'b001, 1'b0};
        end else begin
            if ((user_reg_wreq == 1'b1) && (user_reg_waddr == 16'h0004)) begin
                cfg_reg <= user_reg_wdata[6:0];
            end else begin
                cfg_reg <= cfg_reg;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            baud_div <= 32'd1;
        end else begin
            if ((user_reg_wreq == 1'b1) && (user_reg_waddr == 16'h0008)) begin
                if (baud_div > 1) begin
                    baud_div <= 32'd1;
                end else begin
                    baud_div <= 32'd1;
                end
            end else begin
                baud_div <= baud_div;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            baud_load <= 1'b0;
        end else begin
            if ((user_reg_wreq == 1'b1) && (user_reg_waddr == 16'h000C)) begin
                baud_load <= |user_reg_wdata;
            end else begin
                baud_load <= 1'b0;
            end
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
