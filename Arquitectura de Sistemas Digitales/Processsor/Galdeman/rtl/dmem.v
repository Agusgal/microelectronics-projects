`timescale 1ns/10ps

module dmem (
    input  logic         clk_i  , // Señal de reloj para la escritura síncrona
    input  logic [7:0]   addr_i , // Dirección de entrada (10 bits para 1024 direcciones: 2^10 = 1024)
    input  logic [31:0]  wr_dt_i, // Dato de entrada para escritura
    input  logic         wr_en_i, // Habilitación de escritura (activo alto)
    output logic [31:0]  rd_dt_o  // Dato de salida de la memoria (para lectura)
);

// Declaración de la memoria de datos
logic [31:0] mem [256] ;

 // --- Lógica de Escritura Síncrona ---
 // La escritura se realiza en el flanco ascendente del reloj cuando wr_en_i está activo.
always_ff @(posedge clk_i) begin
   if (wr_en_i) begin
     mem[addr_i] <= wr_dt_i;
   end
end

 // --- Lógica de Lectura Combinacional ---
 assign rd_dt_o = mem[addr_i];

endmodule