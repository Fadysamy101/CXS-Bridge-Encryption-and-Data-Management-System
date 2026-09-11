# Prompt: build my CXS Bridge presentation from my teammate's deck

> Attach **cxs_final.pptx** before sending. Optionally also attach my RTL (`src/`) and testbenches (`Verification/`); if they are attached, treat them as the source of truth over anything written below.

---

## 1. Context

My teammate and I each built our **own implementation of the same project**: the *CXS Bridge Encryption and Data Management System* (Digital Design Internship, Si-Vision, supervised by En. Menna Samir). We worked from the same architecture spec, so the **high-level system is similar**: CXS link in, clock-domain crossing, a control unit, encryption + parity, an ATU, and a central data memory (CDM). The **internal architecture differs in several blocks, most of all the CXS interface**.

The attached **cxs_final.pptx** is my teammate's final presentation. I need **my own presentation** that:

- looks **identical** in design (same template, colors, fonts, layouts, slide geometry, section-divider style), and
- follows the **same overall structure and order**, but
- describes **my** implementation accurately, with **placeholder pictures** wherever a figure must show my design or my results.

## 2. How to build it

1. **Start from a copy of cxs_final.pptx and edit it in place.** Do not rebuild the template from scratch. Duplicate, delete and reorder slides as the slide plan below says.
2. When replacing text, **keep the existing text boxes, run formatting, bullet levels and sizes**. Only change the words. If new text is longer, shorten the wording rather than shrinking the font or moving the box.
3. Keep the slide size (16:9, 10 × 5.625 in), the dark-navy title-slide gradient, the section-divider layout (big number, short accent bar, title, illustration on the right) and the content-slide title position.
4. Palette already used in the deck, for any element you must add: navy `#1E2761` (primary text/headings), dark grey `#3C3939` (body), teal `#00C2A8` (accent), light blue `#CADCFC`, white. Fonts: copy them from the neighbouring element on the same slide (the deck mostly uses Times New Roman for body text).
5. SmartArt diagrams (process flows, sub-block lists, FSM state lists) must keep the **same SmartArt style**; only change the node text and the number of nodes.
6. Fix the reference deck's typos in anything you keep ("Recieving" → "Receiving", "conclusion" → "Conclusion").

## 3. Picture rules: keep, or replace with a placeholder?

**Keep the original picture** only if it is generic and says nothing about either implementation:
- the Si-Vision logo on the title slide,
- the decorative illustrations on the section-divider slides,
- the generic CXS protocol figure on the "CXS Protocol" slide,
- the decorative verification-strategy graphic and the full-slide closing image.

**Replace with a placeholder** every picture that shows:
- a block diagram, a sub-block diagram or an FSM diagram (my architecture differs, so never reuse my teammate's),
- a waveform, a simulator transcript or a coverage screenshot,
- a SpyGlass lint report, or a Design Compiler timing or area report,
- anything else whose content could differ between our two designs. **If in doubt, use a placeholder.**

Do not draw my block diagrams yourself out of shapes. I will insert my own figures.

**Placeholder format** (use exactly this so I can find and replace them all):
- A rectangle at the **same left, top, width and height** as the picture it replaces.
- Fill `#F2F2F2`, dashed outline 1.25 pt in `#9AA5C0`, no shadow.
- Centered text in the slide's body font, `#3C3939`, three lines:
  - **PLACEHOLDER** (bold, 14 pt)
  - what the figure must show (12 pt), e.g. "My top-level block diagram: cxs_if, async FIFO, error synchronizer, system_wrapper"
  - `Source: <where I get it>` (10 pt, italic), e.g. "Source: draw.io diagram" or "Source: QuestaSim waveform"
- Also add `TODO: <same description>` to that slide's **speaker notes**.

## 4. Numbers and claims

- **Never invent results.** No pass counts, coverage percentages, lint results, timing slack or margins unless they appear in section 7 below (or in files I attached).
- Where the reference shows a result I don't have, write **`[TBD]`** in the same place and style.
- Never copy these items from my teammate's deck, because they are **not in my design**:
  - CXSACTIVEREQ/ACK link control (link activation/deactivation FSM, STOP→ACTIVE→RUN) and CXSCRDRTN credit return
  - the "Boundary Extractor", and a "Flit Decoder" in the system clock domain
  - a 32-bit CXSDATA / 6-bit CXSCNTL link
  - an application interface (`app_ack`, `app_read_*`), the LINK_OK handshake, or NACK handling
  - FSM states CFG_SCAN, CFG_WR, LINK_SCAN, LINK, LINK_OK, DATA_SCAN, DATA_BODY
  - splitting a 16-bit payload word into an 8-bit address + 8-bit data
  - the ATU formula "Logical − Base + Start + 2"
  - a reset synchronizer, or CDM REG0/REG1
  - "9/9", "10/10", "100% code coverage", SpyGlass and Design Compiler results, "47% margin"
- Do not mention my teammate or compare the two designs anywhere in the slides.

## 5. Slide-by-slide plan

Legend: **KEEP** = leave as is · **ADAPT** = same layout, rewrite text with my facts · **REWRITE** = same layout, content fully replaced · **NEW** = duplicate the named slide's layout.
Slide numbers in brackets refer to the **reference deck**.

| # | Title | Action | Content (facts in section 6) | Pictures |
|---|---|---|---|---|
| 1 | CXS BRIDGE Encryption & Data Management System | KEEP | Same title, program, supervisor. | Keep logo |
| 2 | Content | ADAPT | Agenda matching the final section titles below. | – |
| 3 | 1 · Introduction & Objectives | KEEP | Section divider. | Keep illustration |
| 4 | Design Objectives | ADAPT | Bullets: modular, parameterised SystemVerilog RTL · CXS RX/TX with credit-based flow control · CXSCNTL decoding with up to 2 packets per FLIT · safe dual-clock operation (CDC) · encryption, parity, address translation and CDM storage · verifiable at unit and system (UVM) level. SmartArt: Receiving → Encryption → Parity → Storing. | – |
| 5 | 2 · High-Level Architecture & System Overview | KEEP | Section divider. | Keep illustration |
| 6 | System Architecture | ADAPT | Caption: "Top-level block diagram: CXS Interface (CLK_CXS), Asynchronous FIFO and error synchronizer (CDC), System Wrapper (CLK_SYS) with Control Unit, ATU, Encryption, Parity and CDM." | **PLACEHOLDER**: my top-level block diagram |
| 7 | System Main Blocks | ADAPT | Keep the 5 cards; rewrite each card text (section 6.1). | Keep card graphics |
| 8 | High-Level Data Flow | REWRITE | Intro sentence + both SmartArt flows (section 6.2). | – |
| 9 | CXS Protocol | KEEP | Generic protocol slide. | Keep figure |
| 10 | CXS Interface (RX) | REWRITE | SmartArt sub-blocks: RX Interface, FLIT FIFO, Credit Manager, Packet Formatter (section 6.3). | **PLACEHOLDER**: my CXS RX path diagram (rx_interface → flit_fifo → packet_formatter → async FIFO, with credit_manager) |
| 11 | CXS Interface (TX) | REWRITE | SmartArt sub-blocks: Packet Encoder, TX Holding Register, TX Credit Counter, FLIT Transmitter (section 6.4). | **PLACEHOLDER**: my CXS TX path diagram (error pulse → packet_encoder → tx_interface) |
| 12 | Packet Formatter & CXSCNTL Decoding | **NEW** (layout of ref. [12]) | Text left: FSM IDLE → CAPTURE → STREAM, the CXSCNTL field layout table and word-window rule (section 6.5). | **PLACEHOLDER**: packet_formatter FSM / CXSCNTL decode diagram |
| 13 | Control Unit | REWRITE (ref. [12]) | Section 6.6 text. | **PLACEHOLDER**: my control unit internal diagram |
| 14 | Control Unit FSM | REWRITE (ref. [13]) | SmartArt: 5 states with one-line meaning + key outputs (section 6.7). | **PLACEHOLDER**: my control unit FSM state diagram |
| 15 | Encryption & Parity | ADAPT (ref. [14]) | Section 6.8. | – |
| 16 | ATU & Central Data Memory (CDM) | ADAPT (ref. [15]) | Section 6.9. | – |
| 17 | 3 · Clock Domain Crossing (CDC) Strategy | KEEP (ref. [16]) | Section divider. | Keep illustration |
| 18 | Clock Domain Crossing (CDC) | ADAPT (ref. [17]) | Objective (keep) · Clock domains: CXS 37 MHz, System 25 MHz, unrelated · Solutions: the **two** techniques in section 6.10. | **PLACEHOLDER**: my CDC diagram (async FIFO + toggle synchronizer) |
| 19 | CDC Solutions | ADAPT (ref. [18]) | SmartArt with **two** columns instead of three: Asynchronous FIFO · Error Toggle Synchronizer (section 6.10). | – |
| 20 | 4 · Verification Strategy & Test Cases | KEEP (ref. [19]) | Section divider. | Keep illustration |
| 21 | Verification Strategy | ADAPT (ref. [20]) | 1. Unit-level: self-checking SystemVerilog testbenches for async FIFO, packet formatter, control unit, encryption unit, parity unit · 2. System-level: UVM environment on the full top. Main goals: CXSCNTL decoding, credit flow control, CDC transfer, configuration and error handling, encryption/parity/ATU/CDM storage, error response FLIT. | Keep decorative graphic and its 4 labels |
| 22 | CXS Path Unit Verification | REWRITE (ref. [21]) | Scenarios + results for packet_formatter and async_fifo (section 7.1). | **PLACEHOLDER** ×2: packet_formatter waveform; async FIFO transcript/waveform |
| 23 | System Path Unit Verification | REWRITE (ref. [22]) | Scenarios + results for control_unit, encryption_unit, parity_unit (section 7.1). | **PLACEHOLDER** ×2: control_unit waveform; encryption/parity transcript |
| 24 | End-to-End Verification (UVM) | ADAPT (ref. [23]) | Box: UVM components + the 4 directed scenarios (section 7.2). SmartArt nodes: CXS RX Interface · FLIT FIFO · Packet Formatter · CDC / Asynchronous FIFO · Control Unit · ATU · Encryption + Parity · Central Data Memory · Packet Encoder · CXS TX Interface. | – |
| 25 | Initialization & Configuration | ADAPT (ref. [24]) | Scenario CFG_LINK_XFER, configuration part: reset, config TLP, global register at 0x00, device entries at 0x01+, invalid ENC_MODE → ERROR. | **PLACEHOLDER** ×3: waveforms (reset, config write, invalid ENC_MODE) |
| 26 | Data Processing | ADAPT (ref. [25]) | Link-Up and Transfer TLPs; TWO_TLP_ONE_FLIT (two TLPs, words 0–3 and 4–7 of one FLIT); payload → ATU address, encrypted + parity data in CDM. | **PLACEHOLDER** ×2: waveforms (transfer TLP write; two TLPs in one FLIT) |
| 27 | Error Response & TX Credit Flow | REWRITE (ref. [26]) | ERR_TX_FLIT and TX_CREDIT_STALL (section 7.2). | **PLACEHOLDER** ×2: waveforms (response FLIT sent; FLIT held until credit) |
| 28 | Verification Results | ADAPT (ref. [27]) | Section 7.3 only. Keep the result banner, but its text must match 7.3. | **PLACEHOLDER**: results summary screenshot |
| 29 | 5 · Linting & Synthesis Timing Results | KEEP (ref. [28]) | Section divider. | Keep illustration |
| 30 | Linting Results | ADAPT (ref. [29]) | Same bullet structure, every result `[TBD]`. | **PLACEHOLDER**: SpyGlass summary report |
| 31 | Synthesis Timing Results | ADAPT (ref. [30]) | Same bullet structure, every number and ✓ replaced by `[TBD]`. | **PLACEHOLDER** ×2: setup report; hold report |
| 32 | 6 · Conclusion | KEEP (ref. [31]) | Section divider (capitalise "Conclusion"). | Keep illustration |
| 33 | Conclusion | ADAPT (ref. [32]) | Section 7.4. | – |
| 34 | (closing image) | KEEP (ref. [33]) | – | Keep |

## 6. My architecture (source of truth)

### 6.0 Top level
- Two unrelated clock domains: **CLK_CXS (37 MHz)** and **CLK_SYS (25 MHz)**, each with an active-low asynchronous reset.
- Hierarchy: `top` → `cxs_if` (CXS domain) · `asynchronous_fifo` (CXS→SYS) · `synchronizer` for the error path (SYS→CXS) · `system_wrapper` (SYS domain: `control_unit`, `atu`, `encryption_unit`, `parity_unit`, `cdm`).
- CXS link: **CXSDATA 256 bits, CXSCNTL 14 bits, CXSMAXPKTPERFLIT = 2**, so a FLIT is 270 bits. Link signals: RX valid/data/cntl/credit-grant and TX valid/data/cntl/credit-grant.
- Top-level parameters: FLIT FIFO depth 16, TLP word 32 bits, async FIFO depth 8, CDM address width 8, payload data width 16, up to 8 devices.
- TLP format: 4 × 32-bit words (1 header + 3 payload words).

### 6.1 Slide 7 card texts
- **CXS Interface (RX/TX):** FLIT reception into a synchronous FLIT FIFO, credit-based flow control, CXSCNTL decoding and 32-bit word extraction, error-response FLIT generation and credit-gated transmission.
- **Control Unit:** 5-state FSM; TLP header decoding, configuration writes, Link-Up and Transfer handling, error detection and reporting.
- **Data Protection Path:** Encryption Unit (16 → 32-bit expansion, 2 modes plus a balanced-word override) and Parity Unit (even/odd parity appended → 33 bits).
- **Address Translation (ATU):** base address captured during configuration; translated address = base address + logical address.
- **Central Data Memory (CDM):** global configuration register at 0x0000, device table from 0x0001, payload region addressed by the ATU.

### 6.2 Slide 8 data flow
- Intro: "Incoming FLITs are buffered and decoded in the CXS clock domain; only valid 32-bit TLP words cross into the system domain through the Asynchronous FIFO."
- Forward flow: Incoming FLIT → RX Interface + FLIT FIFO (credit grant) → Packet Formatter (CXSCNTL decode, 32-bit words) → Asynchronous FIFO (CXS → SYS) → Control Unit → ATU + Encryption + Parity → CDM.
- Return flow: Control Unit error → Toggle Synchronizer (SYS → CXS) → Packet Encoder (response FLIT) → TX Interface (credit-gated) → CXS TX.

### 6.3 CXS RX path
- **RX Interface:** combinational; writes {CXSCNTL, CXSDATA} into the FLIT FIFO when CXSVALID is high and the FIFO is not full.
- **FLIT FIFO:** synchronous FIFO, 16 × 270-bit FLITs, wrap-bit pointers for full/empty, registered read.
- **Credit Manager:** credit counter starts at the FIFO depth, decrements on a FIFO write and increments on a FIFO read (unchanged on a simultaneous read and write); CXSRXCRDGNT is registered and high while credits remain.
- **Packet Formatter:** reads one FLIT at a time and writes only the 32-bit words that belong to a packet into the async FIFO; stalls on async-FIFO full (details in 6.5).

### 6.4 CXS TX path
- **Packet Encoder:** on the rising edge of the synchronized error pulse, builds a one-word response FLIT: opcode 0xE0 in bits [15:8], 2-bit error code in bits [1:0], START0 and END0 set in CXSCNTL. One FLIT per error event.
- **TX Holding Register:** stores one FLIT; `flit_ready` is low while a FLIT is pending.
- **TX Credit Counter:** counts CXSTXCRDGNT grants up to 16; one credit is consumed per transmitted FLIT (unchanged if a grant and a send happen in the same cycle).
- **FLIT Transmitter:** sends the pending FLIT only when a credit is available; CXSTXVALID/DATA/CNTL are registered.

### 6.5 Packet Formatter and CXSCNTL decoding (new slide 12)
- FSM: **IDLE** (wait for a FLIT, pop it) → **CAPTURE** (register FLIT data + CXSCNTL) → **STREAM** (step through the 8 words, write valid ones) → IDLE.
- CXSCNTL layout (14 bits, 2 packets per FLIT):

  | Bits | Field |
  |---|---|
  | [1:0] | START[1:0] |
  | [3:2] | START_PTR × 2 (1 bit each, units of 128 bits = 4 words) |
  | [5:4] | END[1:0] |
  | [7:6] | END_ERROR[1:0] |
  | [13:8] | END_PTR × 2 (3 bits each, in 32-bit words) |

- A word is valid if, for some packet *j*, START[j] and END[j] are both set and START_PTR[j] × 4 ≤ word index ≤ END_PTR[j].
- Current limitations (state honestly): packets spanning FLITs are not supported, and END_ERROR is decoded but not acted on.

### 6.6 Control Unit
- Receives 32-bit TLP words from the async FIFO (read-through FIFO: the word is visible before it is popped, so a header can be inspected and left for the next state).
- Header decode: packet type in bits [1:0] (00 Idle, 01 Configuration, 10 Link-Up, 11 Transfer); encryption mode in bits [7:4].
- A word counter tracks the position inside the 4-word TLP; a configuration counter tracks device entries written.
- **Configuration:** the first header is the global configuration register, written directly (bypassing encryption) to CDM 0x00 after an ENC_MODE check; the following words are device entries {END_ADDR, START_ADDR} written to 0x01, 0x02, ….
- **Link-Up / Transfer:** each payload word is split into **ADDR [31:24]** (to the ATU) and **DATA [15:0]**; bits [23:16] are unused (to encryption → parity → CDM).
- **Errors:** reported as a one-cycle `error_valid` pulse with a held 2-bit code: 00 invalid header packet, 01 invalid encryption mode, 10 invalid state/sequence.

### 6.7 Control Unit FSM (5 states)
- **S_IDLE**: waits for a Configuration header; drops any other word.
- **S_CFG_HDR**: writes the global register, then the device entries; once `dev_count` entries are written, only a Link-Up header may follow (otherwise → S_ERROR). Invalid ENC_MODE → S_ERROR.
- **S_LINK_UP**: consumes the Link-Up TLP; its payload words are written like data; then → S_DATA_HDR.
- **S_DATA_HDR**: data phase; Transfer TLP payloads are written to the CDM; a Link-Up header → S_LINK_UP; an Idle/Config header → S_ERROR.
- **S_ERROR**: asserts `error_valid` for one cycle, then → S_IDLE.

### 6.8 Encryption & Parity
- **Encryption Unit** (combinational, 16 → 32 bits; mode from CDM config register bits [7:4]). Each input bit becomes a 2-bit pair (values written MSB-first):
  - **Even mode** (0000): 0 → `00`, 1 → `01`
  - **Odd mode** (0001): 0 → `10`, 1 → `11`
  - **Balanced override:** if #ones = #zeros, or both counts are even, the mode is ignored: 0 → `01`, 1 → `10`
- **Parity Unit** (combinational, 32 → 33 bits; mode from CDM config register bit [2]): even mode → parity bit = XOR of the data, odd mode → its inverse; the bit is appended as the MSB.

### 6.9 ATU & CDM
- **ATU:** captures the base address from bits [31:24] of the configuration words during configuration writes, when it passes the address through unchanged. In the data phase, **physical address = base address + logical address**. The address-mode bit is decoded (range/region) but both modes currently use the same formula.
- **CDM:** 256 words × 33 bits (8-bit address). Configuration register at **0x00**: DEV_COUNT [15:8], ENC_MODE [7:4], ADDR_MODE [3], PARITY_MODE [2]; these fields drive the ATU, Encryption and Parity units. Device table from **0x01**. Reset clears the configuration region only. Write source select: configuration words are written directly (bypassing encryption); payload words are written encrypted with parity at the ATU address. A read port exists but has no user yet.

### 6.10 CDC
- **Asynchronous FIFO (CXS → SYS):** 32-bit words, depth 8, Gray-coded read/write pointers, 2-flip-flop pointer synchronizers, full/empty generated in their own domains.
- **Error Toggle Synchronizer (SYS → CXS):** the one-cycle error pulse flips a toggle flop in CLK_SYS; the toggle crosses through a 2-FF synchronizer and is edge-detected back into a pulse in CLK_CXS, so a slow-domain sampling edge cannot miss it. The 2-bit error code is held stable by the control unit, so the encoder samples it safely.
- There is **no** separate reset synchronizer in this design.

## 7. My verification results (only claim these)

### 7.1 Unit level (QuestaSim, self-checking SystemVerilog testbenches)
- **Async FIFO:** randomized writes and reads on unrelated clocks; every read word is compared with a reference queue. **All comparisons passed.**
- **Packet Formatter**, 5 directed tests: (1) one packet in words 0–2, (2) one packet in words 4–7 (START_PTR = 1), (3) two packets in one FLIT, (4) one packet spanning words 0–7, (5) async-FIFO back-pressure. **Completed with 0 errors.**
- **Control Unit**, 13 directed tests: reset · idle-word drop · configuration TLP · Link-Up · Transfer TLP · second Transfer TLP · Link-Up during data phase · configuration header during data phase · invalid encryption mode · bad header after configuration · early header · recovery after error · random FIFO stalls. **All completed with 0 errors.**
- **Encryption Unit:** **12/12 test cases PASS** (balanced, single-bit, all-zeros, all-ones and multi-bit cases in both modes).
- **Parity Unit:** **8/8 test cases PASS** (even/odd parity, all-zeros, all-ones).

### 7.2 System level (UVM)
- Environment: interface, sequence item, driver, monitor, sequencer, agent, environment, test, reset sequence and directed sequences, driving the full `top` with a 37 MHz CXS clock and a 25 MHz system clock.
- Directed scenarios:
  - **CFG_LINK_XFER:** reset → Configuration TLP → Link-Up TLP → Transfer TLP, one TLP per FLIT.
  - **TWO_TLP_ONE_FLIT:** two Transfer TLPs packed in one FLIT (words 0–3 and 4–7).
  - **ERR_TX_FLIT:** invalid ENC_MODE; the error crosses to the CXS domain and a response FLIT is transmitted (credit available).
  - **TX_CREDIT_STALL:** same error with no TX credit; the response FLIT is held until one credit is granted.
- Result: **simulation completes with 0 UVM_ERROR, 0 UVM_FATAL, 0 UVM_WARNING**. Behaviour was checked by **waveform inspection**.
- Scoreboard, functional coverage and SVA assertions are **planned, not yet implemented**. Present them as next steps, never as results.

### 7.3 Slide 28 (Verification Results) text
- Unit level: Async FIFO ✓ · Packet Formatter ✓ · Control Unit ✓ · Encryption 12/12 ✓ · Parity 8/8 ✓
- System level (UVM): 4 directed scenarios run clean (0 UVM errors), checked by waveform inspection
- Next steps: self-checking scoreboard, functional coverage, SVA assertions
- Banner: "PASS → all unit tests pass; UVM directed scenarios run clean"

### 7.4 Slide 33 (Conclusion) text
- Designed a modular, parameterised CXS Bridge Encryption and Data Management System in SystemVerilog.
- The CXS interface decodes CXSCNTL in the CXS domain and forwards only valid 32-bit TLP words across the CDC boundary.
- Integrated credit-based RX/TX flow control, an asynchronous FIFO and a toggle synchronizer, a 5-state control unit, encryption, parity, ATU and CDM into one end-to-end path.
- All unit-level testbenches pass; the UVM environment runs the main system scenarios cleanly.
- Next steps: UVM scoreboard, coverage and assertions; cross-FLIT packets; lint and synthesis sign-off.
- Final Outcome line: "RTL ✓ | Unit Verification ✓ | UVM Scenarios ✓ | Lint [TBD] | Synthesis [TBD]"

## 8. Deliverables

1. The finished **.pptx** (34 slides), named `cxs_final_<my name>.pptx`.
2. After the file, a **placeholder checklist** as a table: slide number · slide title · what each placeholder must show · suggested source.
3. A short list of anything you could not fit, shortened, or were unsure about.
