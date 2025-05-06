# CPU Experiment 2023
## Memory Architecture

- **External Memory Access**: DDR2 access is implemented using Xilinx MIG (Memory Interface Generator). The design places MIG between two asynchronous FIFOs (for input and output), each generated via IP cores.

- **Cache Design**:
  - Type: L1 Cache only
  - Structure: 4-way Set-Associative
  - Configuration: 128-bit × 4096 lines  
  - Address Breakdown:
    - Tag: 7 bits
    - Index: 12 bits
    - Offset: 2 bits
  - Write Policy: Write-back with dirty bits per tag
  - Replacement Policy: Pseudo-LRU using `accessed` bits for each tag. If all ways are accessed, the non-recently-used ways are reset to 0. The replacement starts from way0, looking for the first `accessed = 0`.

- **Optimization**:
  - Enabled read/write in consecutive clock cycles by prefetching the next instruction's index/tag.
  - Implemented tag/data forwarding when writing to the same index as the next read.
  - Considered (but rejected) way prediction to reduce critical path delays by halving the number of tag comparisons, as FPU delays became dominant.

---

## FPU Architecture

- **Instruction Latencies**:
  - `fadd`, `fsub`: 3 cycles
  - `fmul`: 2 cycles
  - `fdiv`: 4 cycles
  - `fsqrt`: 2 cycles
  - `fcvtws`: 1 cycle
  - `fcvtsw`: 2 cycles
  - `fhalf`, `fabs`, `feq`, `flt`, `fle`: 1 cycle

- **Floating Point Format** (IEEE-754 Single Precision):
  - Sign: 1 bit
  - Exponent: 8 bits
  - Mantissa: 23 bits
  - Special Cases:
    - `e = 0`: treated as zero regardless of sign or mantissa
    - `e = 255`: undefined behavior
    - `0 < e < 255`: real value is calculated as  
      \[
      (-1)^s \times 2^{(e-127)} \times 1.m
      \]

- **Verification**:  
  All operations were verified with over 100 million randomized test cases and various corner cases using Vivado Simulator (command-line execution).