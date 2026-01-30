`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2025 04:20:28 PM
// Design Name: 
// Module Name: spi_master
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



module spi_master (
 
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire [7:0] m_tx_data,
    input  wire       miso,
    output reg  [7:0] m_rx_data,
    output reg        sclk,
    output reg        mosi,
    output reg        cs,
    output reg        done
);

    reg [2:0] bit_idx;
    reg [7:0] tx_shift;
    reg [7:0] rx_shift;
    reg busy;
    reg sclk_prev;

    // SPI Master Logic
    always @(posedge clk) begin
        if (reset) begin
            cs   <= 1;
            sclk <= 0;
            mosi <= 0;
            done <= 0;
            busy <= 0;
            bit_idx <= 7;
            tx_shift <= 0;
            rx_shift <= 0;
            m_rx_data <= 0;
            sclk_prev <= 0;
        end 
        else begin
            sclk_prev <= sclk;
            done <= 0;

            //START
            if (start && !busy) begin
                busy <= 1;
                cs <= 0;
                sclk <= 0;
                bit_idx <= 7;
                tx_shift <= m_tx_data;
                rx_shift <= 0;
                mosi <= m_tx_data[7];
            end

            // During Transfer
            if (busy) begin
                sclk <= ~sclk;   

                // Rising edge → sample MISO
                if (sclk_prev == 0 && sclk == 1)
                    rx_shift[bit_idx] <= miso;

                // Falling edge → shift MOSI
                if (sclk_prev == 1 && sclk == 0) begin
                    if (bit_idx != 0) begin
                        bit_idx <= bit_idx - 1;
                        mosi <= tx_shift[bit_idx - 1];
                    end
                end

                // END
                if (bit_idx == 0 && sclk_prev == 0 && sclk == 1) begin
                    busy <= 0;
                    cs <= 1;
                    m_rx_data <= rx_shift;
                    done <= 1;
                    mosi <= 0;
                end
            end
        end
    end

endmodule




`timescale 1ns/1ps
//SPI SLAVE 
module spi_slave (
    input  wire       clk,
    input  wire       reset,
    input  wire       sclk,
    input  wire       cs,
    input  wire       mosi,
    input  wire [7:0] s_tx_data,
    output reg  [7:0] s_rx_data,
    output reg        miso
);

    reg [2:0] bit_idx_s;
    reg [7:0] shift_tx_s;
    reg [7:0] shift_rx_s;
    reg sclk_prev_s;
    reg cs_prev;

    always @(posedge clk) begin
        if (reset) begin
            bit_idx_s   <= 7;
            shift_tx_s  <= 0;
            shift_rx_s  <= 0;
            s_rx_data   <= 0;
            miso        <= 0;
            sclk_prev_s <= 0;
            cs_prev     <= 1;
        end else begin
            sclk_prev_s <= sclk;
            cs_prev <= cs;
            if (cs_prev == 1 && cs == 0) begin
                bit_idx_s  <= 7;
                shift_tx_s <= s_tx_data;
                shift_rx_s <= 0;
                miso <= s_tx_data[7]; // send MSB first
            end

            if (cs == 0) begin
                // Rising edge → sample MOSI
                if (sclk_prev_s == 0 && sclk == 1) begin
                    shift_rx_s[bit_idx_s] <= mosi;
                end

                // Falling edge → shift MISO & decrement bit counter
                if (sclk_prev_s == 1 && sclk == 0) begin
                    if (bit_idx_s != 0) begin
                        bit_idx_s <= bit_idx_s - 1;
                        miso <= shift_tx_s[bit_idx_s - 1];
                    end else begin
                        bit_idx_s <= 0;
                        miso <= 0;
                    end
                end
            end else begin
                // CS idle → latch received byte
                if (cs_prev == 0 && cs == 1) begin
                    s_rx_data <= shift_rx_s;
                end
                miso <= 0; 
            end
        end
    end
endmodule

