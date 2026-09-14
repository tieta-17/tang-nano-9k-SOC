"""
isa.py — instruction encoding definitions for the custom 32-bit ISA.

Field layout (bit positions), confirmed against the actual RTL:

  opcode[5:0]  = {type[1:0], op[3:0]}
      type: R=00  I=01  B=10  S=11

  R-type: funct[31:20] rs2[19:16] rs1[15:12] rd[11:8]  funct2[7:6] opcode[5:0]
  I-type: imm[31:16]               rs1[15:12] rd[11:8]  funct2[7:6] opcode[5:0]
  B-type: imm_hi[31:20] rs2[19:16] rs1[15:12] imm_lo[11:8] funct2[7:6] opcode[5:0]
  S-type: imm_hi[31:20] rs2[19:16] rs1[15:12] imm_lo[11:8] funct2[7:6] opcode[5:0]

  B/S-type immediate: 16 bits total, split as {imm_hi[11:0], imm_lo[3:0]}
  (the [11:8] slot physically overlaps R/I-type's rd field, but is reused
  as immediate bits here since B/S-type never write back to rd)
"""

TYPE_BITS = {"R": 0b00, "I": 0b01, "B": 0b10, "S": 0b11}

ALU_OP = {
    "ADD": 0b0000, "SUB": 0b0001, "XOR": 0b0010, "OR": 0b0011,
    "AND": 0b0100, "SLL": 0b0101, "SRL": 0b0110, "SRA": 0b0111,
    "SLT": 0b1000, "SLTU": 0b1001,
}

LW_OP = 0b1111  # reserved I-type opcode nibble, marks a load

BRANCH_FUNCT2 = {"BEQ": 0b00, "BNE": 0b01}

# Maps each assembly mnemonic to (type, op-or-funct2, operand shape)
INSTRUCTIONS = {
    "ADD":  ("R", ALU_OP["ADD"],  "rd,rs1,rs2"),
    "SUB":  ("R", ALU_OP["SUB"],  "rd,rs1,rs2"),
    "XOR":  ("R", ALU_OP["XOR"],  "rd,rs1,rs2"),
    "OR":   ("R", ALU_OP["OR"],   "rd,rs1,rs2"),
    "AND":  ("R", ALU_OP["AND"],  "rd,rs1,rs2"),
    "SLL":  ("R", ALU_OP["SLL"],  "rd,rs1,rs2"),
    "SRL":  ("R", ALU_OP["SRL"],  "rd,rs1,rs2"),
    "SRA":  ("R", ALU_OP["SRA"],  "rd,rs1,rs2"),
    "SLT":  ("R", ALU_OP["SLT"],  "rd,rs1,rs2"),
    "SLTU": ("R", ALU_OP["SLTU"], "rd,rs1,rs2"),

    "ADDI": ("I", ALU_OP["ADD"],  "rd,rs1,imm"),
    "SUBI": ("I", ALU_OP["SUB"],  "rd,rs1,imm"),
    "XORI": ("I", ALU_OP["XOR"],  "rd,rs1,imm"),
    "ORI":  ("I", ALU_OP["OR"],   "rd,rs1,imm"),
    "ANDI": ("I", ALU_OP["AND"],  "rd,rs1,imm"),
    "LW":   ("I", LW_OP,          "rd,imm(rs1)"),

    "SW":   ("S", None,           "rs2,imm(rs1)"),

    "BEQ":  ("B", BRANCH_FUNCT2["BEQ"], "rs1,rs2,label"),
    "BNE":  ("B", BRANCH_FUNCT2["BNE"], "rs1,rs2,label"),
}


def reg_num(token: str) -> int:
    """Parse 'x0'..'x15' into an integer 0-15."""
    token = token.strip().lower()
    if not token.startswith("x"):
        raise ValueError(f"expected a register like 'x3', got '{token}'")
    n = int(token[1:])
    if not (0 <= n <= 15):
        raise ValueError(f"register out of range 0-15: '{token}'")
    return n


def _check_imm_fits(imm: int, bits: int, mnemonic: str):
    lo = -(1 << (bits - 1))
    hi = (1 << (bits - 1)) - 1
    if not (lo <= imm <= hi):
        raise ValueError(
            f"immediate {imm} out of range for {mnemonic} "
            f"(must fit in {bits}-bit signed field: {lo}..{hi})"
        )


def encode_r(op: int, rd: int, rs1: int, rs2: int, funct2: int = 0) -> int:
    opcode = (TYPE_BITS["R"] << 4) | op
    return (rs2 << 16) | (rs1 << 12) | (rd << 8) | (funct2 << 6) | opcode


def encode_i(op: int, rd: int, rs1: int, imm: int, mnemonic: str) -> int:
    _check_imm_fits(imm, 16, mnemonic)
    opcode = (TYPE_BITS["I"] << 4) | op
    imm16 = imm & 0xFFFF
    return (imm16 << 16) | (rs1 << 12) | (rd << 8) | (0 << 6) | opcode


def _split_imm16(imm: int, mnemonic: str):
    _check_imm_fits(imm, 16, mnemonic)
    imm16 = imm & 0xFFFF
    imm_hi = (imm16 >> 4) & 0xFFF
    imm_lo = imm16 & 0xF
    return imm_hi, imm_lo


def encode_s(rs1: int, rs2: int, imm: int, mnemonic: str) -> int:
    imm_hi, imm_lo = _split_imm16(imm, mnemonic)
    opcode = (TYPE_BITS["S"] << 4) | 0
    return (imm_hi << 20) | (rs2 << 16) | (rs1 << 12) | (imm_lo << 8) | (0 << 6) | opcode


def encode_b(funct2: int, rs1: int, rs2: int, imm: int, mnemonic: str) -> int:
    imm_hi, imm_lo = _split_imm16(imm, mnemonic)
    opcode = (TYPE_BITS["B"] << 4) | 0
    return (imm_hi << 20) | (rs2 << 16) | (rs1 << 12) | (imm_lo << 8) | (funct2 << 6) | opcode