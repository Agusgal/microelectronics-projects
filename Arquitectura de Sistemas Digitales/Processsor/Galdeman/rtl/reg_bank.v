`timescale 1ns/10ps

module reg_bank (
   input  logic         clk_i       , // Señal de reloj para escritura síncrona
   input  logic         rst_ni      , // Reset asíncrono activo-bajo (opcional pero buena práctica)
   input  logic [31:0]  reg_dt_i    , // Dato de entrada para escritura
   input  logic         reg_wr_i    , // Habilitación de escritura
   input  logic [3:0]   reg_addr_i  , // Dirección del registro a escribir (4 bits para 16 registros)
   input  logic [3:0]   busA_addr_i , // Dirección para el puerto de lectura A
   output logic [31:0]  busA_dt_o   , // Dato de salida para el puerto de lectura A
   input  logic [3:0]   busB_addr_i , // Dirección para el puerto de lectura B
   output logic [31:0]  busB_dt_o     // Dato de salida para el puerto de lectura B
);
  

// Declaración de registros
logic [31:0] register [16];

// El register[0] tiene que ser siempre 0.

// Logica de Escritura
always_ff @(posedge clk_i or negedge rst_ni) begin
   if (!rst_ni) begin
      for (int i = 0; i < 16; i++) begin
         register[i] <= '0; // Inicializar todos los registros a 0
      end
   end 
   else if (reg_wr_i) begin
      register[reg_addr_i] <= reg_dt_i; 
   end
end

// Lógica de Lectura
assign busA_dt_o = (busA_addr_i == 4'd0) ? 32'd0 : register[busA_addr_i];
assign busB_dt_o = (busB_addr_i == 4'd0) ? 32'd0 : register[busB_addr_i];


endmodule