`timescale 1ns / 1ps
module buad_generator(
       input clk,
       input rst,
       input enable,
       output reg tick
    );
    
reg [3:0]count;

always@(posedge clk or posedge rst) begin
     count <= 4'b0;
     if(rst) begin
        count <= 4'b0;
        tick <= 1'b0;
     end
     
     else if(enable) begin
          if(count == 4'b1001) begin
             count <= 4'b0;
             tick <= 1'b1;
          end
          
          else begin
             count <= count + 1;
             tick <= 1'b0;
          end
             
     end
     
     else
        begin
             count  <= 1'b0;
             tick <= 1'b0;
        end
end
endmodule
