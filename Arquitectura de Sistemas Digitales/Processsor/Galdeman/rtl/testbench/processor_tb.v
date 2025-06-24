`timescale 1ns/10ps
///////////////////////////////////////////////
//  Author         : mdife
///////////////////////////////////////////////


`include "pmem.sv"
`include "dmem.sv"
`include "core.sv"
`include "alu.sv"
`include "reg_bank.sv"

`define CLK_PERIOD   20

module tb_micro;
///////////////////////////////////////////////
//  CLK Generation
localparam T_TCLK = `CLK_PERIOD / 2;

logic clk_i;
initial begin
  clk_i = 1'b0;
  forever # (T_TCLK) clk_i = ~clk_i;
end
///////////////////////////////////////////////
  
logic rst_ni;
micro u_micro (
   .clk_i          ( clk_i    ) ,
   .rst_ni         ( rst_ni      ) );

initial begin
   $timeformat (-6, 6, " us", 10);
   $dumpfile("dump.vcd"); $dumpvars;

   START_SIMULATION();
   @(posedge clk_i); #0.1;
   #100 $finish;
end


// --- Inicialización de la Memoria de Programa---
`define PMEM   u_micro.u_pmem.mem
initial begin
   ////////////// R_M_J_F_L_M_CND_OP _Literal _rsB _rsA _RD  ;
   `PMEM[0] = 32'b0_0_0_0_0_0_000_000_00000000_0000_0000_0001; // NOP
   `PMEM[1] = 32'b1_0_0_0_1_0_000_000_00001010_0000_0000_0001; // MOVE r1, 10
   `PMEM[2] = 32'b0_1_0_0_0_0_000_000_00000000_0001_0001_0000; // STORE r1, r1 (Write Mem)
   `PMEM[3] = 32'b1_0_0_0_0_1_000_000_00000101_0000_0000_0010; // LOAD r2, 5 (Read Mem)
   `PMEM[4] = 32'b1_0_0_1_1_0_000_001_00000001_0000_0001_0001; // SUB r1, 1 (Resta y Actualiza Flags)
   `PMEM[5] = 32'b0_0_1_0_0_0_010_000_00000010_0000_0000_0000; // JNZ 2
   `PMEM[6] = 32'b0_1_0_0_0_0_000_000_00000000_0000_0010_0000; // STORE r2 0
   `PMEM[7] = 32'b0_1_0_0_0_0_000_000_00001011_0000_0010_0000; // STORE r2 11
   `PMEM[8] = 32'b0_0_1_0_0_0_000_000_00001111_0000_0000_0000; // JUMP 8 (SE QUEDA AHI)
   ////////////// │ │ │ │ │ │  
   ////////////// │ │ │ │ │ └ Memory(1) or Register(0) 
   ////////////// │ │ │ │ └ Literal(1) or Register(0) ALU Source
   ////////////// │ │ │ └ Register Flag write 
   ////////////// │ │ └ PC Write - JUMP
   ////////////// │ └ MEMORY Write
   ////////////// └ Register Write
end


///////////////////////////////////////////////
// Simulation Tasks
///////////////////////////////////////////////
  
  task START_SIMULATION ();
    $display("--- START SIMULATION");
    rst_ni = 0;
    #20;
    rst_ni = 1;
    #1000;
  endtask

endmodule
