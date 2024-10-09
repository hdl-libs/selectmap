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
// Module Name   : tx_clk_gen
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

module tx_clk_gen #(
    parameter CPOL = 1'b1,
    parameter CPHA = 1'b1
) (
    input  wire        clk,        // clock
    input  wire        rst,        // active high reset
    input  wire        en,         //
    input  wire        baud_load,  //
    input  wire [31:0] baud_div,   //
    output reg         shift_en,   //
    output wire        sync_clk    //
);
    reg        en_reg;
    reg [31:0] baud_div_reg;

    // ***********************************************************************************
    // config register
    // ***********************************************************************************
    always @(posedge clk) begin
        if (rst) begin
            baud_div_reg <= 1;
        end else if (baud_load) begin
            baud_div_reg <= baud_div;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            en_reg <= 1'b0;
        end else begin
            if (en) begin
                en_reg <= 1'b1;
            end else if (CPOL == sync_clk) begin
                en_reg <= 1'b0;
            end
        end
    end

    // ***********************************************************************************
    // internal clock for transmit
    // ***********************************************************************************
    reg [31:0] counter;
    reg [ 3:0] count16;
    reg        ce_16;
    reg        int_sync_clk = 1'b0;
    // baud divider counter
    always @(posedge clk) begin
        if (rst | ~(en | en_reg)) begin
            counter <= 16'b0;
        end else if (counter >= baud_div_reg) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

    // clk divider output
    always @(posedge clk) begin
        if (rst) begin
            int_sync_clk <= 1'b0;
        end else if (counter > baud_div_reg[31:1]) begin
            int_sync_clk <= 1'b1;
        end else begin
            int_sync_clk <= 1'b0;
        end
    end

    // ***********************************************************************************
    // tx enable strobe
    // ***********************************************************************************
    reg [1:0] sync_clk_dd;
    always @(posedge clk) begin
        if (rst || !en_reg) begin
            sync_clk_dd <= 2'b00;
        end else begin
            sync_clk_dd <= {sync_clk_dd[0], int_sync_clk};
        end
    end

    always @(posedge clk) begin
        if (rst || !en_reg) begin
            shift_en <= 1'b0;
        end else begin
            if ((sync_clk_dd[0] & (~sync_clk_dd[1]))) begin
                shift_en <= 1'b1;
            end else begin
                shift_en <= 1'b0;
            end
        end
    end

    // ***********************************************************************************
    // sync clk for output
    // ***********************************************************************************
    reg [1:0] sync_clk_d = {2{CPOL}};
    generate
        always @(posedge clk) begin
            if (rst || !en_reg) begin
                sync_clk_d <= {2{CPOL}};
            end else if (^sync_clk_dd) begin
                sync_clk_d <= {sync_clk_d[0], int_sync_clk ^ CPOL};
            end
        end
        if (CPHA == 1'b0) begin : g_cpha0
            assign sync_clk = sync_clk_d[1];
        end else begin : g_cpha1
            assign sync_clk = sync_clk_d[0];
        end
    endgenerate

endmodule

// verilog_format: off
`resetall
// verilog_format: on
