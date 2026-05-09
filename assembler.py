import sys

# Base opcode map for normal instructions
OPCODES = {
    "LDA":  0b0001,
    "STA":  0b0010,
    "ADD":  0b0011,
    "SUB":  0b0100,
    "PUSH": 0b0101,
    "POP":  0b0110,
    "CALL": 0b0111,
    "RET":  0b1000,
    "NOP":  0b1001,
    "IRET": 0b1010,
    "EI":   0b1011,
    "JZ":   0b1100,
    "JC":   0b1101,
    "JMP":  0b1110,
    "HLT":  0b1111,
}

# Custom one-byte special instructions
SPECIAL_BYTES = {
    "LDA_CHAR": 0x1D, # special raw keyboard-character instruction
    "LDK": 0x1E,      # special keyboard-input instruction
    "OUT": 0x2F,      # special output instruction
}

NO_OPERAND = {"PUSH", "POP", "RET", "NOP", "IRET", "EI", "HLT"}
WITH_OPERAND = {"LDA", "STA", "ADD", "SUB", "CALL", "JZ", "JC", "JMP"}


def parse_line(line):
    return line.split(";")[0].strip()


def instruction_size(mnemonic):
    if mnemonic in SPECIAL_BYTES:
        return 1
    if mnemonic in NO_OPERAND:
        return 1
    if mnemonic in WITH_OPERAND:
        return 2
    raise ValueError(f"Unknown instruction: {mnemonic}")


def parse_operand(operand_text, labels):
    if operand_text.startswith(("0x", "0X")):
        operand = int(operand_text, 16)
    elif operand_text.startswith(("0b", "0B")):
        operand = int(operand_text, 2)
    elif operand_text.isdigit():
        operand = int(operand_text)
    else:
        if operand_text not in labels:
            raise ValueError(f"Undefined label: {operand_text}")
        operand = labels[operand_text]

    if operand < 0 or operand > 255:
        raise ValueError(f"Operand out of range (0–255): {operand}")

    return operand


def first_pass(lines):
    labels = {}
    address = 0

    for raw_line in lines:
        line = parse_line(raw_line)

        if not line:
            continue

        parts = line.split()

        # Handle ORG directive in the first pass
        if parts[0].upper() == "ORG":
            if len(parts) != 2:
                raise ValueError("ORG requires an address operand")
            address = parse_operand(parts[1], labels)
            continue

        if line.endswith(":"):
            label = line[:-1].strip()
            if not label:
                raise ValueError("Empty label definition")
            if label in labels:
                raise ValueError(f"Duplicate label: {label}")
            labels[label] = address
            continue

        mnemonic = parts[0].upper()
        address += instruction_size(mnemonic)

    return labels


def second_pass(lines, labels):
    machine_code = [0x00] * 256
    address = 0

    for raw_line in lines:
        line = parse_line(raw_line)

        if not line:
            continue

        if line.endswith(":"):
            continue

        parts = line.split()
        mnemonic = parts[0].upper()

        # Handle ORG directive in the second pass
        if mnemonic == "ORG":
            address = parse_operand(parts[1], labels)
            continue

        # Custom one-byte special instructions
        if mnemonic in SPECIAL_BYTES:
            if len(parts) != 1:
                raise ValueError(f"{mnemonic} does not take an operand")
            machine_code[address] = SPECIAL_BYTES[mnemonic]
            address += 1
            continue

        if mnemonic not in OPCODES:
            raise ValueError(f"Unknown instruction: {mnemonic}")

        opcode = OPCODES[mnemonic]
        opcode_byte = (opcode << 4)

        if mnemonic in NO_OPERAND:
            if len(parts) != 1:
                raise ValueError(f"{mnemonic} does not take an operand")
            machine_code[address] = opcode_byte
            address += 1

        elif mnemonic in WITH_OPERAND:
            if len(parts) != 2:
                raise ValueError(f"{mnemonic} requires exactly one operand")

            operand = parse_operand(parts[1], labels)
            machine_code[address] = opcode_byte
            address += 1
            machine_code[address] = operand
            address += 1

        else:
            raise ValueError(f"Unhandled instruction type: {mnemonic}")

    return machine_code


def assemble(filename):
    with open(filename, "r") as f:
        lines = f.readlines()

    labels = first_pass(lines)
    machine_code = second_pass(lines, labels)

    out_filename = "program.mem"
    with open(out_filename, "w") as out_f:
        for byte in machine_code:
            out_f.write(f"{byte:02X}\n")

    print(f"\nMachine code successfully saved to {out_filename} for Verilog.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python assembler.py program.asm")
        sys.exit(1)

    assemble(sys.argv[1])