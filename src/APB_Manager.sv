`timescale 1ns/1ps
module APB_Manager (
    // Global Signals
    input logic PCLK,
    input logic PRESET,

    output logic [31:0] PADDR,
    output logic PWRITE,
    output logic PENABLE,
    output logic [31:0] PWDATA,
    output logic PSEL0,
    output logic PSEL1,
    output logic PSEL2,
    output logic PSEL3,

    // APB Interface Signals
    input logic [31:0] PRDATA0,
    input logic [31:0] PRDATA1,
    input logic [31:0] PRDATA2,
    input logic [31:0] PRDATA3,
    input logic PREADY0,
    input logic PREADY1,
    input logic PREADY2,
    input logic PREADY3,

    // Internal Interface Signals
    input logic transfer,
    input logic write,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    output logic [31:0] rdata,
    output logic ready
);

    logic decoder_en;
    logic [1:0] mux_sel;
    logic temp_write_reg, temp_write_next;
    logic [31:0] temp_addr_reg, temp_addr_next;
    logic [31:0] temp_wdata_reg, temp_wdata_next;
    logic [3:0] PSELx;

    assign {PSEL3, PSEL2, PSEL1, PSEL0} = PSELx;

    APB_Decoder #(
        .BUS_NUM(4)
    ) U_APB_DECODER (
        .en(decoder_en),
        .addr_sel(temp_addr_reg),
        .y(PSELx),
        .mux_sel(mux_sel)
    );

    APB_Mux U_APB_MUX (
        .sel(mux_sel),
        .r_data0(PRDATA0),
        .r_data1(PRDATA1),
        .r_data2(PRDATA2),
        .r_data3(PRDATA3),
        .ready0(PREADY0),
        .ready1(PREADY1),
        .ready2(PREADY2),
        .ready3(PREADY3),
        .r_data(rdata),
        .ready(ready)
    );


    typedef enum { 
        IDLE,
        SETUP,
        ACCESS
    } apb_state_e;

    apb_state_e state_reg, state_next;

    always_ff @( posedge PCLK, posedge PRESET ) begin
        if (PRESET) begin
            state_reg <= IDLE;
            temp_write_reg <= 0;
            temp_addr_reg <= 0;
            temp_wdata_reg <= 0;
        end
        else begin
            state_reg <= state_next;
            temp_write_reg <= temp_write_next;
            temp_addr_reg <= temp_addr_next;
            temp_wdata_reg <= temp_wdata_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        temp_write_next = temp_write_reg;
        temp_addr_next = temp_addr_reg;
        temp_wdata_next = temp_wdata_reg;
        // Default Signals
        PADDR = temp_addr_reg;
        PWRITE = temp_write_reg;
        PWDATA = temp_wdata_reg;
        PENABLE = 1'b0;
        case (state_reg)
            IDLE: begin
                decoder_en = 1'b0;
                PENABLE = 1'b0;
                if (transfer) begin
                    state_next = SETUP;
                    // Latch signals
                    temp_write_next = write;
                    temp_addr_next = addr;
                    temp_wdata_next = wdata;
                end
            end
            SETUP: begin
                decoder_en = 1'b1;
                PENABLE = 1'b0;
                PADDR = temp_addr_reg;
                PWRITE = temp_write_reg;
                state_next = ACCESS;
                if (temp_write_reg) begin
                    PWDATA = temp_wdata_reg;
                end
            end
            ACCESS: begin
                decoder_en = 1'b1;
                PENABLE = 1'b1;
                if (ready) begin
                    if (transfer) begin
                        state_next = SETUP;
                    end else begin
                        state_next = IDLE;
                    end
                end else begin
                    state_next = ACCESS;
                end
            end
        endcase
    end
endmodule

module APB_Decoder #(
    BUS_NUM = 4
) (
    input logic en,
    input logic [31:0] addr_sel,
    /*
    Address Map
        ADDR_ROM       : 32'h0000_0000 ~ 32'h0000_FFFF
        ADDR_RAM       : 32'h1000_0000 ~ 32'h1000_0FFF
        ADDR_PERIPH_0 : 32'h1000_1000 ~ 32'h1000_2000
        ADDR_PERIPH_1 : 32'h1000_2000 ~ 32'h1000_3000
        ADDR_PERIPH_2 : 32'h1000_3000 ~ 32'h1000_4000
    */

    output logic [BUS_NUM-1:0] y,               // PSELx
    output logic [$clog2(BUS_NUM)-1:0] mux_sel  // PSEL
);
    always_comb begin : decode_logic_y
        y = 4'b0;
        if (en) begin
            casex (addr_sel)
                32'h1000_0xxx: y = 4'b0001;     // RAM
                32'h1000_1xxx: y = 4'b0010;     // PERIPH_0
                32'h1000_2xxx: y = 4'b0100;     // PERIPH_1
                32'h1000_3xxx: y = 4'b1000;     // PERIPH_2
            endcase
        end
    end

    always_comb begin : decode_logic_mux_sel
        mux_sel = 2'dx;
        if (en) begin
            casex (addr_sel)
                32'h1000_0xxx: mux_sel = 2'd0;     // RAM
                32'h1000_1xxx: mux_sel = 2'd1;     // PERIPH_0
                32'h1000_2xxx: mux_sel = 2'd2;     // PERIPH_1
                32'h1000_3xxx: mux_sel = 2'd3;     // PERIPH_2
            endcase
        end
    end
endmodule

module APB_Mux (
    input logic [1:0] sel,
    input logic [31:0] r_data0,
    input logic [31:0] r_data1,
    input logic [31:0] r_data2,
    input logic [31:0] r_data3,
    input logic ready0,
    input logic ready1,
    input logic ready2,
    input logic ready3,

    output logic [31:0] r_data,
    output logic ready
);
    always_comb begin : r_data_logic
        r_data = 32'b0;
        case (sel)
            2'b00: r_data = r_data0;
            2'b01: r_data = r_data1;
            2'b10: r_data = r_data2;
            2'b11: r_data = r_data3;
        endcase
    end

    always_comb begin : ready_logic
        ready = 1'b0;
        case (sel)
            2'b00: ready = ready0;
            2'b01: ready = ready1;
            2'b10: ready = ready2;
            2'b11: ready = ready3;
        endcase
    end
endmodule