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
// Module Name   : user_register_interface
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

module user_register_interface #(
    parameter integer C_APB_DATA_WIDTH = 32,
    parameter integer C_APB_ADDR_WIDTH = 16
) (
    input wire clk,

    input  wire                        s_pwrite,
    input  wire                        s_psel,
    input  wire                        s_penable,
    input  wire [C_APB_ADDR_WIDTH-1:0] s_paddr,
    output wire                        s_pready,
    output wire [C_APB_DATA_WIDTH-1:0] s_prdata,
    input  wire [C_APB_DATA_WIDTH-1:0] s_pwdata,
    output wire                        s_pslverr,

    // Additional signals for internal use
    output wire                        user_reg_rreq,
    output wire                        user_reg_wreq,
    output wire [C_APB_ADDR_WIDTH-1:0] user_reg_raddr,
    output wire [C_APB_ADDR_WIDTH-1:0] user_reg_waddr,
    output wire [C_APB_DATA_WIDTH-1:0] user_reg_wdata,
    input  wire [C_APB_DATA_WIDTH-1:0] user_reg_rdata
);

    reg user_reg_rack;
    reg user_reg_wack;

    assign user_reg_rreq  = ~s_pwrite & s_psel & s_penable;
    assign user_reg_wreq  = s_pwrite & s_psel & s_penable;
    assign s_pready       = user_reg_rack | user_reg_wack;
    assign user_reg_raddr = s_paddr;
    assign user_reg_waddr = s_paddr;
    assign user_reg_wdata = s_pwdata;
    assign s_prdata       = user_reg_rdata;
    assign s_pslverr      = 1'b0;

    always @(posedge clk) begin
        user_reg_rack <= user_reg_rreq & ~user_reg_rack;
        user_reg_wack <= user_reg_wreq & ~user_reg_wack;
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
