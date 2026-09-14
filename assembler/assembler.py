#!/usr/bin/env python3
"""
assembler.py — two-pass assembler for the custom 32-bit ISA.

Usage:
    python3 assembler.py program.asm program.hex

Syntax supported:
    - one instruction or label per line
    - labels: "loop:" on their own line, or "loop: ADDI x1, x0, 0" inline
    - comments: ";" or "//" to end of line
    - registers: x0-x15
    - LW/SW use the form: LW rd, imm(rs1)   /   SW rs2, imm(rs1)
    - branches take a label, not a raw offset: BEQ x1, x2, loop
"""

import re
import sys

from isa import INSTRUCTIONS, reg_num, encode_r, encode_i, encode_s, encode_b


def strip_comment(line: str) -> str:
    for marker in (";", "//"):
        idx = line.find(marker)
        if idx != -1:
            line = line[:idx]
    return line.strip()


def parse_mem_operand(token: str):
    """Parse 'imm(rs1)' -> (imm:int, rs1:int)"""
    m = re.match(r"^(-?\w+)\((x\d+)\)$", token.strip())
    if not m:
        raise ValueError(f"expected 'imm(rs1)', got '{token}'")
    imm_str, rs1_str = m.groups()
    return int(imm_str, 0), reg_num(rs1_str)


def tokenize(line: str):
    """Split 'ADDI x1, x0, 5' into ['ADDI', 'x1', 'x0', '5']"""
    mnemonic, _, rest = line.partition(" ")
    operands = [op.strip() for op in rest.split(",") if op.strip()]
    return mnemonic.strip().upper(), operands


def first_pass(lines):
    """Collect label -> instruction-index. Returns (labels, cleaned_lines)."""
    labels = {}
    cleaned = []
    index = 0
    for raw in lines:
        line = strip_comment(raw)
        if not line:
            continue

        # A line may be "label:" alone, or "label: INSTR ..."
        if ":" in line:
            label, _, remainder = line.partition(":")
            label = label.strip()
            if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", label):
                raise ValueError(f"invalid label name: '{label}'")
            if label in labels:
                raise ValueError(f"duplicate label: '{label}'")
            labels[label] = index
            remainder = remainder.strip()
            if remainder:
                cleaned.append(remainder)
                index += 1
        else:
            cleaned.append(line)
            index += 1

    return labels, cleaned


def encode_instruction(line: str, index: int, labels: dict) -> int:
    mnemonic, operands = tokenize(line)
    if mnemonic not in INSTRUCTIONS:
        raise ValueError(f"unknown instruction: '{mnemonic}' (line: '{line}')")

    itype, op_or_funct2, shape = INSTRUCTIONS[mnemonic]

    if shape == "rd,rs1,rs2":
        rd, rs1, rs2 = (reg_num(o) for o in operands)
        return encode_r(op_or_funct2, rd, rs1, rs2)

    if shape == "rd,rs1,imm":
        rd = reg_num(operands[0])
        rs1 = reg_num(operands[1])
        imm = int(operands[2], 0)
        return encode_i(op_or_funct2, rd, rs1, imm, mnemonic)

    if shape == "rd,imm(rs1)":  # LW
        rd = reg_num(operands[0])
        imm, rs1 = parse_mem_operand(operands[1])
        return encode_i(op_or_funct2, rd, rs1, imm, mnemonic)

    if shape == "rs2,imm(rs1)":  # SW
        rs2 = reg_num(operands[0])
        imm, rs1 = parse_mem_operand(operands[1])
        return encode_s(rs1, rs2, imm, mnemonic)

    if shape == "rs1,rs2,label":  # BEQ / BNE
        rs1 = reg_num(operands[0])
        rs2 = reg_num(operands[1])
        target_label = operands[2]
        if target_label not in labels:
            raise ValueError(f"undefined label: '{target_label}'")
        # offset is in instructions, not bytes — matches the hardware's
        # own <<1/<<2 scaling done downstream in imm_gen/cpu.v
        offset = labels[target_label] - index
        return encode_b(op_or_funct2, rs1, rs2, offset, mnemonic)

    raise ValueError(f"unhandled operand shape '{shape}' for '{mnemonic}'")


def assemble(source_lines):
    labels, cleaned = first_pass(source_lines)
    words = []
    for index, line in enumerate(cleaned):
        try:
            words.append(encode_instruction(line, index, labels))
        except Exception as e:
            raise ValueError(f"line {index} ('{line}'): {e}") from e
    return words


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 assembler.py <input.asm> <output.hex>")
        sys.exit(1)

    in_path, out_path = sys.argv[1], sys.argv[2]

    with open(in_path) as f:
        source_lines = f.readlines()

    words = assemble(source_lines)

    with open(out_path, "w") as f:
        for w in words:
            f.write(f"{w:08x}\n")

    print(f"Assembled {len(words)} instructions -> {out_path}")


if __name__ == "__main__":
    main()