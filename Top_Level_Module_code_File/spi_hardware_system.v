`timescale 1ns / 1ps
module spi_hardware_system (
    input  wire        clk,          
    input  wire        rst,        
    input  wire        start,        
    input  wire [1:0]  slave_select, 
    input  wire [7:0]  master_tx,    
    output wire [7:0]  master_rx,    
    output wire        busy,
    output wire        done,

    output wire        BOARD_SCLK,
    output wire        BOARD_MOSI,
    input  wire        BOARD_MISO,
    output wire        FLASH_CS_N,
    output wire        TEMP_CS_N,
    output wire        OLED_CS_N,
    output reg         OLED_DC,         

    input  wire [7:0]  flash_write_data,
    output wire [7:0]  flash_read_data,
    output wire [7:0]  temperature_value,
    input  wire [7:0]  oled_pixel_data,
    input  wire        oled_data_cmd_sel 
);

    wire [2:0] internal_cs;
    
    
    reg [7:0] flash_read_reg;
    reg [7:0] temp_read_reg;

    
    assign flash_read_data   = flash_read_reg;
    assign temperature_value = temp_read_reg;

    assign FLASH_CS_N = internal_cs[0]; 
    assign TEMP_CS_N  = internal_cs[1]; 
    assign OLED_CS_N  = internal_cs[2]; 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            OLED_DC <= 1'b0;
        end else if (slave_select == 2'b10) begin
            OLED_DC <= oled_data_cmd_sel;
        end
    end

   
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            flash_read_reg   <= 8'h00;
            temp_read_reg    <= 8'h00;
        end else if (done) begin
            case (slave_select)
                2'b00: flash_read_reg <= master_rx;
                2'b01: temp_read_reg  <= master_rx;
            endcase
        end
    end

    spi_three_slaves_top u_spi_infrastructure (
        .clk          (clk),
        .rst          (rst),
        .start        (start),
        .slave_select (slave_select),
        .master_tx    (master_tx),
        .master_rx    (master_rx),
        .busy         (busy),
        .done         (done),

        .sclk_bus     (BOARD_SCLK),
        .mosi_bus     (BOARD_MOSI),
        .miso_bus     (BOARD_MISO),
        .cs_bus       (internal_cs),

        .slave0_tx    (flash_write_data),
        .slave0_rx    (), // Disconnected here; handled cleanly by master_rx latching

        .slave1_tx    (8'h00),             
        .slave1_rx    (), // Disconnected here; handled cleanly by master_rx latching

        .slave2_tx    (oled_pixel_data), // Routed input pixel data to the OLED slave            
        .slave2_rx    ()                   
    );

endmodule