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
// Module Name   : selectmap_timing
// ---------------------------------------------------------------------------------------
// Revision      : 1.0
// Description   : File Created
// ---------------------------------------------------------------------------------------
// Synthesizable : Yes
// Clock Domains : clk
// Reset Strategy: sync reset, high active
// -FHEADER-------------------------------------------------------------------------------

// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module selectmap_timing #(
    parameter DATA_TBYTES = 8
) (
    // Clock Signals
    input  wire                       clk,
    input  wire                       rst,
    // Control Signals
    input  wire                       en,
    output reg                        busy,
    input  wire                       step_en,
    // Data Input Signals
    input  wire [(DATA_TBYTES*8-1):0] s_axis_tdata,
    input  wire                       s_axis_tvalid,
    input  wire                       s_axis_tkeep,
    output reg                        s_axis_tready,
    // SelectMap Signals
    output reg                        cfg_clk_en,
    output reg  [(DATA_TBYTES*8-1):0] cfg_data,
    output reg                        cfg_cs_n
);

    // verilog_format: off
    localparam FSM_IDLE        = 8'b00000000;
    localparam FSM_PRE_WAIT    = 8'b00000001;
    localparam FSM_WAIT_CONFIG = 8'b00000010;
    localparam FSM_CONFIG      = 8'b00000100;
    // verilog_format: on

    reg  [7:0] cstate;
    reg  [7:0] nstate;

    reg  [7:0] delay_cnt;
    wire       delay_done;

    always @(posedge clk) begin
        if (rst) begin
            cstate <= FSM_IDLE;
        end else begin
            cstate <= nstate;
        end
    end

    always @(*) begin
        if (rst) begin
            nstate = FSM_IDLE;
        end else begin
            if (!en) begin
                nstate = FSM_IDLE;
            end else begin
                case (cstate)
                    FSM_IDLE: begin
                        if (en) begin
                            nstate = FSM_PRE_WAIT;
                        end else begin
                            nstate = FSM_IDLE;
                        end
                    end
                    FSM_PRE_WAIT: begin
                        if (step_en & delay_done) begin
                            nstate = FSM_WAIT_CONFIG;
                        end else begin
                            nstate = FSM_PRE_WAIT;
                        end
                    end
                    FSM_WAIT_CONFIG: begin
                        if (step_en & (s_axis_tvalid & s_axis_tkeep)) begin
                            nstate = FSM_CONFIG;
                        end else begin
                            nstate = FSM_WAIT_CONFIG;
                        end
                    end
                    FSM_CONFIG: begin
                        if (step_en & ~(s_axis_tvalid & s_axis_tkeep)) begin
                            nstate = FSM_WAIT_CONFIG;
                        end else begin
                            nstate = FSM_CONFIG;
                        end
                    end
                    default: nstate = FSM_IDLE;
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            s_axis_tready <= 1'b0;
        end else begin
            if (step_en) s_axis_tready <= (nstate == FSM_CONFIG);
            else s_axis_tready <= s_axis_tvalid & ~s_axis_tkeep;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            cfg_data <= 0;
        end else begin
            if (step_en) begin
                case (nstate)
                    FSM_CONFIG: cfg_data <= s_axis_tdata;
                    default:    cfg_data <= s_axis_tvalid & ~s_axis_tkeep;
                endcase
            end else cfg_data <= cfg_data;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            cfg_clk_en <= 1'b0;
        end else begin
            case (nstate)
                FSM_IDLE: cfg_clk_en <= 1'b0;
                default:  cfg_clk_en <= 1'b1;
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            cfg_cs_n <= 1'b1;
        end else begin
            case (nstate)
                FSM_CONFIG: cfg_cs_n <= 1'b0;
                default:    cfg_cs_n <= 1'b1;
            endcase
        end
    end

    assign delay_done = delay_cnt[7];

    always @(posedge clk) begin
        if (rst) begin
            delay_cnt <= 0;
        end else begin
            case (nstate)
                FSM_PRE_WAIT: begin
                    if (step_en) begin
                        delay_cnt <= delay_cnt + 1;
                    end else begin
                        delay_cnt <= delay_cnt;
                    end
                end
                default: begin
                    delay_cnt <= 0;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            busy <= 1'b1;
        end else begin
            case (nstate)
                FSM_IDLE: busy <= 1'b0;
                default:  busy <= 1'b1;
            endcase
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
