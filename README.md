## *tiny5*

Toy RISC-V processor developed during the Processor Architecture subject as part of the Master in Innovation and Research in Informatics program at the Universitat Politècnica de Catalunya.

### Features

* RISC-V 32 integer and multiplication and division extension (RV32IM)
* INT pipeline: 5 stages (fetch, decode, execution/alu, memory, writeback)
* MULDIV pipeline: M0, M1, M2, M3, M4, WB<sub>MUL</sub>
* Store buffer
* ICache, Dcache, memory arbiter
* Bypasses to the register file output
* CSR (Control and Status Registers)
* Passes official RISC-V RV32I and RV32M tests (as of January 2019)[^1]

#### ICache, Dcache, memory arbiter

* Fully associative, write-back and write allocate (on store miss)
* Parameterized (*LINE_SIZE*, *SIZE*)

#### Store buffer
* Parameterized (*NUM_ENTRIES*)
* Snoops loads (hit only if *load.size == entry[i].size*)
* Circular buffer (*head*, *tail* pointers) FIFO
* “Priority encoder”, checks from *tail* to *head* (*head* is newer)

#### MULDIV pipeline
* RV32IM extension: MUL(H), DIV, REM instructions
* Pipeline stages: F, D, M0, M1, M2, M3, M4, WB<sub>MUL</sub>

#### CSR (Control and Status Registers)
* Clock and retired instruction count registers

[^1]: https://github.com/riscv/riscv-tests

## Pipeline overview

<img src="https://svgshare.com/i/1141.svg">

#### Arithmetic/logic instructions highlight

<img src="https://svgshare.com/i/114B.svg">

#### Load instruction highlight

<img src="https://svgshare.com/i/113i.svg">

#### Store instruction highlight

<img src="https://svgshare.com/i/114Q.svg">

#### Branch instructions highlight

<img src="https://svgshare.com/i/112w.svg">
