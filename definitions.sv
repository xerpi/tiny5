package definitions;

/* RISC-V ISA definitions */

typedef struct packed {
	logic [6:0] funct7;
	logic [4:0] rs2;
	logic [4:0] rs1;
	logic [2:0] funct3;
	logic [4:0] rd;
	logic [6:0] opcode;
} instruction_rtype_t;

typedef struct packed {
	logic [11:0] imm;
	logic [4:0] rs1;
	logic [2:0] funct3;
	logic [4:0] rd;
	logic [6:0] opcode;
} instruction_itype_t;

typedef struct packed {
	logic [6:0] imm5;
	logic [4:0] rs2;
	logic [4:0] rs1;
	logic [2:0] funct3;
	logic [4:0] imm0;
	logic [6:0] opcode;
} instruction_stype_t;

typedef struct packed {
	logic imm12;
	logic [5:0] imm5;
	logic [4:0] rs2;
	logic [4:0] rs1;
	logic [2:0] funct3;
	logic [3:0] imm1;
	logic imm11;
	logic [6:0] opcode;
} instruction_btype_t;

typedef struct packed {
	logic [19:0] imm;
	logic [4:0] rd;
	logic [6:0] opcode;
} instruction_utype_t;

typedef struct packed {
	logic imm20;
	logic [9:0] imm1;
	logic imm11;
	logic [7:0] imm12;
	logic [4:0] rd;
	logic [6:0] opcode;
} instruction_jtype_t;

typedef union packed {
	logic [31:0] bits;
	struct packed {
		logic [6:0] skip1;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] skip0;
		logic [4:0] rd;
		logic [6:0] opcode;
	} common;
	instruction_rtype_t rtype;
	instruction_itype_t itype;
	instruction_stype_t stype;
	instruction_btype_t btype;
	instruction_utype_t utype;
	instruction_jtype_t jtype;
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
	OPCODE_MISC_MEM = 7'b0001111,
	OPCODE_SYSTEM   = 7'b1110011
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
} funct3_misc_mem_t;

typedef enum logic [2:0] {
	FUNCT3_SYSTEM_PRIV   = 3'b000,
	FUNCT3_SYSTEM_CSRRW  = 3'b001,
	FUNCT3_SYSTEM_CSRRS  = 3'b010,
	FUNCT3_SYSTEM_CSRRC  = 3'b011,
	FUNCT3_SYSTEM_CSRRWI = 3'b101,
	FUNCT3_SYSTEM_CSRRSI = 3'b110,
	FUNCT3_SYSTEM_CSRRCI = 3'b111
} funct3_system_t;

typedef enum logic [11:0] {
	FUNCT12_SYSTEM_PRIV_ECALL  = 12'b000000000000,
	FUNCT12_SYSTEM_PRIV_EBREAK = 12'b000000000001
} funct12_system_priv_t;

typedef enum logic [11:0] {
	CSR_REG_CYCLE    = 12'hC00,
	CSR_REG_TIME     = 12'hC01,
	CSR_REG_INSTRET  = 12'hC02,
	CSR_REG_CYCLEH   = 12'hC80,
	CSR_REG_TIMEH    = 12'hC81,
	CSR_REG_INSTRETH = 12'hC82
} csr_reg_t;

/* tiny5 definitions */

/* Multiplexer select */

typedef enum logic {
	NEXT_PC_SEL_PC_4,
	NEXT_PC_SEL_ALU_OUT
} next_pc_sel_t;

typedef enum logic [2:0] {
	REGFILE_IN_SEL_ALU_OUT,
	REGFILE_IN_SEL_PC_4,
	REGFILE_IN_SEL_MEM_RD,
	REGFILE_IN_SEL_MEM_RD_SEXT8,
	REGFILE_IN_SEL_MEM_RD_SEXT16,
	REGFILE_IN_SEL_CSR_OUT
} regfile_in_sel_t;

typedef enum logic [1:0] {
	ALU_IN1_SEL_REGFILE_OUT1,
	ALU_IN1_SEL_PC,
	ALU_IN1_SEL_CSR_OUT
} alu_in1_sel_t;

typedef enum logic [1:0] {
	ALU_IN2_SEL_REGFILE_OUT2,
	ALU_IN2_SEL_IMM,
	ALU_IN2_SEL_CSR_OUT
} alu_in2_sel_t;

typedef enum logic [3:0] {
	ALU_OP_IN1_PASSTHROUGH,
	ALU_OP_IN2_PASSTHROUGH,
	ALU_OP_ADD,
	ALU_OP_SUB,
	ALU_OP_SLL,
	ALU_OP_SLT,
	ALU_OP_SLTU,
	ALU_OP_XOR,
	ALU_OP_SRL,
	ALU_OP_SRA,
	ALU_OP_OR,
	ALU_OP_AND
} alu_op_t;

typedef enum logic [2:0] {
	COMPARE_UNIT_OP_EQ,
	COMPARE_UNIT_OP_NE,
	COMPARE_UNIT_OP_LT,
	COMPARE_UNIT_OP_GE,
	COMPARE_UNIT_OP_LTU,
	COMPARE_UNIT_OP_GEU
} compare_unit_op_t;

typedef enum logic [1:0] {
	MEM_ACCESS_SIZE_BYTE,
	MEM_ACCESS_SIZE_HALF,
	MEM_ACCESS_SIZE_WORD
} mem_access_size_t;

/* Pipeline stage registers (IF - ID - EX - MEM - WB) */

typedef struct packed {
	logic [31:0] pc;
	instruction_t instr;
	logic valid;
} pipeline_if_id_reg_t;

typedef struct packed {
	logic [31:0] pc;
	instruction_t instr;
	logic [31:0] imm;
	logic [31:0] regfile_out1;
	logic [31:0] regfile_out2;
	logic [31:0] csr_out;
	logic [4:0] regfile_rd;
	logic regfile_we;
	logic valid;
} pipeline_id_ex_reg_t;

typedef struct packed {
	logic [31:0] pc;
	instruction_t instr;
	logic [31:0] regfile_out2;
	logic [31:0] csr_out;
	logic [31:0] alu_out;
	logic cmp_unit_res;
	logic [4:0] regfile_rd;
	logic regfile_we;
	logic valid;
} pipeline_ex_mem_reg_t;

typedef struct packed {
	logic [31:0] pc;
	instruction_t instr;
	logic [31:0] csr_out;
	logic [31:0] alu_out;
	logic [31:0] dmem_rd_data;
	logic [4:0] regfile_rd;
	logic regfile_we;
	logic valid;
} pipeline_mem_wb_reg_t;

/* Pipeline per-stage control signals */

typedef struct packed {
	logic pc_we;
	next_pc_sel_t next_pc_sel;
	logic pc_reg_stall;
	logic if_id_reg_stall;
	logic if_id_reg_valid;
} pipeline_if_ctrl_t;

typedef struct packed {
	logic id_ex_reg_valid;
	logic regfile_we;
} pipeline_id_ctrl_t;

typedef struct packed {
	alu_op_t alu_op;
	alu_in1_sel_t alu_in1_sel;
	alu_in2_sel_t alu_in2_sel;
	compare_unit_op_t compare_unit_op;
	logic ex_mem_reg_valid;
} pipeline_ex_ctrl_t;

typedef struct packed {
	mem_access_size_t dmem_rd_size;
	mem_access_size_t dmem_wr_size;
	logic dmem_wr_enable;
} pipeline_mem_ctrl_t;

typedef struct packed {
	logic csr_we;
	regfile_in_sel_t regfile_in_sel;
} pipeline_wb_ctrl_t;

/* Helper functions */

function instruction_reads_from_regfile_rs1(input instruction_t instr);
	case (instr.common.opcode)
	OPCODE_JALR,
	OPCODE_BRANCH,
	OPCODE_LOAD,
	OPCODE_STORE,
	OPCODE_OP_IMM,
	OPCODE_OP:
		return 1;
	OPCODE_SYSTEM: begin
		case (instr.itype.funct3)
		FUNCT3_SYSTEM_CSRRW,
		FUNCT3_SYSTEM_CSRRS,
		FUNCT3_SYSTEM_CSRRC:
			return 1;
		default:
			return 0;
		endcase
	end
	default:
		return 0;
	endcase
endfunction

function instruction_reads_from_regfile_rs2(input instruction_t instr);
	case (instr.common.opcode)
	OPCODE_BRANCH,
	OPCODE_STORE,
	OPCODE_OP:
		return 1;
	default:
		return 0;
	endcase
endfunction

function instruction_writes_to_regfile(input instruction_t instr);
	case (instr.common.opcode)
	OPCODE_LUI,
	OPCODE_AUIPC,
	OPCODE_JAL,
	OPCODE_JALR,
	OPCODE_LOAD,
	OPCODE_OP_IMM,
	OPCODE_OP:
		return 1;
	OPCODE_SYSTEM: begin
		case (instr.itype.funct3)
		FUNCT3_SYSTEM_CSRRW,
		FUNCT3_SYSTEM_CSRRS,
		FUNCT3_SYSTEM_CSRRC,
		FUNCT3_SYSTEM_CSRRWI,
		FUNCT3_SYSTEM_CSRRSI,
		FUNCT3_SYSTEM_CSRRCI:
			return 1;
		default:
			return 0;
		endcase
	end
	default:
		return 0;
	endcase
endfunction

function data_hazard_raw_check(input instruction_t instr_read, input logic [4:0] write_rd);
	return (write_rd != 0) &&
		((instruction_reads_from_regfile_rs1(instr_read) &&
			(instr_read.common.rs1 == write_rd)) ||
		(instruction_reads_from_regfile_rs2(instr_read) &&
			(instr_read.common.rs2 == write_rd)));
endfunction

endpackage
