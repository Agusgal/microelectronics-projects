`timescale 1ns/10ps

module core (
   input  logic        clk_i       ,  
   input  logic        rst_ni      ,  
///// Data memory Interface
   output logic [31:0] dmem_dt_o   ,
   output logic [ 7:0] dmem_addr_o ,
   output logic        dmem_wr_o   ,
   input  logic [31:0] dmem_dt_i   ,
///// Program memory Interface
   output logic [ 7:0] pmem_addr_o ,
   input  logic [31:0] pmem_dt_i   );

// Signal Declaration
logic [31:0] instruction            ;
logic        opcode_reg_we          ; //  Register Write Enable
logic        opcode_mem_we          ; //  Memory Write Enable
logic        opcode_pc_we           ; //  JUMP - PC Write Enable
logic        opcode_flg_we          ; //  Flag Write Enable
logic        opcode_alu_src         ; //  Alu Source 0-Literal 1-Register
logic        opcode_reg_src         ; //  RegBank Source 0-ALU 1-Memory
logic [ 2:0] opcode_cond            ; //  
logic [ 2:0] opcode_alu_op          ; //  
logic [ 7:0] opdata_lit_dt          ; //  
logic [ 3:0] opdata_rsA_addr        ; //  
logic [ 3:0] opdata_rsB_addr        ; //  
logic [ 3:0] opdata_rd_addr         ; //  
logic [31:0] rsA_dt, rsB_dt         ; //
logic [ 7:0] lit_dt                 ; //  
logic [ 7:0] mem_addr               ; // 
logic [31:0] wr_reg_dt              ;
logic [31:0] alu_inB_dt, alu_dt     ; // 
logic        alu_fZ, alu_fS, alu_fZ_r, alu_fS_r;

// IF - Instruction fetching
/////////////////////////////////////////////////////////////////////
assign instruction    = pmem_dt_i    ;

// ID - Instruction Decoding and register Read
/////////////////////////////////////////////////////////////////////
// Control
assign opcode_reg_we     = instruction[31];
assign opcode_mem_we     = instruction[30];
assign opcode_pc_we      = instruction[29];
assign opcode_flg_we     = instruction[28];
assign opcode_alu_src    = instruction[27];
assign opcode_reg_src    = instruction[26];

assign opcode_cond       = instruction[25:23];
assign opcode_alu_op     = instruction[22:20]; 
// Data
assign opdata_lit_dt     = instruction[19:12];
assign opdata_rsB_addr   = instruction[11:8];
assign opdata_rsA_addr   = instruction[7:4];
assign opdata_rd_addr    = instruction[3:0];

// Data Read. Get all the DATA to be used.
reg_bank u_reg_bank(
   .clk_i       (clk_i) ,
   .rst_ni      (rst_ni) ,
   .reg_dt_i    (wr_reg_dt) ,
   .reg_wr_i    (opcode_reg_we) ,
   .reg_addr_i  (opdata_rd_addr) ,
   .busA_addr_i (opdata_rsA_addr) ,
   .busA_dt_o   (rsA_dt) ,
   .busB_addr_i (opdata_rsB_addr) ,
   .busB_dt_o   (rsB_dt) );

assign lit_dt       = {24'd0, opdata_lit_dt};
assign alu_inB_dt   = opcode_alu_src ? lit_dt : rsB_dt;

// EX - Instruction Executing
/////////////////////////////////////////////////////////////////////

assign mem_addr     = rsB_dt[7:0] + lit_dt  ;

alu u_alu (
   .dtA_i     (rsA_dt) ,
   .dtB_i     (alu_inB_dt) ,
   .alu_op_i  (opcode_alu_op) ,
   .alu_dt_o  (alu_dt) ,
   .sign_o    (alu_fS) ,
   .zero_o    (alu_fZ) );

// WR - Write Value to Register
/////////////////////////////////////////////////////////////////////
assign wr_reg_dt      = opcode_reg_src ? dmem_dt_i : alu_dt;

// WR - Write Flag
always_ff @(posedge clk_i or negedge rst_ni) begin
   if (!rst_ni) begin
      alu_fZ_r <= 1'b0;
      alu_fS_r <= 1'b0;
   end else if (opcode_flg_we) begin
      alu_fZ_r <= alu_fZ;
      alu_fS_r <= alu_fS;
   end
 end

// PC - Program Counter Logic
/////////////////////////////////////////////////////////////////////
// Condition Calculation
logic cond_ok;

always_comb begin
   case ( opcode_cond )
      default: cond_ok =  1  ; 			// ALWAYS
      3'b001:  cond_ok =  alu_fZ_r  ; 	//Z
      3'b010:  cond_ok =  ~alu_fZ_r  ;	 //NZ 
      3'b011:  cond_ok =  alu_fS_r  ; 	//S
      3'b100:  cond_ok =  ~alu_fS_r  ; 	//NS
   endcase
end

logic [7:0] PC ;

always_ff @(posedge clk_i or negedge rst_ni) begin
   if (!rst_ni) PC <= 0;
   else if  (opcode_pc_we & cond_ok)   PC <= lit_dt[7:0];
   else                                PC <= PC+1'b1;
end

// Outputs
assign pmem_addr_o  = PC;          // Dirección de instrucción a la PMEM
assign dmem_dt_o    = rsA_dt;      // Dato a escribir en DMEM (store usa rsA)
assign dmem_addr_o  = mem_addr;    // Dirección de la DMEM (base rsB + literal)
assign dmem_wr_o    = opcode_mem_we; // Habilita escritura cuando la instrucción lo indica

  

  
endmodule
