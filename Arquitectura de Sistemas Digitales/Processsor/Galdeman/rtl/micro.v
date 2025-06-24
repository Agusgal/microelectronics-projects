`timescale 1ns/10ps

module micro (
    input  logic    clk_i   ,
    input  logic    rst_ni );

logic [31:0]  dmem_dt_rd, dmem_dt_wr, pmem_dt ;
logic [ 7:0]  dmem_addr, pmem_addr ;
logic         dmem_wr ;

core u_core (
   .clk_i        ( clk_i      ) ,  
   .rst_ni       ( rst_ni     ) ,  
   .dmem_dt_o    ( dmem_dt_wr ) ,
   .dmem_addr_o  ( dmem_addr  ) ,
   .dmem_wr_o    ( dmem_wr    ) ,
   .dmem_dt_i    ( dmem_dt_rd ) ,
   .pmem_addr_o  ( pmem_addr  ) ,
   .pmem_dt_i    ( pmem_dt    ) );

pmem u_pmem(
   .clk_i        ( clk_i ) ,
   .addr_i       ( pmem_addr ) ,
   .data_o       ( pmem_dt   ) );

dmem u_dmem (
   .clk_i        ( clk_i      ) ,
   .addr_i       ( dmem_addr  ) ,
   .wr_dt_i      ( dmem_dt_wr ) ,
   .wr_en_i      ( dmem_wr    ) ,
   .rd_dt_o      ( dmem_dt_rd ) );

endmodule
