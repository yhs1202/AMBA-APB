`timescale 1ns/1ps

interface apb_master_if(
    input logic clk,    
    input logic reset
);
    logic transfer;
    logic write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic ready;
endinterface //apb_master_if

class transaction;
    logic transfer;
    logic write;
    logic [31:0] rdata;
    rand logic [31:0] addr;
    rand logic [31:0] wdata;    // random data for write

    constraint addr_c {
        addr inside {
            [32'h1000_0000:32'h1000_000C],  // slv0
            [32'h1000_1000:32'h1000_100C],  // slv1
            [32'h1000_2000:32'h1000_200C],  // slv2
            [32'h1000_3000:32'h1000_300C]   // slv3
        };

        // 4-byte aligned
        addr % 4 == 0;
    }

    task automatic print(string name);
        $display("[%s], tranfer=%h, write=%0h, addr=0x%h, wdata=0x%h, rdata=0x%h",
                 name, transfer, write, addr, wdata, rdata);
    endtask //print
endclass //transaction


class apbSignal;
    transaction tr;

    virtual apb_master_if m_if;

    function new(virtual apb_master_if m_if);
        this.m_if = m_if;
        this.tr = new();
        
    endfunction //new()


    task automatic send();
        tr.transfer = 1'b1;
        tr.write    = 1'b1; // write
        m_if.transfer <= tr.transfer;
        m_if.write <= tr.write;
        m_if.addr <= tr.addr;
        m_if.wdata <= tr.wdata;

        @(posedge m_if.clk);
        m_if.transfer <= 1'b0;

        @(posedge m_if.clk);
        wait (m_if.ready);
        tr.print("SEND");
        @(posedge m_if.clk);
    endtask //automatic


    task automatic receive();
        tr.transfer = 1'b1;
        tr.write    = 1'b0; // read
        m_if.transfer <= tr.transfer;
        m_if.write <= tr.write;
        m_if.addr <= tr.addr;

        @(posedge m_if.clk);
        m_if.transfer <= 1'b0;

        @(posedge m_if.clk);
        wait (m_if.ready);
        tr.rdata = m_if.rdata;
        tr.print("RECEIVE");
        @(posedge m_if.clk);
    endtask //automatic

    task automatic compare();
        if (tr.wdata == tr.rdata) begin
            $display("PASS");
        end else begin
            $display("FAIL: WDATA=0x%h, RDATA=0x%h", tr.wdata,  tr.rdata);
        end
    endtask //automatic

    task automatic run(int count);
        repeat (count) begin
            tr.randomize();
            send();
            receive();
            compare();
        end
    endtask //automatic

    
endclass //apbSignal

module tb_APB ();
    // Global Signals
    logic PCLK;
    logic PRESET;

    // APB Interface Signals
    logic [3:0] PADDR;
    logic PWRITE;
    logic PENABLE;
    logic [31:0] PWDATA;

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

    /* Internal Interface Signals, Substituted by apb_master_if
    logic transfer;
    logic write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic ready;
    */
    apb_master_if m_if(
        .clk    (PCLK),
        .reset  (PRESET)
    );

    // Instantiate APB Signal Handlers -> Stack Segment
    /*
    apbSignal apbUART;  // handler
    apbSignal apbUART_clone; // shallow copy
    apbSignal apbGPIO;  // handler
    apbSignal apbTIMER;  // handler
    */

    // apb instance
    apbSignal apbInst;


    APB_Manager dut_manager (
        .*,
        .transfer   (m_if.transfer),
        .write      (m_if.write),
        .addr       (m_if.addr),
        .wdata      (m_if.wdata),
        .rdata      (m_if.rdata),
        .ready      (m_if.ready)
    );

    APB_Slave dut_slave_0 (
        .*,
        .PSEL   (PSEL0),
        .PRDATA (PRDATA0),
        .PREADY (PREADY0)
    );

    APB_Slave dut_slave_1 (
        .*,
        .PSEL   (PSEL1),
        .PRDATA (PRDATA1),
        .PREADY (PREADY1)
    );

    APB_Slave dut_slave_2 (
        .*,
        .PSEL   (PSEL2),
        .PRDATA (PRDATA2),
        .PREADY (PREADY2)
    );

    APB_Slave dut_slave_3 (
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

    initial begin
        apbInst = new(m_if);
        wait (!PRESET);
        repeat (3) @(posedge PCLK);

        apbInst.run(100);

        $stop;
    end
endmodule