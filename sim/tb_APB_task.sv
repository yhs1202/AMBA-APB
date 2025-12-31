`timescale 1ns/1ps

module tb_APB_task ();
    // Global Signals
    logic PCLK;
    logic PRESET;

    // APB Interface Signals
    logic [3:0] PADDR;
    logic PWRITE;
    // logic PSEL;
    logic PENABLE;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic PREADY;

    // Slave Select Signals
    logic PSEL0;
    logic PSEL1;
    logic PSEL2;
    logic PSEL3;
    logic [31:0] PRDATA0;
    logic [31:0] PRDATA1;
    logic [31:0] PRDATA2;
    logic [31:0] PRDATA3;
    logic PREADY0;
    logic PREADY1;
    logic PREADY2;
    logic PREADY3;

    // Internal Interface Signals
    logic transfer;
    logic write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic ready;


    APB_Manager dut_manager (.*);

    APB_slave dut_slave_0 (
        .*,
        .PSEL   (PSEL0),
        .PRDATA (PRDATA0),
        .PREADY (PREADY0)
    );

    APB_slave dut_slave_1 (
        .*,
        .PSEL   (PSEL1),
        .PRDATA (PRDATA1),
        .PREADY (PREADY1)
    );

    APB_slave dut_slave_2 (
        .*,
        .PSEL   (PSEL2),
        .PRDATA (PRDATA2),
        .PREADY (PREADY2)
    );

    APB_slave dut_slave_3 (
        .*,
        .PSEL   (PSEL3),
        .PRDATA (PRDATA3),
        .PREADY (PREADY3)
    );

    always #5 PCLK = ~PCLK;

    initial begin
        #0  PCLK = 0;
            PRESET = 1;
        #10 PRESET = 0;
    end

    task automatic apbMasterWrite(logic [31:0] addr_, logic [31:0] data);
        transfer = 1'b1; write = 1'b1; addr = addr_; wdata = data;
        @(posedge PCLK);
        transfer = 1'b0;
        @(posedge PCLK);
        wait (ready == 1'b1);
        @(posedge PCLK);
        
    endtask //automatic

    task automatic apbMasterRead(logic [31:0] addr_);
        transfer = 1'b1; write = 1'b0; addr = addr_;
        @(posedge PCLK);
        transfer = 1'b0;
        @(posedge PCLK);
        wait (ready == 1'b1);
        @(posedge PCLK);

    endtask //automatic

    initial begin

        repeat (3) @(posedge PCLK);

        apbMasterWrite(32'h1000_0000, 32'h12345678);
        apbMasterWrite(32'h1000_1000, 32'hDEAD_BEEF);
        apbMasterWrite(32'h1000_2000, 32'hCAFEBABE);
        apbMasterWrite(32'h1000_3000, 32'h87654321);

        apbMasterRead(32'h1000_0000);
        apbMasterRead(32'h1000_1000);
        apbMasterRead(32'h1000_2000);
        apbMasterRead(32'h1000_3000);
    end
/*
    task automatic abpRead(logic [3:0] addr);
        repeat (3) @(posedge PCLK);
        PSEL = 1;       // SETUP
        PENABLE = 0;
        PWRITE = 0;
        PADDR = addr;
        @(posedge PCLK);
        PENABLE = 1;    // ACCESS
        wait (PREADY == 1);
        @(posedge PCLK);
        PSEL = 0;
        PENABLE = 0;    // IDLE
        @(posedge PCLK);
    endtask //automatic

    task automatic abpWrite(logic [3:0] addr, logic [31:0] wdata);
        repeat (3) @(posedge PCLK);
        PSEL = 1;       // SETUP
        PENABLE = 0;
        PWRITE = 1;
        PADDR = addr;
        PWDATA = wdata;
        @(posedge PCLK);
        PENABLE = 1;    // ACCESS
        wait (PREADY == 1);
        @(posedge PCLK);
        PSEL = 0;
        PENABLE = 0;    // IDLE
        @(posedge PCLK);
    endtask //automatic

    // Slave Testbench
    initial begin
        for (int i = 0; i < 4; i++) begin
            abpWrite(4'h00 + i*4, 32'hDEAD_BEEF + i);
            #10;
        end

        for (int i = 0; i < 4; i++) begin
            abpRead(4'h00 + i*4);
            #10;
        end
    end
*/
endmodule