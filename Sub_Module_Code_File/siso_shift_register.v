`timescale 1ns / 1ps
module siso_shift_register(
     input clk,
     input rst,
     input load,
     input [7:0]p_in,
     input shift_en,
     input s_in,
     output reg s_out,
     output reg [7:0]p_out
    );
    
reg [7:0]r_reg;

always@(posedge clk or posedge rst) begin
        if(rst)
           r_reg <= 7'b0;
        else if(load)
           r_reg <= p_in;
        else if(shift_en)
           r_reg <= {r_reg[6:0] , s_in};
end

always@(*) begin
     s_out <= r_reg[7];
     p_out <= r_reg;
     
end
endmodule
