module tb #(
    parameter integer IIR_LPF_WLX = 16,   // Word Length for x input       : Assumed to be of type(1, WLX, WLX-1)
    parameter integer IIR_LPF_WLA = 15,   // Word Length for a coefficients: Assumed to be of type(1, WLA, WLA-2)
    parameter integer IIR_LPF_WLB = 15    // Word Length for b coefficients: Assumed to be of type(1, WLB, WLB-1)
);

    // -----------------------------------------------------
    // Local parameters
    // -----------------------------------------------------
    localparam real      CLK_FREQ_HZ = 8e6;
    localparam real      MAX_FREQ    = 1e6;             // Max Freq permitida
    localparam real      FS          = 10e6;            // Frecuencia de sampleo
    localparam realtime  TS          = 100ns;           // Tiempo de sampleo
    localparam real      PI          = 3.14159265359;   // PI
    // -----------------------------------------------------

    // ParÃ¡metros para el test de settling time
    localparam real      STEP_INPUT  = 0.5;            // Valor del escalÃ³n
    localparam real      TOLERANCE   = 0.02;           // Tolerancia (2%)
    localparam real      TARGET_VALUE = STEP_INPUT;    // Valor esperado
    localparam int       MAX_SETTLING_CLOCKS = 100000; // LÃ­mite mÃ¡ximo para evitar bucle infinito
    // -----------------------------------------------------


    // -----------------------------------------------------
    // Internal signals
    // -----------------------------------------------------
    real  x_stimuli;
    int   n;

    // Variables locales agregadas para el nuevo Test
    int   settling_clocks;
    real  current_output;
    real  error;
    bit   settling_done;
    bit   step_applied;



    reg   tb_clk   = 1'b0;
    reg   i_enable = 1'b0;
    reg   i_srst   = 1'b0;
    reg   i_rst_n  = 1'b0;

    // ----------------------------------
    // INPUT PORTS
    // ----------------------------------

    reg                     i_req;      // Request pulse
    reg   [IIR_LPF_WLX-1:0] i_x;        // Input data.
    reg   [IIR_LPF_WLA-1:0] i_a1;       // Coeficiente a1.
    reg   [IIR_LPF_WLA-1:0] i_a2;       // Coeficiente a2.
    reg   [IIR_LPF_WLB-1:0] i_b0;       // Coeficiente b0.
    reg   [IIR_LPF_WLB-1:0] i_b1;       // Coeficiente b1.
    reg   [IIR_LPF_WLB-1:0] i_b2;       // Coeficiente b2.

    // ----------------------------------
    // OUTPUT PORTS
    // ----------------------------------
    wire   [IIR_LPF_WLX-1:0] o_y;        // Output data.
    wire                     o_y_new;    // 1'b1 cuando hay data disponible.
    wire                     o_y_sat_lo; // Sat lo value.
    wire                     o_y_sat_hi; // Sat hi value.

    // -----------------------------------------------------

    // -----------------------------------------------------
    // Clockcito generado
    // -----------------------------------------------------
    always #((0.5/CLK_FREQ_HZ)*1s) tb_clk <= ~tb_clk;
    // -----------------------------------------------------

    // -----------------------------------------------------
    // ConversiÃ³n de salida a real para anÃ¡lisis 
    // -----------------------------------------------------
    always @(*) begin
        // Convertir de formato fijo a real (asumiendo formato Q15)
        current_output = $signed(o_y) / (2.0**(IIR_LPF_WLX-1));
    end



    // -----------------------------------------------------
    // Monitor de settling time - CORREGIDO
    // -----------------------------------------------------
    always @(posedge tb_clk) begin
        if (o_y_new && step_applied && !settling_done) begin
            error = (current_output - TARGET_VALUE);
            if (error < 0) error = -error; // Valor absoluto
            
            $display("Clock %0d: Output = %f, Target = %f, Error = %f", 
                     settling_clocks, current_output, TARGET_VALUE, error);
            
            if (error <= TOLERANCE) begin
                settling_done = 1'b1;
                $display("\n*** ANALISIS DE SETTLING TIME  ***");
                $display("Valor Target: %f", TARGET_VALUE);
                $display("Valor Final Output: %f", current_output);
                $display("Error: %f", error);
                $display("Tolerancia: %f", TOLERANCE);
                $display("Settling Time: %0d clocks", settling_clocks);
                $display("Settling Time: %0.2f us", settling_clocks * TS / 1us);
                $display("*** FIN  ***\n");
            end else begin
                settling_clocks++;
                // ProtecciÃ³n contra bucle infinito
                if (settling_clocks >= MAX_SETTLING_CLOCKS) begin
                    $display("\n*** ERROR: SETTLING TIME EXCEDIDO ***");
                    $display("MÃ¡ximo de clocks alcanzado: %0d", MAX_SETTLING_CLOCKS);
                    $display("El filtro no converge en el tiempo esperado");
                    $display("Output actual: %f, Target: %f, Error: %f", 
                             current_output, TARGET_VALUE, error);
                    $display("*** TERMINANDO SIMULACION ***\n");
                    settling_done = 1'b1; // Forzar salida del loop
                end
            end
        end
    end
    // -----------------------------------------------------


    // ------------------------------------------------------------------------
    // Modelos
    // ------------------------------------------------------------------------
    cic_model #(IIR_LPF_WLX) u_cic_model(
        // ----------------------------------
        // INPUT PORTS
        // ----------------------------------
        .clk            (tb_clk            ),
        .rst_n          (i_rst_n           ),
        .srst           (i_srst            ),
        .en             (i_enable          ),
        .x              (x_stimuli         ), // seÃ±al de estÃ­mulo
        // ---------------------------------
        // OUTPUT PORTS
        // ---------------------------------
        .y              (i_x),
        .y_rdy          (i_req)
    );


    // ------------------------------------------------------------------------
    // DUT (Design under test)
    // ------------------------------------------------------------------------
    iir_lpf #(IIR_LPF_WLX, IIR_LPF_WLA, IIR_LPF_WLB) u_iir_lpf(
        // ----------------------------------
        // INPUT PORTS
        // ----------------------------------
        .clk            (tb_clk    ),
        .rst_n          (i_rst_n   ),
        .srst           (i_srst    ),
        .enable         (i_enable  ),
        .req            (i_req     ),
        .x              (i_x       ),
        .a1             (15'h48dc  ),  // Coeficientes como entrada en lugar de localparam
        .a2             (15'h188e  ),
        .b0             (15'h00b5  ),
        .b1             (15'h016a  ),
        .b2             (15'h00b5  ),
        // ---------------------------------
        // OUTPUT PORTS
        // ---------------------------------
        .y              (o_y       ), 
        .y_new          (o_y_new   ), 
        .y_sat_lo       (o_y_sat_lo), 
        .y_sat_hi       (o_y_sat_hi)  
    );

    // ------------------------------------------------------------------------
    // Testing
    // ------------------------------------------------------------------------
    initial begin
        // Variables para el logging
        int output_file;
        int sample_count = 0;
        
        $timeformat(-9,0," ns",20);
        set_enable(1'b1);
        reset_dut();

        // InicializaciÃ³n
        settling_clocks = 0;
        settling_done = 1'b0;
        step_applied = 1'b0;
        n = 0;
    


        set_enable(1'b1);
        reset_dut();

        $display("\n=== COMENZANDO TEST DE RESPUESTA AL ESCALON ===");
        $display("Valor de Escalon Input: %f", STEP_INPUT);
        $display("Target Output: %f", TARGET_VALUE);
        $display("Tolerancia: %f (%0.1f%%)", TOLERANCE, TOLERANCE*100);
        $display("Cantidad mÃ¡xima de Clocks: %0d", MAX_SETTLING_CLOCKS);
        $display("=====================================\n");

        // Crear archivo de salida ANTES de aplicar el escalÃ³n
        output_file = $fopen("verilog_outputs.txt", "w");
        if (output_file == 0) begin
            $display("ERROR: No se pudo crear archivo de salida");
            $finish();
        end

        // Escribir header del archivo
        $fwrite(output_file, "# Sample_Index Output_Real Output_Hex Input_Hex\n");

        // Aplicar el escalÃ³n
        step_applied = 1'b1;

    
        // SimulaciÃ³n con fork join para manejar timeout y grabaciÃ³n en paralelo
        fork
            // Proceso 1: SimulaciÃ³n completa 
            begin
                for (int i=0; i < 10000; i = i+1) begin
                    update_sequence();
                    #TS;
                    n++;

                    // Guardar datos cuando hay nueva salida 
                    if (o_y_new) begin
                        $fwrite(output_file, "%0d  %.6f 0x%04h 0x%04h\n", 
                               sample_count, current_output, o_y, i_x);
                        sample_count++;
                        
                        // AnÃ¡lisis de settling time en paralelo (solo para display)
                        if (!settling_done) begin
                            error = (current_output - TARGET_VALUE);
                            if (error < 0) error = -error; // Valor absoluto
                            
                            if (sample_count > 10) begin // Empezar anÃ¡lisis despuÃ©s de algunas muestras
                                if (sample_count % 100 == 0) begin // Display cada 100 muestras para no saturar
                                    $display("Sample %0d: Output = %f, Target = %f, Error = %f", 
                                            sample_count, current_output, TARGET_VALUE, error);
                                end
                                
                                if (error <= TOLERANCE) begin
                                    settling_done = 1'b1;
                                    settling_clocks = sample_count;
                                    $display("\n*** ANALISIS DE SETTLING TIME  ***");
                                    $display("Valor Target: %f", TARGET_VALUE);
                                    $display("Valor Final Output: %f", current_output);
                                    $display("Error: %f", error);
                                    $display("Tolerancia: %f", TOLERANCE);
                                    $display("Settling Time: %0d samples", settling_clocks);
                                    $display("Settling Time: %0.2f us", settling_clocks * TS / 1us);
                                    $display("*** CONTINUANDO GRABACION ***\n");
                                end else begin
                                    // ProtecciÃ³n contra bucle infinito
                                    if (sample_count >= MAX_SETTLING_CLOCKS) begin
                                        $display("\n*** ERROR: SETTLING TIME EXCEDIDO ***");
                                        $display("MÃ¡ximo de samples alcanzado: %0d", MAX_SETTLING_CLOCKS);
                                        $display("El filtro no converge en el tiempo esperado");
                                        $display("Output actual: %f, Target: %f, Error: %f", 
                                                current_output, TARGET_VALUE, error);
                                        $display("*** CONTINUANDO SIMULACION ***\n");
                                        settling_done = 1'b1; // Forzar salida del anÃ¡lisis
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            // Proceso 2: Timeout de seguridad (solo para casos extremos)
            begin
                #(MAX_SETTLING_CLOCKS * TS * 3); // Timeout con margen amplio
                $display("\n*** TIMEOUT DE SIMULACION DE SEGURIDAD ***");
                $display("La simulaciÃ³n ha excedido el tiempo mÃ¡ximo de seguridad");
            end
        join_any
        
        disable fork; // Detener el proceso que no terminÃ³


        $fclose(output_file);
        $display("Datos guardados en: verilog_outputs.txt");
        $display("Total de muestras guardadas: %0d", sample_count);
    
        // Opcionalmente, llamar script Python para comparaciÃ³n automÃ¡tica
        //$system("python compare_with_golden.py verilog_outputs.txt");

        #10us;

        $display("\n=== SIMULACION COMPLETADA ===");
        $finish();
    end

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------
    task automatic set_enable(bit enable);
        string msg = $psprintf("\n\t %s", enable ? "ENABLE" : "DISABLE");
        $display(msg);
        i_enable = enable;
    endtask : set_enable

    task sync_reset();
        $display("\n\t sync reset");
        @(posedge tb_clk);
        i_srst <= 1'b1;
        @(posedge tb_clk);
        i_srst <= 1'b0;
    endtask : sync_reset

    task reset_dut(int p_width = 1, string unit = "us");
        $display("\n\t async reset");
        i_rst_n = 1'b0;
        wait_time(p_width, unit);
        i_rst_n = 1'b1;
    endtask : reset_dut

    task wait_time(int delay, string time_unit = "ns");
        time delay_in_time_units;
        time unit;
        case(time_unit)
           "ps": unit = 1ps;
           "ns": unit = 1ns;
           "us": unit = 1us;
           "ms": unit = 1ms;
           "s" : unit = 1s;
        endcase
        delay_in_time_units = delay * unit;
        #delay_in_time_units;
     endtask : wait_time

    function void update_sequence();
        //x_stimuli = 0.13*$sin(2*PI*((27_500*n)/FS));
        x_stimuli = STEP_INPUT;
    endfunction : update_sequence

endmodule : tb
