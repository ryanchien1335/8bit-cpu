OPCODES = {
    "NOP": 0b0000,
    "LDA": 0b0001,
    "STA": 0b0010,
    "ADD": 0b0011,
    "SUB": 0b0100,
    "JZ": 0b0101,
    "JC": 0b0110,
    "JMP": 0b1110,
    "HLT": 0b1111,
}

def parse_line(line):
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

        # Skip empty lines and labels
        if not line or line.endswith(":"):
            continue

        parts = line.split()
        mnemonic = parts[0].upper()

        # Check instruction exists
        if mnemonic not in OPCODES:
            raise ValueError(f"Unknown instruction: {mnemonic}")

        opcode = OPCODES[mnemonic]

        # Instructions with no operand
        if mnemonic in ("HLT", "NOP"):
            operand = 0
        else:
            operand_text = parts[1]

            # Number operand
            if operand_text.isdigit():
                operand = int(operand_text)
            else:
                # Label operand
                if operand_text not in labels:
                    raise ValueError(f"Undefined label: {operand_text}")
                operand = labels[operand_text]

        if operand < 0 or operand > 15:
            raise ValueError("Operand out of range (0–15)")

        instruction = (opcode << 4) | operand
        machine_code.append(instruction)

    print("Machine code (hex):")
    for instr in machine_code:
        print(f"{instr:02X}")



def assemble(filename):
    with open(filename) as f:
        lines = f.readlines()

    print("RAW LINES:", repr(lines))

    labels = first_pass(lines)
    print("Labels:", labels)

    second_pass(lines, labels)


assemble("test.asm")