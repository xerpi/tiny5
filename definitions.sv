package definitions;

import cache_interface_types::*;

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
	FUNCT3_OP_MULDIV_MUL    = 3'b000,
	FUNCT3_OP_MULDIV_MULH   = 3'b001,
	FUNCT3_OP_MULDIV_MULHSU = 3'b010,
	FUNCT3_OP_MULDIV_MULHU  = 3'b011,
	FUNCT3_OP_MULDIV_DIV    = 3'b100,
	FUNCT3_OP_MULDIV_DIVU   = 3'b101,
	FUNCT3_OP_MULDIV_REM    = 3'b110,
	FUNCT3_OP_MULDIV_REMU   = 3'b111
} funct3_op_muldiv_t;

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

typedef enum logic [6:0] {
	FUNCT7_OP_MULDIV = 7'b0000001
} funct7_op_t;

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

typedef enum logic [3:0] {
	ALU_OP_IN1_PASSTHROUGH,
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

/* Multiplexer select */

typedef enum logic {
	NEXT_PC_SEL_PC_4,
	NEXT_PC_SEL_ALU_OUT
} next_pc_sel_t;

typedef enum logic [1:0] {
	REGFILE_WR_SEL_ALU_OUT,
	REGFILE_WR_SEL_DMEM_RD_DATA,
	REGFILE_WR_SEL_PC_4,
	REGFILE_WR_SEL_CSR_OUT
} regfile_wr_sel_t;

typedef enum logic {
	ALU_IN1_SEL_REGFILE_OUT1,
	ALU_IN1_SEL_IMM
} alu_in1_sel_t;

typedef enum logic [1:0] {
	ALU_IN2_SEL_REGFILE_OUT2,
	ALU_IN2_SEL_IMM,
	ALU_IN2_SEL_PC,
	ALU_IN2_SEL_CSR_OUT
} alu_in2_sel_t;

/* Pipeline stage registers (IF - ID - EX - MEM - WB) */

typedef struct packed {
	logic [31:0] pc;
	instruction_t instr;
	logic valid;
} pipeline_id_reg_t;

typedef struct packed {
	logic [31:0] pc;
	logic [31:0] imm;
	logic [31:0] regfile_out1;
	logic [31:0] regfile_out2;
	logic [31:0] csr_out;
	logic [4:0] regfile_wr_addr;
	logic [11:0] csr_wr_addr;
	logic regfile_we;
	logic csr_we;
	alu_op_t alu_op;
	alu_in1_sel_t alu_in1_sel;
	alu_in2_sel_t alu_in2_sel;
	compare_unit_op_t compare_unit_op;
	regfile_wr_sel_t regfile_wr_sel;
	cache_access_size_t dcache_rd_size;
	cache_access_size_t dcache_wr_size;
	logic dcache_wr_enable;
	logic dcache_rd_signed;
	logic is_branch;
	logic is_jump;
	logic is_ecall;
	logic is_mem_access;
	logic valid;
} pipeline_ex_reg_t;

typedef struct packed {
	logic [31:0] pc;
	logic [31:0] regfile_out2;
	logic [31:0] csr_out;
	logic [4:0] regfile_wr_addr;
	logic [11:0] csr_wr_addr;
	logic regfile_we;
	logic csr_we;
	logic [31:0] alu_out;
	logic cmp_unit_res;
	regfile_wr_sel_t regfile_wr_sel;
	cache_access_size_t dcache_rd_size;
	cache_access_size_t dcache_wr_size;
	logic dcache_wr_enable;
	logic dcache_rd_signed;
	logic is_branch;
	logic is_jump;
	logic is_ecall;
	logic is_mem_access;
	logic valid;
} pipeline_mem_reg_t;

typedef struct packed {
	logic [31:0] pc;
	logic [31:0] csr_out;
	logic [4:0] regfile_wr_addr;
	logic [11:0] csr_wr_addr;
	logic regfile_we;
	logic csr_we;
	logic [31:0] alu_out;
	regfile_wr_sel_t regfile_wr_sel;
	logic [31:0] dcache_rd_data;
	logic is_ecall;
	logic valid;
} pipeline_wb_reg_t;

typedef struct packed {
	logic [31:0] op1;
	logic [31:0] op2;
	funct3_op_muldiv_t muldiv_op;
	logic [4:0] regfile_wr_addr;
	logic valid;
} pipeline_mul_m0_reg_t;

typedef struct packed {
	logic [31:0] muldiv_out;
	logic [4:0] regfile_wr_addr;
	logic valid;
} pipeline_mul_m1234_reg_t;

typedef struct packed {
	logic [31:0] muldiv_out;
	logic [4:0] regfile_wr_addr;
	logic valid;
} pipeline_mul_wmul_reg_t;

/* Pipeline decode and control signals */

typedef struct packed {
	logic regfile_we;
	logic csr_we;
	alu_op_t alu_op;
	alu_in1_sel_t alu_in1_sel;
	alu_in2_sel_t alu_in2_sel;
	funct3_op_muldiv_t muldiv_op;
	compare_unit_op_t compare_unit_op;
	regfile_wr_sel_t regfile_wr_sel;
	cache_access_size_t dcache_rd_size;
	cache_access_size_t dcache_wr_size;
	logic dcache_wr_enable;
	logic dcache_rd_signed;
	logic is_branch;
	logic is_jump;
	logic is_ecall;
	logic is_mem_access;
	logic is_muldiv;
} decode_out_t;

typedef enum logic [1:0] {
	ALU_OUT_BYPASS_FROM_NONE,
	ALU_OUT_BYPASS_FROM_EX,
	ALU_OUT_BYPASS_FROM_MEM,
	ALU_OUT_BYPASS_FROM_WB
} alu_out_bypass_from_t;

typedef struct packed {
	/* IF stage */
	next_pc_sel_t next_pc_sel;
	logic pc_reg_stall;
	/* ID stage */
	logic id_reg_stall;
	logic id_reg_valid;
	/* EX stage */
	decode_out_t decode_out;
	alu_out_bypass_from_t alu_out_to_reg1_bypass;
	alu_out_bypass_from_t alu_out_to_reg2_bypass;
	logic ex_reg_stall;
	logic ex_reg_valid;
	/* MEM stage */
	logic mem_reg_stall;
	logic mem_reg_valid;
	logic mem_sb_put_enable;
	logic mem_sb_get_enable;
	logic mem_valid_load;
	logic mem_use_sb_snoop_data;
	/* WB stage */
	logic wb_reg_valid;
	/* MUL_M0 stage */
	logic mul_m0_reg_stall;
	logic mul_m0_reg_valid;
	/* MUL_M1 stage */
	logic mul_m1_reg_stall;
	/* MUL_M2 stage */
	logic mul_m2_reg_stall;
	/* MUL_M3 stage */
	logic mul_m3_reg_stall;
	/* MUL_M4 stage */
	logic mul_m4_reg_stall;
} pipeline_control_t;

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

function data_hazard_raw_check(input instruction_t instr_read, input logic [4:0] write_rd);
	return (write_rd != 0) &&
		((instruction_reads_from_regfile_rs1(instr_read) &&
			(instr_read.common.rs1 == write_rd)) ||
		(instruction_reads_from_regfile_rs2(instr_read) &&
			(instr_read.common.rs2 == write_rd)));
endfunction

function stage_will_write_alu_to_regfile(input logic rf_we, input logic [4:0] rf_wr_addr,
					 input regfile_wr_sel_t rf_wr_sel);
	return rf_we && (rf_wr_addr != 0) && (rf_wr_sel == REGFILE_WR_SEL_ALU_OUT);
endfunction

endpackage
