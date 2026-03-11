import sys

OPCODES = {
    "NOP":  0b0000,
    "LDA":  0b0001,
    "STA":  0b0010,
    "ADD":  0b0011,
    "SUB":  0b0100,
    "PUSH": 0b0101,
    "POP":  0b0110,
    "CALL": 0b0111,
    "RET":  0b1000,
    "JZ":   0b1100,
    "JC":   0b1101,
    "JMP":  0b1110,
    "HLT":  0b1111,
}

NO_OPERAND = {"NOP", "HLT", "RET", "PUSH", "POP"}


def parse_line(line):
    # Remove comments
    line = line.split(";")[0]
    return line.strip()


def first_pass(lines):
    labels = {}
    address = 0

    for line in lines:
        line = parse_line(line)

        if not line:
            continue

        if line.endswith(":"):
            label = line[:-1]
            labels[label] = address
        else:
            address += 1

    return labels


def second_pass(lines, labels):
    machine_code = []

    for line in lines:
        line = parse_line(line)

        if not line or line.endswith(":"):
            continue

        parts = line.split()
        mnemonic = parts[0].upper()

        if mnemonic not in OPCODES:
            raise ValueError(f"Unknown instruction: {mnemonic}")

        opcode = OPCODES[mnemonic]

        # Instructions without operands
        if mnemonic in NO_OPERAND:
            operand = 0

        else:
            if len(parts) < 2:
                raise ValueError(f"Missing operand for {mnemonic}")

            operand_text = parts[1]

            # numeric operand
            if operand_text.isdigit():
                operand = int(operand_text)

            # label operand
            else:
                if operand_text not in labels:
                    raise ValueError(f"Undefined label: {operand_text}")
                operand = labels[operand_text]

        if operand < 0 or operand > 15:
            raise ValueError("Operand out of range (0–15)")

        instruction = (opcode << 4) | operand
        machine_code.append(instruction)

    return machine_code


def assemble(filename):
    with open(filename) as f:
        lines = f.readlines()

    labels = first_pass(lines)
    machine_code = second_pass(lines, labels)

    print("Machine code (hex):")
    for instr in machine_code:
        print(f"{instr:02X}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python assembler.py program.asm")
        sys.exit(1)

    assemble(sys.argv[1])