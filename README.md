# CXS Bridge Encryption and Data Management System

[**Design Link:** *<Insert your architecture spec / diagram link here>*](#)

This repository contains the full RTL implementation of the CXS Bridge project, including source code, testbenches, simulation waveforms, and shared type packages. The bridge sits between an external CXS interface and internal logic blocks, providing configurable encryption, parity generation, and centralized data storage across two clock domains (`CLK_CXS` and `CLK_SYS`).

*Note: this README assumes SystemVerilog. If you're targeting VHDL instead, swap `.sv` for `.vhd` and `package ... endpackage` for a VHDL package — the structure below still applies.*

---

# File Structure

The project is organized into three main folders. Each folder mirrors the others in terms of file count and naming, so every source file should have a corresponding testbench and waveform directory.

```
project-root/
│
├── src/
│   ├── packages/
│   │   └── cxs_pkg.sv
│   ├── 01_cxs_interface/
│   │   └── cxs_interface.sv
│   ├── 02_async_fifo/
│   │   └── async_fifo.sv
│   ├── 03_sync/
│   │   ├── reset_sync.sv
│   │   └── ctrl_sync_2ff.sv
│   ├── 04_control_unit/
│   │   └── control_unit.sv
│   ├── 05_register_file/
│   │   └── register_file.sv
│   ├── 06_encryption/
│   │   └── encryption_module.sv
│   ├── 07_parity/
│   │   └── parity_module.sv
│   ├── 08_cdm/
│   │   └── cdm.sv
│   └── 09_top/
│       └── cxs_bridge_top.sv
│
├── tb/
│   ├── <corresponding testbenches>.sv
│
├── wave/
│   ├── <corresponding waveform setups>.do
│
└── do/
    ├── <compile / simulation do files>.do
```

### Notes on File Structure
- Files in **src/** should always have:
  - A matching **testbench** file in **tb/**
  - A simulation waveform setup in **wave/** (mostly for repetitive tests during development)
- Folders are prefixed with numbers (`01_cxs_interface`, `02_async_fifo`, ...). This is intentional.
  Compilers — especially when doing `vcom` / `vlog` on a wildcard path — compile in file order, and this project has a real dependency chain: the CDC boundary must exist before the control unit that reads from it, the register file must exist before anything that reads config bits from it, and so on. Numbering enforces that order instead of relying on the tool to figure it out.
- `03_sync` is split out on its own because it's shared infrastructure (used by the CXS interface, control unit, and reset tree alike) rather than belonging to any one functional block.

---

# Types & Constants Package

You should have a shared package `cxs_pkg.sv` inside `src/packages/`. This package includes constants and types pulled straight from the register map in the architecture spec: bus widths, `ENC_MODE` / `PARITY_MODE` / `SYS_STATE` field encodings, per-device address region widths, and the TLP word format.

### Why the package matters
Instead of redefining bus widths or state encodings in every module, everything is defined **once**. If a value shows up in more than one block — encryption mode encoding, address region width, FIFO depth — it belongs in the package, not hardcoded locally. This also means when the register map changes (and it likely will — see the open issues below), you fix it in one place.

### How to use the package
Add this line to the top of any file that uses the shared types:
```systemverilog
import cxs_pkg::*;
```

### Open items to resolve before relying on this package
The architecture spec has a couple of ambiguities worth nailing down here rather than discovering mid-implementation:
- `ENC_MODE` is listed as bits `7:4` (4 bits) but only two values (`0000`/`0001`) are defined — confirm whether this is really a 1-bit field before encoding it in the package.
- Behavior on parity mismatch isn't defined (hard stop vs. status flag) — decide this once, encode it as a constant/enum, and reference it everywhere downstream.

---

# Workflow

This project has a lot of incremental steps, split across the two clock domains from the architecture. The recommended build order is bottom-up: get the pieces each phase depends on working before the phase that uses them.

### 1. Shared Package + Register File _Not started_
Lock the register map (base address, `DEV_COUNT`, `ENC_MODE`, `PARITY_MODE`, `SYS_STATE`, and the three device address regions) in `cxs_pkg.sv`, then build `register_file.sv`. Every other block reads from this — get it right first.

### 2. CDM (Central Data Memory) _Not started_
Build the shared memory block and its per-region address decode before anything tries to write to it. No simulation should manually hardcode memory contents — later stages should write through the real address-decoded interface.

### 3. CDC Boundary: Async FIFO + Synchronizers _Not started_
Before wiring the two clock domains together, get the async FIFO (Gray-coded pointers, dual-flop pointer sync) and the 2-stage synchronizers for single-bit control signals (`FIFO Empty`, `Link-Up Complete`, etc.) working and tested in isolation. This is the highest-risk block in the whole design — don't let it be an afterthought bolted on at integration time.

### 4. CXS Interface _Not started_
Header validation, packet framing, and the `TX_VALID`/`RX_VALID`/`READY` handshake. This is the one block where correctness depends on the real CXS protocol, not just this spec — flag it for a protocol-compliance review separately from functional testing.

### 5. Control Unit _Not started_
The three-phase FSM (Configuration → Link-Up → Data Transmission) plus CDM arbitration. Implement against stubbed encryption/parity/CDM interfaces first so you're not blocked waiting on those blocks.

### 6. Encryption + Parity Modules _Not started_
Both are small. Implement the bit-counting/expansion logic and the parity XOR tree, test each against hand-computed vectors before wiring them into the pipeline.

### 7. Reset Tree _Not started_
Asynchronous assert, synchronous per-domain deassert via reset synchronizers. Wire this in early enough that every block above is tested with reset behavior included, not added at the end.

### 8. Top-Level Integration _Not started_
Wire everything together into `cxs_bridge_top.sv`, run a lint pass, and confirm the three operating phases end-to-end in simulation.

---

# General Advice

- Maintain mirrored structure between `src/`, `tb/`, and `wave/`.
- Put every register-map constant and shared type into `cxs_pkg.sv` — never redefine field widths locally.
- Use numbered folders/filenames only where compile order actually matters (the CDC and register file dependencies are the real ones here).
- Keep testcases small and readable early — one instruction/one operating phase per test before combining them.
- Treat the async FIFO and CXS interface as the two blocks that need the most test coverage; the encryption, parity, and CDM blocks are comparatively low-risk.
- Naming convention: signal names for data buses in lowercase (`data_bus`, `adr_bus`), control/status signals in all **CAPS** (`SYS_STATE`, `LINK_UP`).
- Update the status tags (`_Not started_` / `_In progress_` / `_Done_`) next to each workflow step as you go, same as the original template.

---

Feel free to update or expand this README as the project grows.
