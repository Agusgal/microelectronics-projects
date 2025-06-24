`timescale 1ns/10ps

module pmem (
    input  logic        clk_i   , // Señal de reloj para la lectura síncrona
    input  logic [7:0]  addr_i  , // Dirección de entrada (10 bits para 1024 direcciones: 2^10 = 1024)
    output logic [31:0] data_o    // Dato de salida (32 bits)
);

//logic [31:0] mem [0:255] ='{default:0};
logic [31:0] mem [256] ;

//always_ff @(posedge clk_i) begin
always_comb begin ; 
   data_o = mem[addr_i] ;
end


endmodule