`timescale 1ns / 1ps
module tb_buad_generator();

reg clk;
reg rst;
reg enable;

wire tick;

buad_generator uut(
      .clk(clk),
      .rst(rst),
      .enable(enable),
      .tick(tick)
);

always #5 clk = ~clk;

initial begin

clk = 0;
rst = 1;
enable = 0;

#10;

rst = 0;
enable = 1;

#90;

enable = 0;

#90;
$finish;
end
endmodule
