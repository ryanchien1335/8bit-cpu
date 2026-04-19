`timescale 1ns/1ps

module system_tb;

    // Inputs to the CPU
    reg clk;
    reg reset;
    reg INT;
    reg [7:0] external_bus_in;

    // Outputs from the CPU (to view in waveform)
    wire [8:0]  upc_out;
    wire [63:0] micro_out;
    wire [7:0] A_out, B_out, IR_out, OPR_out, MAR_out;
    wire [7:0] OUT_out, TEMP_out, DIGIT_out, TEMP1_out;
    wire [7:0] TEMP2_out, TEMP3_out, flags_out, alu_out;
    wire [7:0] pc_out, sp_out, ram_out, bus;
    wire       alu_zero, alu_carry;

    // Instantiate the CPU
    main_cpu uut (
        .clk(clk),
        .reset(reset),
        .INT(INT),
        .external_bus_in(external_bus_in),

        // Tie off the testbench write ports since we use $readmemh now!
        .prom_tb_clk(1'b0),
        .prom_tb_we(1'b0),
        .prom_tb_addr(8'h00),
        .prom_tb_data(8'h00),

        .upc_out(upc_out),
        .micro_out(micro_out),
        .A_out(A_out), .B_out(B_out), .IR_out(IR_out),
        .OPR_out(OPR_out), .MAR_out(MAR_out), .OUT_out(OUT_out),
        .TEMP_out(TEMP_out), .DIGIT_out(DIGIT_out), .TEMP1_out(TEMP1_out),
        .TEMP2_out(TEMP2_out), .TEMP3_out(TEMP3_out), .flags_out(flags_out),
        .alu_out(alu_out), .pc_out(pc_out), .sp_out(sp_out),
        .ram_out(ram_out), .bus(bus),
        .alu_zero(alu_zero), .alu_carry(alu_carry)
    );

    // 1. Generate the Clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // 2. Control the Reset and let it run
    initial begin
        // Initialize inputs
        INT = 1'b0;
        external_bus_in = 8'h00;
        
        // Hold reset high for a few clock cycles
        reset = 1'b1;

	// Put the number 5 into RAM Address 5
        uut.datapath_unit.ram_unit.mem[8'h05] = 8'h05;
        // Put the number 1 (0x0A) into RAM Address 1
        uut.datapath_unit.ram_unit.mem[8'h01] = 8'h01;
        // ----------------------------

        #20; 
        
        // Release reset! The CPU is now alive and running on its own.
        reset = 1'b0;

        // Let the simulation run for enough time to execute a few instructions
        #1000; 
        
        $display("Simulation Complete. Check the waveform!");
        $stop;
    end

   
    // 3. Print out the CPU's state to the terminal in real-time
    initial begin
        $monitor("Time: %0t | PC: %h | IR: %h | A Reg: %h | RAM: %h", 
                 $time, pc_out, IR_out, A_out, uut.datapath_unit.ram_unit.mem[8'h03]);
    end

endmodule