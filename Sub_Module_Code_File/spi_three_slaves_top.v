`timescale 1ns / 1ps
module spi_three_slaves_top (
    input  wire       clk,           
    input  wire       rst,         
    input  wire       start,         
    input  wire [1:0] slave_select, 
    input  wire [7:0] master_tx,     
    output wire [7:0] master_rx,     
    output wire       busy,
    output wire       done,
    input  wire [7:0] slave0_tx,    
    input  wire [7:0] slave1_tx,     
    input  wire [7:0] slave2_tx,    
    output wire [7:0] slave0_rx,
    output wire [7:0] slave1_rx,
    output wire [7:0] slave2_rx,

    output wire       sclk_bus,    
    output wire       mosi_bus,    
    input  wire       miso_bus, 
    output wire [2:0] cs_bus    
);

    
    wire miso_s0;
    wire miso_s1;
    wire miso_s2;
    wire internal_miso_mux;

    spi_master_multi_top u_master (
        .clk        (clk),
        .rst        (rst),
        .tx_data    (master_tx),
        .start      (start),
        .slave_sel  (slave_select),  
        .rx_data    (master_rx),
        .busy       (busy),
        .done       (done),
        .sclk       (sclk_bus),
        .mosi       (mosi_bus),
        .miso       (internal_miso_mux), 
        .cs         (cs_bus)      
    );

    spi_slave u_slave_chip0 (
        .sclk    (sclk_bus),        
        .cs      (cs_bus[0]),    
        .mosi    (mosi_bus),        
        .miso    (miso_s0),         
        .tx_data (slave0_tx),
        .rx_data (slave0_rx)
    );

    spi_slave u_slave_chip1 (
        .sclk    (sclk_bus),        
        .cs      (cs_bus[1]),     
        .mosi    (mosi_bus),        
        .miso    (miso_s1),        
        .tx_data (slave1_tx),
        .rx_data (slave1_rx)
    );

    spi_slave u_slave_chip2 (
        .sclk    (sclk_bus),        
        .cs      (cs_bus[2]),    
        .mosi    (mosi_bus),       
        .miso    (miso_s2),         
        .tx_data (slave2_tx),
        .rx_data (slave2_rx)
    );


    assign internal_miso_mux = (slave_select == 2'b00) ? miso_s0 :
                               (slave_select == 2'b01) ? miso_s1 :
                               (slave_select == 2'b10) ? miso_s2 : 1'b0;

endmodule