`timescale 1ns / 1ps

module tb_spi_hardware_system;

    reg        clk;
    reg        rst;
    reg        start;
    reg  [1:0] slave_select;
    reg  [7:0] master_tx;
    wire [7:0] master_rx;
    wire       busy;
    wire       done;

    wire       BOARD_SCLK;
    wire       BOARD_MOSI;
    reg        BOARD_MISO;
    wire       FLASH_CS_N;
    wire       TEMP_CS_N;
    wire       OLED_CS_N;
    wire       OLED_DC;

    reg  [7:0] flash_write_data;
    wire [7:0] flash_read_data;
    wire [7:0] temperature_value;
    reg  [7:0] oled_pixel_data;
    reg        oled_data_cmd_sel;

    spi_hardware_system uut (
        .clk                 (clk),
        .rst                 (rst),
        .start               (start),
        .slave_select        (slave_select),
        .master_tx           (master_tx),
        .master_rx           (master_rx),
        .busy                (busy),
        .done                (done),
        .BOARD_SCLK          (BOARD_SCLK),
        .BOARD_MOSI          (BOARD_MOSI),
        .BOARD_MISO          (BOARD_MISO),
        .FLASH_CS_N          (FLASH_CS_N),
        .TEMP_CS_N           (TEMP_CS_N),
        .OLED_CS_N           (OLED_CS_N),
        .OLED_DC             (OLED_DC),
        .flash_write_data    (flash_write_data),
        .flash_read_data     (flash_read_data),
        .temperature_value   (temperature_value),
        .oled_pixel_data     (oled_pixel_data),
        .oled_data_cmd_sel   (oled_data_cmd_sel)
    );

    // 100MHz clock generation
    always #5 clk = ~clk;

    initial begin
        // --- 1. System Reset & Initialization ---
        clk = 0;
        start = 0;
        slave_select = 2'b00;
        master_tx = 8'h00;
        BOARD_MISO = 0;
        flash_write_data = 8'h00;
        oled_pixel_data = 8'h00;
        oled_data_cmd_sel = 0;

        rst = 1; #40;
        rst = 0; #40;

        // --- Test Case 1: Flash Memory ---
        slave_select      = 2'b00;
        master_tx         = 8'hA5;         
        flash_write_data  = 8'hA5;   
        BOARD_MISO        = 1;          
        
        #20; start = 1; 
        #20; start = 0;   
        #5000;                          

        // --- Test Case 2: Temperature Sensor ---
        slave_select      = 2'b01;
        master_tx         = 8'h9C;         
        BOARD_MISO        = 0;          
        
        #20; start = 1; 
        #20; start = 0;   
        #5000;                          

        // --- Test Case 3: OLED Command ---
        slave_select      = 2'b10;
        oled_data_cmd_sel = 0;     
        master_tx         = 8'h3F;         
        BOARD_MISO        = 0;          
        
        #20; start = 1; 
        #20; start = 0;   
        #5000;                          

        // --- Test Case 4: OLED Pixel Data ---
        slave_select      = 2'b10;
        oled_data_cmd_sel = 1;     
        oled_pixel_data   = 8'hFF;    
        master_tx         = 8'hFF;
        BOARD_MISO        = 0;          
        
        #20; start = 1; 
        #20; start = 0;   
        #5000;                          

        $finish;
    end

endmodule