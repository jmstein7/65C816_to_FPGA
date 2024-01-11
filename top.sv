/* Module Description:
    // This module serves as the top-level entity for an FPGA design, interfacing with various
    // components such as clocks, data buses, control signals, UART, SRAM, and FLASH.
    // It handles the coordination and control of these components to implement the desired
    // functionality of the FPGA.
*/

module top(

    // Clock Signals
    input logic CLK,       // Internal 12 MHz Clock
    input logic PHI2,      // External 14.31818 MHz Clock
    input logic ACIA_CLK,  // External 1.8432 MHz Clock

    // Button
    input logic btn_reset, // Reset button

    // Address Lines
    input logic [15:0] A,  // Address bus

    // Data Lines
    inout logic [7:0] D,   // Data bus

    // Control Signals
    input logic RWB,       // Read/Write Bar signal
    output logic BE,        // Bus Enable signal
    input logic VDA,       // Valid Data Address signal
    output logic RESB,      // Reset Bar signal
    input logic VPA,       // Valid Peripheral Address signal
    output logic IRQB,      // Interrupt Request Bar signal
    output logic RDY,       // Ready signal

    // UART
    output wire uart_rxd_out,  // UART Receive Data Out
    input wire uart_txd_in,  // UART Transmit Data In
    
    // SRAM
    output reg [18:0] SramAdr, // SRAM Address Lines
    inout wire [7:0] SramDB,    // SRAM Data Lines
    output reg RamOEn,         // SRAM Output Enable
    output reg RamWEn,         // SRAM Write Enable
    output reg RamCEn,         // SRAM Chip Enable
    
    output wire [1:0] led,
    
    // FLASH
    output logic flashCSB,
    output logic flashCLK,
    inout  logic [3:0] flashIO
    
);

    // Clock and ACIA Signals
    logic CLK_8MHz;             // Output signal for the 8 MHz clock
    logic [7:0] acia_in;        // ACIA input data
    logic [7:0] acia_out;       // ACIA output data
    logic acia_irq;             // ACIA interrupt request
    logic phi_enable;           // PHI2 enable signal
    logic [1:0] reg_select;     // ACIA register select

    // UART Signals
    logic rts;                  // Request to Send
    logic tx;                   // Transmit Data
    logic rx;                   // Receive Data
    logic cts;                  // Clear to Send

    // Combined Signal for Valid Peripheral or Data Address
    logic vpvda;                // Valid Peripheral/Data Address combined signal

    // Memory Control Signals
    logic mrd_n, mrw_n;         // Memory Read and Write control signals
    logic mrw_enable;           // Memory Read/Write enable signal

    // Data Bus Control
    logic db_enable;            // Data Bus Enable signal
    logic [7:0] data_w;         // Data Write buffer
    logic [7:0] data_r;         // Data Read buffer
    logic [7:0] read_data;      // Data Read from memory

    // Bank Addressing
    logic [7:0] BA;             // Bank Address
    logic bank_enable;          // Bank Address Enable signal

    // Memory and Peripheral Control
    logic [15:0] address;   // Current address
    logic acia_e;               // ACIA enable signal
    logic rom_enable;           // ROM enable signal
    logic ram_enable;           // RAM enable signal
    logic [7:0] ram_in;         // RAM input data
    logic [7:0] ram_out;        // RAM output data
    logic [7:0] rom_out;        // ROM output data

    assign address = A;
    // Signal Assignments
    assign vpvda = (VPA || VDA) ? 1'b1 : 1'b0;
    assign mrw_enable = (PHI2) ? 1'b1 : 1'b0;
    assign mwr_n = (mrw_enable && ~RWB) ? 1'b0 : 1'b1;
    assign mrd_n = (mrw_enable && RWB) ? 1'b0 : 1'b1;
    
    assign bank_enable = (~PHI2) ? 1'b1 : 1'b0;
    assign db_enable = (~PHI2) ? 1'b0 : 1'b1;
    assign acia_e = ~acia_enable;
    assign reg_select = address[1:0];
    
    assign data_w = (db_enable) ? (~RWB ? D : 'bZ) : 'bZ;
    assign acia_in = (acia_enable && ~RWB) ? data_w : 'bZ; 
    assign ram_in = (ram_enable && ~RWB) ? data_w : 'bZ; 
    
    assign rom_enable = (address >= 16'hC000  && vpvda) ? 1'b1 : 1'b0;
    assign ram_enable = (address < 16'h8000 && vpvda) ? 1'b1 : 1'b0;
    assign acia_enable = (address >= 16'h8000 && address < 16'h8010 && vpvda) ? 1'b1 : 1'b0;
    
    // Bank Demultiplex Logic
    always_latch begin
        if (bank_enable) begin
            BA = D; // Latch bank address from data lines
        end
    end

    // Data Bus Logic
    assign D = (db_enable) ? (RWB ? (rom_enable ? rom_out : (ram_enable ? ram_out : (acia_enable ? acia_out : 'bZ))) : 'bZ) : 'bZ;

    // Control Signal Logic
    assign RESB = ~btn_reset;
    assign RDY = 1;
    assign BE = 1;
    assign IRQB = 1;
    assign RDY = 1;
    
    assign led[0] = RESB;
    assign led[1] = RESB;
    /*
    / Control Signals
    BE        // Bus Enable signal
    VDA       // Valid Data Address signal
    VPA       // Valid Peripheral Address signal
    IRQB      // Interrupt Request Bar signal
    RDY       // Ready signal
    */
    
    //ROM
    dist_mem_gen_0 rom_0(
    .a(address),
    .spo(rom_out)
  );
  
    // SRAM
    sram_ctrl5 ram_0(
        .clk(PHI2), 
        .rw(RWB), 
        .wr_n(mwr_n), 
        .rd_n(mrd_n), 
        .ram_e(ram_enable), 
        .address_input(address), 
        .data_f2s(ram_in), 
        .data_s2f(ram_out), 
        .address_to_sram_output(SramAdr), 
        .we_to_sram_output(RamWEn), 
        .oe_to_sram_output(RamOEn), 
        .ce_to_sram_output(RamCEn), 
        .data_from_to_sram_input_output(SramDB)
        );

    // Clock Divider Instantiation
    /*
    clock_div_128 clk_divider (
        .clk_12MHz(CLK),
        .clk_8MHz(CLK_8MHz)
    );
    */

    //UART Logic
    Xilinx_UART UART_A(
    .m_rxd(uart_txd_in), // Serial Input (required)
    .m_txd(uart_rxd_out), // Serial Output (required)
    .m_rtsn(cts), // Request to Send out(optional)
    .m_ctsn(rts), // Clear to Send in(optional)
    //  additional ports here
    .acia_tx(tx),
    .acia_rx(rx)

);

    // ACIA Module Instantiation
    ACIA acia_a(
        .RESET(RESB),
        .PHI2(PHI2),
        .phi_enable(phi_enable),
        .CS(acia_e),
        .RWN(RWB),
        .RS(reg_select),
        .DATAIN(acia_in),
        .DATAOUT(acia_out),
        .XTLI(ACIA_CLK),
        .RTSB(rts),
        .CTSB(cts),
        .DTRB(),
        .RXD(rx),
        .TXD(tx),
        .IRQn(1'b1) // Placeholder for ACIA IRQ
    );
   
endmodule
