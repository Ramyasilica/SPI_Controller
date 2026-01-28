`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2025 04:31:04 PM
// Design Name: 
// Module Name: spi_tb
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
module spi_tb;


    reg clk = 0;
    reg reset = 1;
    reg start = 0;

    wire sclk, mosi, miso, cs, done;
    reg  [7:0] m_tx_data = 8'hA5;  // MASTER sends A5
    reg  [7:0] s_tx_data = 8'h3C;  // SLAVE sends 3C

    wire [7:0] m_rx_data;
    wire [7:0] s_rx_data;

    // System clock = 10 ns (100 MHz)
    always #5 clk = ~clk;

    // Instantiate Master
    spi_master M1 (
        .clk(clk), .reset(reset), .start(start),
        .m_tx_data(m_tx_data), .miso(miso),
        .m_rx_data(m_rx_data), .sclk(sclk),
        .mosi(mosi), .cs(cs), .done(done)
    );

    // Instantiate Slave (corrected)
    spi_slave S1 (
        .clk(clk), .reset(reset),
        .sclk(sclk), .cs(cs), .mosi(mosi),
        .s_tx_data(s_tx_data),
        .s_rx_data(s_rx_data), .miso(miso)
    );

    initial begin
        // RESET phase
        #20 reset = 0;

        // Start transfer @ 30ns
        #10 start = 1;
        #10 start = 0;

        // Simulation ends at 400ns
        #400 $finish;
    end

    // -------- Monitor signals --------
    initial begin
        $display("Time(ns) | CS | SCLK | MOSI | MISO | M_RX | S_RX | DONE");
        $monitor("%8t |  %b  |  %b  |  %b  |  %b  | %2h  | %2h  |  %b",
                  $time, cs, sclk, mosi, miso, m_rx_data, s_rx_data, done);
    end

endmodule

