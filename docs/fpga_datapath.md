# FPGA Hardware Implementation & Datapath

## Hardware Execution Model

* **Target Device:** Xilinx Artix-7 (Basys 3 FPGA)
* **System Clock:** 100 MHz onboard oscillator
* **CPU Clock Domain:** Scaled down via `clk_wiz_0` for stable execution and multi-cycle bus routing
* **Reset State:** Active-high system reset; initializes PC to `0x00`, clears CPU registers, and resets all debouncing state machines.
* **I/O Routing:** External bus mapped physically to onboard switches, buttons, and 7-segment display logic rather than simulated console I/O.

---

## Top-Level RTL Architecture

<img width="1213" height="594" alt="rtl_schematic" src="https://github.com/user-attachments/assets/7e8723f3-f2e5-49db-9e31-3f886700ed0a" />

The `fpga_top` module serves as the wrapper for the CPU, instantiating the core processor alongside physical peripheral controllers.

### Core Component Integration
1. **`main_cpu`**: The unmodified CPU core (Registers, ALU, Microcode ROM, Control Unit).
2. **`cpu_clock_gen`**: Generates the divided clock signal to meet timing constraints.
3. **`button_pulse`**: Hardware debouncer converting human-scale button presses into single-clock-cycle CPU write-enables.
4. **`binary_to_dec` & Display Muxing**: Translates the 8-bit `OUT` register into multiplexed signals for the 4-digit 7-segment display.

---

## Memory-Mapped I/O Architecture

To bridge the pure instruction set to physical hardware, the memory address space is intercepted before reaching the `RAM256` module. 

### Address Decoding (Pseudo-RTL)
```verilog
if (address == 0xFF) then
    data_bus_in ← {sw[15:7]}   // Upper switches routed directly to data bus
else
    data_bus_in ← RAM[address] // Normal memory fetch
```

### Architectural Implications
* Instructions like `LDA 0xFF` do not access physical block RAM. Instead, the memory controller multiplexes the live physical state of switches 15 through 7 directly onto the CPU's internal data bus during the `T2` (Memory Read) microstate.
* This allows pure software-level branching (e.g., `JZ`) based on real-time hardware conditions.

---

## Input Synchronization & Debouncing

Mechanical switch bounce will cause a single physical button press to register as hundreds of rapid voltage spikes, corrupting the CPU's FIFO queue.

### `button_pulse` Microarchitecture
Mechanical switch bounce causes rapid voltage spikes, and asynchronous human inputs can cause metastability in the registers. To fix this, `button_pulse` relies on a synchronizer and a cooldown counter rather than a traditional finite state machine:

1. **2-Stage Synchronizer:** Routes `btn_in` through two sequential flip-flops (`sync_0` and `sync_1`) to align the asynchronous physical button press with the CPU's clock domain.
2. **Cooldown Timer (Debounce):** A 20-bit counter acts as an inactivity timer. If the button signal fluctuates *at all* (press, release, or mechanical bounce), the timer resets to `1,000,000` (approx. 10ms at 100MHz). The counter only decrements when the physical line is perfectly stable.
3. **Edge-Triggered Pulse:** A single-cycle write-enable pulse is emitted only if a strict rising edge is detected (`sync_1 & ~sync_1_prev`) **and** the cooldown timer has safely reached zero. 

**Cycle Overhead:** Introduces a ~10ms hardware latency to physical inputs, which is invisible to the CPU's software polling loop but completely eliminates double-writes to the FIFO queue.

---

## Output Multiplexing (7-Segment Display)

The Basys 3 board requires constant, rapid multiplexing to display numbers across 4 digits. The CPU's `OUT` instruction executes in exactly 3 micro-cycles, but the display must hold that value indefinitely.

### Display Register Transfer Logic
```text
When CPU executes OUT (Opcode 0x2F):
T1: MAR ← PC
T2: OUT_REG ← A  // Hardware latches the Accumulator value
T3: PC ← PC + 1
```

Once latched in `OUT_REG`, the display module continuously translates and cycles the output independently of the CPU:
1. **Binary to BCD:** `binary_to_dec` continuously converts `OUT_REG` to Hundreds, Tens, and Ones.
2. **Refresh Counter:** A hardware counter (`refresh_counter_reg`) loops constantly.
3. **Anode/Cathode Muxing:** Based on the refresh counter, the RTL multiplexer activates one digit's anode (`an_i`) and drives its specific cathode segments (`seg_i`), switching fast enough to appear as a solid, continuous multi-digit number to the human eye.

---

## Hardware Implementation Invariants

* **Clock Independence:** Peripheral display multiplexing runs continuously, independent of CPU halt states (`HLT`) or microcode branch stalls.
* **Bus Isolation:** Physical switches cannot drive the CPU bus unless explicitly targeted by the memory controller (e.g., Address `0xFF`) or the dedicated FIFO read routine (`LDA_CHAR`).
* **Non-Volatile ROM:** The microcode (`microcode.mem`) and program memory (`program.mem`) are synthesized directly into FPGA Block RAM/ROM, establishing a hardcoded boot state upon power cycle.
