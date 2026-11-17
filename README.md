FPGA Cache Controller in VHDL
A direct-mapped, write-back cache controller for a simple memory hierarchy, built in VHDL on a Xilinx Spartan-3E FPGA. It sits between a CPU request generator, a 256-byte BlockRAM cache and an SDRAM main-memory model, and it handles all four hit and miss cases. ChipScope captures from the real board verify the timing.

Built for COE 758 (Digital Systems Engineering) at Toronto Metropolitan University, Fall 2026.

Features
Direct-mapped cache: 256 bytes, organised as 8 blocks of 32 one-byte words
16-bit address: tag [15:8], index [7:5], offset [4:0]
Write-back with write-allocate: each block has a valid bit and a dirty bit
All four cases handled: read hit, write hit, clean miss (fetch), and dirty miss (write-back, then fetch)
32-word block transfers: two clocks per word, using MEMSTRB
On-board verification: a ChipScope ICON and ILA capture every transaction over JTAG
Architecture
Module	What it does
cache_system	Top level that connects the CPU, the cache wrapper, main memory and ChipScope
CPU generator	Plays back 8 test transactions that cover every case, one per button press
Cache controller	Address register, tag compare, tag/valid/dirty storage, block counter and FSM
Cache SRAM (BlockRAM)	8 x 32-byte data storage
SDRAM controller	Behavioural main memory model, 16 KB
FSM states: IDLE → CHECK → READ_HIT / WRITE_HIT, or WRITEBACK → FETCH → hit state → COMPLETE → IDLE

Measured performance (50 MHz clock, from ChipScope)
Parameter	Clocks	Time
Hit/miss determination	1	20 ns
Hit time (read or write)	4	80 ns
Block fetch or write-back	64	1280 ns
Miss penalty, clean block (D = 0)	64	1280 ns
Miss penalty, dirty block (D = 1)	128	2560 ns
Total transaction, clean miss	68	1360 ns
Total transaction, dirty miss	132	2640 ns
Building and running
Create a Xilinx ISE project for the Spartan-3E and add the files in src/, the ChipScope cores and the .ucf file.
Set cache_system as the top module, then synthesise and generate the bitstream.
Program the board, open ChipScope Analyzer, and press the trigger button to step through the 8 test transactions.
Repository layout
src/            VHDL source (controller, CPU generator, SRAM wrapper, SDRAM model, top level)
constraints/    .ucf pin assignments
docs/           Project report, block/state/process diagrams, ChipScope captures
