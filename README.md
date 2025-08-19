# Traffic Light Controller FSM with UVM Testbench

# Abstract
This project implements a 4-state Moore Finite State Machine (FSM) in Verilog to control traffic lights (NS_GREEN, NS_YELLOW, EW_GREEN, EW_YELLOW) with fixed timings (10 and 3 clock cycles), verified using a UVM testbench in SystemVerilog. Simulated on EDA Playground with Riviera-PRO, it achieves comprehensive coverage.
# Objective
Design a Moore FSM for a traffic light controller ensuring safe transitions and verify it with UVM, covering all states and transitions, to learn VLSI design and verification.
# Working
The FSM uses clk and rst inputs, with current_state (2-bit) and timer (4-bit) to cycle states. Outputs (lights) depend on current_state: NS_GREEN (10 cycles), NS_YELLOW (3), EW_GREEN (10), EW_YELLOW (3). The UVM testbench drives inputs, monitors lights, infers states, and checks correctness via a scoreboard.
## Results
Simulation ran for 825ns (~31 cycles), with console showing Monitor (e.g., state=00, ns_g=1) and Scoreboard: PASS for all states. Waveform confirms: clk (10ns period), rst (10ns high), timer (counts 10/3), lights cycling safely (no dual greens).
# Inference
The Moore FSM operates stably, with predictable state transitions and correct light patterns. UVM verification ensures 100% coverage, validating design safety and timing. Waveform analysis confirms long-term reliability.
# Conclusion
The project successfully demonstrates a Moore FSM for traffic control, highlighting its stability advantage over Mealy. It builds VLSI skills in design and UVM verification, with potential for future enhancements like adaptive timing.
## Files
- traffic_light_fsm.sv : DESIGN CODE
- testbench.sv: UVM TESTBENCH
- traffic_light_fsm_waveform_RESULT.png: SIMULATION WAVEFORM
- Result_1_console : CONSOLE OUTPUT(MONITOR AND SCOREBOARD OUTPUTS)
- Result_2_console : CONSOLE OUTPUT(MONITOR AND SCOREBOARD OUTPUTS)continued
