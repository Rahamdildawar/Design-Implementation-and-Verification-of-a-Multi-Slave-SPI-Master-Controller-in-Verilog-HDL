`timescale 1ns / 1ps
module tb_SPI_controller_FSM();

reg clk;
reg rst;
reg start;
reg tick;
reg [1:0]slave_sel;

wire baud_enable;
wire load_en;
wire shift_en;
wire [2:0]cs;
wire sclk_out;
wire busy;
wire done;

SPI_controller_FSM uut(
       .clk(clk),
       .rst(rst),
       .start(start),
       .slave_sel(slave_sel),
       .baud_enable(baud_enable),
       .load_en(load_en),
       .shift_en(shift_en),
       .cs(cs),
       .sclk_out(sclk_out),
       .busy(busy),
       .done(done)
);

always #5 clk = ~clk;

initial begin

clk = 0;
rst = 1;
start = 0;
tick = 0;
slave_sel = 0;

#10;

rst = 0;

start = 1'b1;
tick = 1'b0;
slave_sel = 2'b00;

#40;

start = 1'b1;
tick = 1'b1;
slave_sel = 2'b00;

#40;

start = 1'b1;
tick = 1'b0;
slave_sel = 2'b01;

#40;

start = 1'b1;
tick = 1'b1;
slave_sel = 2'b01;

#40;

start = 1'b1;
tick = 1'b0;
slave_sel = 2'b10;

#40;

start = 1'b1;
tick = 1'b1;
slave_sel = 2'b10;

#40;

$finish;
end
endmodule
