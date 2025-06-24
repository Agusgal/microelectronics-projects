`timescale 1ns/10ps

module alu (
    input  logic [31:0] dtA_i    ,  // Operando A (32 bits)
    input  logic [31:0] dtB_i    ,  // Operando B (32 bits)
    input  logic [2:0]  alu_op_i ,  // Código de operación (3 bits para 8 funciones)
    output logic [31:0] alu_dt_o ,  // Salida de la operación (32 bits)
    output logic        sign_o   ,  // Flag de signo
    output logic        zero_o      // Flag de cero
);

reg  [32:0] result;
wire [32:0] neg_B, a_plus_b, a_minus_b, abs_b, a_sl_b;

assign a_plus_b   = dtA_i + dtB_i ;
assign a_minus_b  = dtA_i + neg_B ;
assign neg_B      = -dtB_i ;
assign abs_b      = dtB_i[31] ? neg_B : dtB_i ;
assign a_sl_b     = dtA_i << dtB_i[4:0] ;

always_comb begin
   case ( alu_op_i )
      3'b000: result = a_plus_b  ;
      3'b001: result = a_minus_b  ;
      3'b010: result = abs_b  ;
      3'b011: result = a_sl_b  ;
      3'b100: result = dtA_i & dtB_i  ;
      3'b101: result = dtA_i | dtB_i  ;
      3'b110: result = dtA_i ^ dtB_i  ;
      3'b111: result = neg_B  ;
   endcase
end

assign alu_dt_o  = result[31:0] ;
assign zero_o    = (result == 0) ;
//assign carry_o   = result[32] ;
assign sign_o    = result[31] ;

endmodule
