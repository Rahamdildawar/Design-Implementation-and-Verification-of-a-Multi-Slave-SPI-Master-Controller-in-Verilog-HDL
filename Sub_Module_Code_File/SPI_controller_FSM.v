`timescale 1ns / 1ps
module SPI_controller_FSM(
      input clk,
      input rst,
      input start,
      input tick,
      input [1:0]slave_sel,
      output reg baud_enable,
      output reg load_en,
      output reg shift_en,
      output reg [2:0]cs, //chip selection
      output reg sclk_out,
      output reg busy,
      output reg done
    );
    
parameter idle = 2'b00;
parameter load = 2'b01;
parameter transfer = 2'b10;
parameter Done = 2'b11;

reg [1:0]current_state , next_state;
reg [3:0]edge_counter;
reg sclk_track;

always@(posedge clk or posedge rst) begin
     if(rst)
        current_state <= idle;
     else
        current_state <= next_state;
end

always@(*) begin
      case(current_state)
           idle : begin
               if(start)
                  next_state = load;
               else
                  next_state = idle;
           end
           
           load : next_state = transfer;
           
           transfer : begin
                 if(edge_counter == 4'b1111 && tick == 1'b1)
                         next_state = Done;
           end
           
           Done : next_state = idle;
           default next_state = idle;
      endcase
end

always@(posedge clk or posedge rst) begin
              if(rst) begin
                  cs <= 3'b111;
                  busy <= 1'b0;
                  done <= 1'b0;
                  sclk_track <= 1'b0;
                  baud_enable <= 1'b0;
                  edge_counter <= 4'd0;
                  load_en <= 1'b0;
                  shift_en <= 1'b0;
              end
              
              else begin
                  load_en <= 1'b0;
                  shift_en <= 1'b0;
                  done <= 1'b0;
                  case(current_state)
                       idle : begin
                           cs <= 3'b111;
                           busy <= 1'b0;
                           sclk_track <= 1'b0;
                           baud_enable <= 1'b0;
                           edge_counter <= 4'b0;
                       end
                       
                       load : begin
                           busy <= 1'b1;
                           load_en <= 1'b1;
                           case(slave_sel)
                               2'b00 : cs <= 3'b110;
                               2'b01 : cs <= 3'b101;
                               2'b10 : cs <= 3'b011;
                               default cs <= 3'b111;
                           endcase
                       end
                       
                       transfer : begin
                              baud_enable <= 1'b1;
                              
                              if (tick) begin
                                    sclk_track   <= ~sclk_track; 
                                    edge_counter <= edge_counter + 1;
                              
                                    if (sclk_track == 1'b1) begin
                                           shift_en <= 1'b1;
                                    end
                              end
                       end
                       
                       Done : begin
                              cs <= 3'b111;
                              baud_enable <= 1'b0; 
                              done <= 1'b1; 
                              busy <= 1'b0;
                       end
                  endcase
              end
end

always @(*) begin
        if (current_state == transfer)
            sclk_out = sclk_track;
        else
            sclk_out = 1'b0; 
end
endmodule
