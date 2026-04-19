# Verilog / ModelSim Implementation

This folder contains the HDL reconstruction of the 8-bit microcoded CPU project.

The original CPU was first developed in Logisim with a Python assembler, microcoded control flow, stack-based subroutines, interrupt handling, and opcode-selectable I/O behavior. This implementation extends that work into Verilog and ModelSim in order to recreate the architecture in HDL, validate behavior through simulation, and prepare the design for later FPGA deployment.

## Overview

This Verilog phase follows the same architectural goals as the Logisim-first implementation: clarity, correctness, and extensibility over raw performance.

The HDL implementation reconstructs the processor as a set of modular datapath and control components. It preserves the same general execution model, including multi-cycle instruction sequencing, shared-bus style data movement, microcoded control flow, stack behavior, and interrupt support.

## Folder Structure

This folder is organized into two main sections:

- `modules/` — Verilog hardware modules and top-level CPU integration
- `testbenches/` — simulation testbenches for unit-level and system-level validation

## Architecture Correspondence

The modules in this folder are intended to reflect the same CPU structure documented in the main project README and architecture notes.

Core implementation areas include:

- register and datapath components
- ALU behavior and flag generation
- program counter and stack pointer logic
- RAM and ROM structures
- microcode ROM and microprogram counter sequencing
- top-level datapath and control integration

This allows the HDL design to serve as a direct architectural reconstruction of the earlier Logisim CPU rather than a separate redesign.

## Implemented Modules

Current module work includes the following major components:

- `register.v`
- `alu.v`
- `pc.v`
- `sp.v`
- `ram256.v`
- `program_rom.v`
- `microcode_rom.v`
- `upc.v`
- `mini_cpu.v`
- `main_cpu.v`

Together, these modules provide the foundation for datapath execution, control sequencing, memory access, stack behavior, and top-level CPU integration.

## Testbench Coverage

Simulation testbenches are included to validate both individual module behavior and integrated system behavior.

Current testbench work includes validation of:

- register loading behavior
- ALU operations and flag outputs
- PC and SP update behavior
- RAM read/write behavior
- microprogram counter sequencing
- integrated CPU execution flow

System-level benches are used to observe instruction execution, opcode dispatch, stack behavior, interrupt-related behavior, and broader integration correctness.

## Execution and Validation

The current focus of this HDL phase is simulation-based validation in ModelSim.

This includes:
- reconstructing the documented CPU architecture in Verilog
- verifying datapath and control behavior through testbenches
- running instruction-level execution tests
- refining sequencing and integration details before hardware deployment

At this stage, the Verilog implementation should be understood as an active reconstruction and validation effort rather than a finalized FPGA deployment.

## Notes

A few implementation details are still being refined.

For example:
- some files or benches may still be under development
- documentation for this HDL phase is still being expanded
- ROM initialization paths may need cleanup for portability across different machines

These are documentation and workflow refinements rather than changes to the overall architectural direction.

## Relationship to the Main Project

The main repository README remains the primary description of the CPU’s architecture, instruction model, stack behavior, interrupt behavior, and assembler support.

This folder should be understood as the HDL realization of that same system.

In other words, the Logisim implementation established the architectural design, while this Verilog / ModelSim implementation is rebuilding that design in a form suitable for simulation, verification, and eventual FPGA deployment.
