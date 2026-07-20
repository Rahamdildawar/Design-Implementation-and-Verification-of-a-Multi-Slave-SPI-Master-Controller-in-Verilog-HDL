`timescale 1ns / 1ps
module tb_siso_shift_register();

reg clk;
reg rst;
reg load;
reg shift_en;
reg s_in;
reg [7:0]p_in;

wire [7:0]p_out;
wire s_out;

siso_shift_register uut(
       .clk(clk),
       .rst(rst),
       .load(load),
       .shift_en(shift_en),
       .s_in(s_in),
       .p_in(p_in),
       .p_out(p_out),
       .s_out(s_out)
);

always #5 clk = ~clk;

initial begin

clk = 0;
rst = 1;
load = 0;
shift_en = 0;
s_in = 0;
p_in = 0;

#10;

rst = 0;

load = 1;
shift_en = 0;
s_in = 1'b1;
p_in = 8'b11001100;

#50;

load = 0;
shift_en = 1;
s_in = 1'b1;
p_in = 8'b11001100;

#50;



$finish;
end
endmodule
