`timescale 1ns / 1ps
module spi_slave(
     input sclk,
     input cs,
     input mosi,
     input miso,
     input [7:0]tx_data,
     output reg [7:0]rx_data
    );
    
reg [7:0]shift_register;
reg [2:0]bit_counter;

assign miso = (cs == 1'b0) ? shift_register[7] : 1'bz;

always@(posedge sclk or posedge cs) begin
    if(cs) begin
         shift_register <= tx_data;
         bit_counter <= 3'b0;
    end
    
    else begin
         shift_register <= {shift_register[6:0] , mosi};
         if(bit_counter == 3'b111) begin
              bit_counter <= 3'b0;
              rx_data <= {shift_register[7] , mosi};
         end
         
         else begin 
              bit_counter <= bit_counter + 1;
         end
    end
           
end
endmodule
