package definitions;

/* RISC-V ISA definitions */

typedef struct packed {
	logic [31:25] funct7;
	logic [24:20] rs2;
	logic [19:15] rs1;
	logic [14:12] funct3;
	logic [11:7] rd;
	logic [6:0] opcode;
} instruction_rtype_t;

typedef struct packed {
	logic [31:20] imm;
	logic [19:15] rs1;
	logic [14:12] funct3;
	logic [11:7] rd;
	logic [6:0] opcode;
} instruction_itype_t;

typedef struct packed {
	logic [31:25] imm;
	logic [24:20] rs2;
	logic [19:15] rs1;
	logic [14:12] funct3;
	logic [11:7] imm0;
	logic [6:0] opcode;
} instruction_stype_t;

typedef struct packed {
	logic [31:12] imm;
	logic [11:7] rd;
	logic [6:0] opcode;
} instruction_utype_t;

typedef union packed {
	logic [31:0] bits;
	logic [6:0] opcode;
	instruction_rtype_t rtype;
	instruction_itype_t itype;
	instruction_stype_t stype;
	instruction_utype_t utype;
} instruction_t;

typedef enum logic [6:0] {
	OPCODE_LUI      = 7'b0110111,
	OPCODE_AUIPC    = 7'b0010111,
	OPCODE_JAL      = 7'b1101111,
	OPCODE_JALR     = 7'b1100111,
	OPCODE_BRANCH   = 7'b1100011,
	OPCODE_LOAD     = 7'b0000011,
	OPCODE_STORE    = 7'b0100011,
	OPCODE_OP_IMM   = 7'b0010011,
	OPCODE_OP       = 7'b0110011,
	OPCODE_MISC_MEM = 7'b0001111
} opcode_t;

typedef enum logic [2:0] {
	FUNCT3_BRANCH_BEQ  = 3'b000,
	FUNCT3_BRANCH_BNE  = 3'b001,
	FUNCT3_BRANCH_BLT  = 3'b100,
	FUNCT3_BRANCH_BGE  = 3'b101,
	FUNCT3_BRANCH_BLTU = 3'b110,
	FUNCT3_BRANCH_BGEU = 3'b111
} funct3_branch_t;

typedef enum logic [2:0] {
	FUNCT3_LOAD_LB  = 3'b000,
	FUNCT3_LOAD_LH  = 3'b001,
	FUNCT3_LOAD_LW  = 3'b010,
	FUNCT3_LOAD_LBU = 3'b100,
	FUNCT3_LOAD_LHU = 3'b101
} funct3_load_t;

typedef enum logic [2:0] {
	FUNCT3_STORE_SB = 3'b000,
	FUNCT3_STORE_SH = 3'b001,
	FUNCT3_STORE_SW = 3'b010
} funct3_store_t;

typedef enum logic [2:0] {
	FUNCT3_OP_IMM_ADDI  = 3'b000,
	FUNCT3_OP_IMM_SLTI  = 3'b010,
	FUNCT3_OP_IMM_SLTIU = 3'b011,
	FUNCT3_OP_IMM_XORI  = 3'b100,
	FUNCT3_OP_IMM_ORI   = 3'b110,
	FUNCT3_OP_IMM_ANDI  = 3'b111,
	FUNCT3_OP_IMM_SLLI  = 3'b001,
	FUNCT3_OP_IMM_SRI   = 3'b101 /* SRLI and SRAI */
} funct3_op_imm_t;

typedef enum logic [2:0] {
	FUNCT3_OP_ADD_SUB  = 3'b000, /* ADD and SUB */
	FUNCT3_OP_SLL      = 3'b001,
	FUNCT3_OP_SLT      = 3'b010,
	FUNCT3_OP_SLTU     = 3'b011,
	FUNCT3_OP_XOR      = 3'b100,
	FUNCT3_OP_SR       = 3'b101, /* SRL and SRA */
	FUNCT3_OP_OR       = 3'b110,
	FUNCT3_OP_AND      = 3'b111
} funct3_op_t;

typedef enum logic [2:0] {
	FUNCT3_MISC_MEM_FENCE   = 3'b000,
	FUNCT3_MISC_MEM_FENCE_I = 3'b001
} funct3_miscm_mem_t;

/* tiny5 definitions */

typedef enum logic {
	NEXT_PC_SEL_PC,
	NEXT_PC_SEL_PC_4
} next_pc_sel_t;

typedef enum logic {
	REGFILE_IN_SEL_ALU_OUT
} regfile_in_sel_t;

typedef enum logic {
	ALU_OP_LUI
} alu_op_t;

endpackage
