`timescale 1ns / 1ps
module spi_master_multi_top(
       input clk,
       input rst,
       input [7:0]tx_data,
       input start,
       input [1:0]slave_sel,
       input [7:0]rx_data,
       input miso,
       
       output busy,
       output done,
       output sclk,
       output mosi,
       output [2:0]cs
    );
    
wire buad_enable; 
wire buad_tick;
wire shift_en;
wire load_en;

buad_generator Buad_gen(
        .clk(clk),
        .rst(rst),
        .enable(buad_enable),
        .tick(buad_tick)
);

siso_shift_register shift_register(
          .clk(clk),
          .rst(rst),
          .load(load_en),
          .p_in(tx_data),
          .shift_en(shift_en),
          .s_in(miso),
          .s_out(mosi),
          .p_out(rx_data)
);

SPI_controller_FSM controller(
          .clk(clk),
          .rst(rst),
          .start(start),
          .tick(buad_tick),
          .slave_sel(slave_sel),
          .baud_enable(buad_enable),
          .load_en(load_en),
          .shift_en(shift_en),
          .cs(cs),
          .sclk_out(sclk),
          .busy(busy),
          .done(done)
);
endmodule
