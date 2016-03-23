`include "define.vh"


/**
 * Controller for MIPS 5-stage pipelined CPU.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module controller (/*AUTOARG*/
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// debug
	`ifdef DEBUG
	input wire debug_en,  // debug enable
	input wire debug_step,  // debug step clock
	`endif
	// instruction decode
	input wire [31:0] inst,  // instruction


	output reg [2:0] pc_src,  // how would PC change to next
	output reg imm_ext,  // whether using sign extended to immediate data
	output reg [1:0] exe_a_src,  // data source of operand A for ALU
	output reg [1:0] exe_b_src,  // data source of operand B for ALU
	output reg [3:0] exe_alu_oper,  // ALU operation type
	output reg mem_ren,  // memory read enable signal
	output reg mem_wen,  // memory write enable signal
	output reg [1:0] wb_addr_src,  // address source to write data back to registers
	output reg wb_data_src,  // data source of data being written back to registers
	output reg wb_wen,  // register write enable signal
	output reg unrecognized,  // whether current instruction can not be recognized
	// debug control
	output reg cpu_rst,  // cpu reset signal
	output reg cpu_en  // cpu enable signal
	);
	
	`include "mips_define.vh"
	
	// instruction decode
	always @(*) begin

		// decode 之前，给一些信号赋默认值。

		pc_src = PC_NEXT;
		imm_ext = 0;
		exe_a_src = EXE_A_RS;
		exe_b_src = EXE_B_RT;
		exe_alu_oper = EXE_ALU_ADD;
		mem_ren = 0;
		mem_wen = 0;
		wb_addr_src = WB_ADDR_RD;	// wb_addr_src 是写回寄存器的地址，默认写回 RD。
		wb_data_src = WB_DATA_ALU;
		wb_wen = 0;					// 寄存器写使能。
		unrecognized = 0;

		// 开始解释 opcode：
		// 先解释前 6 位，确定指令类型：R 型、I 型、J 型。
		case (inst[31:26])

			// 前 6 位为 000000，确定为 R 型指令。
			// 根据 [5:0] 确定是哪一条指令：
			// 结合 MIPS 指令集表格，根据指令的行为设置相应的信号。
			INST_R: begin
				case (inst[5:0])
					R_FUNC_JR: begin
						pc_src = PC_JR;
					end
					R_FUNC_ADD: begin
						exe_alu_oper = EXE_ALU_ADD;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
					end
					R_FUNC_SUB: begin
						exe_alu_oper = EXE_ALU_SUB;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
					end
					R_FUNC_AND: begin
						exe_alu_oper = EXE_ALU_AND;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
					end
					R_FUNC_OR: begin
						exe_alu_oper = EXE_ALU_OR;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
					end
					R_FUNC_SLT: begin
						exe_alu_oper = EXE_ALU_SLT;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
					end
					default: begin
						unrecognized = 1;
					end
				endcase
			end

			// 检测到 J 型指令
			INST_J: begin
				pc_src = PC_JUMP;
			end
			INST_JAL: begin
				pc_src = PC_JUMP;
				exe_a_src = EXE_A_LINK;		// 实际上是下一条指令的地址(PC+4)
				exe_b_src = EXE_B_LINK;
				exe_alu_oper = EXE_ALU_OR;
				wb_addr_src = WB_ADDR_LINK;		// 实际上是 GPR_RA, $31 寄存器。
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end

			// 检测到其他类型的指令：
			// # 实验报告点：我们需要自己实现 BNE 指令
			// # BNE 和 BEQ 的行为相似，都是先判断再计算。
			// # 在译码阶段，我们只能指定［判断通过后，执行什么计算行为］。
			// # 我们面临的问题是：找到在哪里执行这个判断。
			INST_BNE: begin
				pc_src = PC_BNE;
				exe_a_src = EXE_A_BRANCH;	// 实际上是下一条指令的地址(PC+4)
				exe_b_src = EXE_B_BRANCH;
				exe_alu_oper = EXE_ALU_ADD;
				imm_ext = 1;
			end
			INST_BEQ: begin
				pc_src = PC_BEQ;
				exe_a_src = EXE_A_BRANCH;
				exe_b_src = EXE_B_BRANCH;
				exe_alu_oper = EXE_ALU_ADD;
				imm_ext = 1;
			end

			// I 型信号
			INST_ADDI: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end
			INST_ANDI: begin
				imm_ext = 0;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_AND;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end
			INST_ORI: begin
				imm_ext = 0;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_OR;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end
			INST_LW: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_ren = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_MEM;
				wb_wen = 1;		// 写寄存器使能
			end
			INST_SW: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_wen = 1;
			end
			default: begin
				unrecognized = 1;
			end
		endcase
	end
	
	// debug control
	`ifdef DEBUG
	reg debug_step_prev;
	
	always @(posedge clk) begin
		debug_step_prev <= debug_step;
	end
	`endif
	
	always @(*) begin
		cpu_rst = 0;
		cpu_en = 1;
		if (rst) begin
			cpu_rst = 1;
		end
		`ifdef DEBUG
		// suspend and step execution
		// 如何实现单步执行：
		// 要让 CPU 运行，cpu_en 必须为 1，下方的 else if 必须不执行。
		// 要让 else if 不执行，或者 debug_en 为0，或者后面的整个判断为 0。
		// 也就是(~debug_step_prev && debug_step) 要为1。
		// 也就是说，必须按下按钮(debug_step=1), 而且按下的同时(debug_step_prev=0),
		// 也就是说上次 debug_step 为 1 之后必须至少经过了一个时钟周期。
		else if ((debug_en) && ~(~debug_step_prev && debug_step)) begin
			cpu_en = 0;
		end
		`endif
	end
	
endmodule
