`include "define.vh"


/**
 * MIPS 5-stage pipeline CPU Core, including data path and co-processors.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module mips_core (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	
	// interrupt
	input wire ir_in,
	
	// debug
	`ifdef DEBUG
	input wire debug_en,  // debug enable
	input wire debug_step,  // debug step clock
	input wire [6:0] debug_addr,  // debug address
	output wire [31:0] debug_data,  // debug data
	`endif
	// instruction interfaces
	output wire inst_ren,  // instruction read enable signal
	output wire [31:0] inst_addr,  // address of instruction needed
	input wire [31:0] inst_data,  // instruction fetched
	// memory interfaces
	output wire mem_ren,  // memory read enable signal
	output wire mem_wen,  // memory write enable signal
	output wire [31:0] mem_addr,  // address of memory
	output wire [31:0] mem_dout,  // data writing to memory
	input wire [31:0] mem_din  // data read from memory
	);
	
	// control signals
	wire [31:0] inst_data_ctrl;
	
	wire [2:0] pc_src_ctrl;
	wire imm_ext_ctrl;
	wire [1:0] exe_a_src_ctrl, exe_b_src_ctrl;
	wire [3:0] exe_alu_oper_ctrl;
	wire exe_alu_sign;
	wire mem_ren_ctrl;
	wire mem_wen_ctrl;
	wire [1:0] wb_addr_src_ctrl;
	wire wb_data_src_ctrl;
	wire wb_wen_ctrl;
	
	wire is_branch_exe, is_branch_mem;
	wire [4:0] regw_addr_exe, regw_addr_mem;
	wire wb_wen_exe, wb_wen_mem;
	
	wire if_rst, if_en, if_valid;
	wire id_rst, id_en, id_valid;
	wire exe_rst, exe_en, exe_valid;
	wire mem_rst, mem_en, mem_valid;
	wire wb_rst, wb_en, wb_valid;
	
	// forwarding
	wire mem_ren_exe, mem_ren_mem;
	wire wb_wen_wb;
	wire [4:0] regw_addr_wb;
	wire [1:0] exe_fwd_a_ctrl;
	wire [2:0] exe_fwd_b_ctrl;
	
	// new forwarding
	wire is_load_ctrl, is_store_ctrl;
	wire is_load_exe;
	wire is_load_mem;
	wire fwd_m_ctrl;
//	wire is_branch_id;

	// interrupt
	wire [1:0] cp_oper;
    wire [4:0] cp_addr_r;
    wire [31:0] cp_data_r;
    wire [4:0] cp_addr_w;
    wire [31:0] cp_data_w;
    wire ir_en;
    wire [31:0] ret_addr;
    wire jump_en;
    wire [31:0] jump_addr;
	
	// controller
	controller CONTROLLER (
		.clk(clk),
		.rst(rst),
		
		.mem_ren_exe(mem_ren_exe),
		.mem_ren_mem(mem_ren_mem),
		.wb_wen_wb(wb_wen_wb),
		.regw_addr_wb(regw_addr_wb),
		.exe_fwd_a(exe_fwd_a_ctrl),
		.exe_fwd_b(exe_fwd_b_ctrl),
		
		// interrupt
		.cp_oper(cp_oper),
		.ir_en(ir_en),
		.jump_en(jump_en),
		
		// new forwarding
		.is_load(is_load_ctrl),
		.is_store(is_store_ctrl),
		.is_load_exe(is_load_exe),
		.is_load_mem(is_load_mem),
		.fwd_m(fwd_m_ctrl),
//		.is_branch_id(is_branch_id),
		
		`ifdef DEBUG
		.debug_en(debug_en),
		.debug_step(debug_step),
		`endif
		.inst(inst_data_ctrl),
		.is_branch_exe(is_branch_exe),
		.regw_addr_exe(regw_addr_exe),
		.wb_wen_exe(wb_wen_exe),
		.is_branch_mem(is_branch_mem),
		.regw_addr_mem(regw_addr_mem),
		.wb_wen_mem(wb_wen_mem),
		.pc_src(pc_src_ctrl),
		.imm_ext(imm_ext_ctrl),
		.exe_a_src(exe_a_src_ctrl),
		.exe_b_src(exe_b_src_ctrl),
		.exe_alu_oper(exe_alu_oper_ctrl),
		.sign(exe_alu_sign),
		.mem_ren(mem_ren_ctrl),
		.mem_wen(mem_wen_ctrl),
		.wb_addr_src(wb_addr_src_ctrl),
		.wb_data_src(wb_data_src_ctrl),
		.wb_wen(wb_wen_ctrl),
		.unrecognized(),
		.if_rst(if_rst),
		.if_en(if_en),
		.if_valid(if_valid),
		.id_rst(id_rst),
		.id_en(id_en),
		.id_valid(id_valid),
		.exe_rst(exe_rst),
		.exe_en(exe_en),
		.exe_valid(exe_valid),
		.mem_rst(mem_rst),
		.mem_en(mem_en),
		.mem_valid(mem_valid),
		.wb_rst(wb_rst),
		.wb_en(wb_en),
		.wb_valid(wb_valid)
	);
	
	// data path
	datapath DATAPATH (
		.clk(clk),
		
		.mem_ren_exe(mem_ren_exe),
		.mem_ren_mem(mem_ren_mem),
		.wb_wen_wb(wb_wen_wb),
		.regw_addr_wb(regw_addr_wb),
		.exe_fwd_a_ctrl(exe_fwd_a_ctrl),
		.exe_fwd_b_ctrl(exe_fwd_b_ctrl),
		
		// interrupt
		.cp_addr_r(cp_addr_r),//out 5
		.cp_data_r(cp_data_r),//in 32
		.cp_data_w(cp_data_w),//out 32
		.ret_addr(ret_addr),//out 32
		.jump_en(jump_en),//in 1
		.jump_addr(jump_addr), //in 32
		
		// new forwarding.
		.is_load_ctrl(is_load_ctrl),
		.is_store_ctrl(is_store_ctrl),
		.is_load_exe(is_load_exe),
		.is_load_mem(is_load_mem),
		.fwd_m_ctrl(fwd_m_ctrl),
//		.is_branch_id(is_branch_id),
		
		`ifdef DEBUG
		.debug_addr(debug_addr[5:0]),
		.debug_data(debug_data),
		`endif
		.inst_data_id(inst_data_ctrl),
		.is_branch_exe(is_branch_exe),
		.regw_addr_exe(regw_addr_exe),
		.wb_wen_exe(wb_wen_exe),
		.is_branch_mem(is_branch_mem),
		.regw_addr_mem(regw_addr_mem),
		.wb_wen_mem(wb_wen_mem),
		.pc_src_ctrl(pc_src_ctrl),
		.imm_ext_ctrl(imm_ext_ctrl),
		.exe_a_src_ctrl(exe_a_src_ctrl),
		.exe_b_src_ctrl(exe_b_src_ctrl),
		.exe_alu_oper_ctrl(exe_alu_oper_ctrl),
		.exe_alu_sign(exe_alu_sign),
		.mem_ren_ctrl(mem_ren_ctrl),
		.mem_wen_ctrl(mem_wen_ctrl),
		.wb_addr_src_ctrl(wb_addr_src_ctrl),
		.wb_data_src_ctrl(wb_data_src_ctrl),
		.wb_wen_ctrl(wb_wen_ctrl),
		.if_rst(if_rst),
		.if_en(if_en),
		.if_valid(if_valid),
		.inst_ren(inst_ren),
		.inst_addr(inst_addr),
		.inst_data(inst_data),
		.id_rst(id_rst),
		.id_en(id_en),
		.id_valid(id_valid),
		.exe_rst(exe_rst),
		.exe_en(exe_en),
		.exe_valid(exe_valid),
		.mem_rst(mem_rst),
		.mem_en(mem_en),
		.mem_valid(mem_valid),
		.mem_ren(mem_ren),
		.mem_wen(mem_wen),
		.mem_addr(mem_addr),
		.mem_dout(mem_dout),
		.mem_din(mem_din),
		.wb_rst(wb_rst),
		.wb_en(wb_en),
		.wb_valid(wb_valid)
	);


	assign cp_addr_w = cp_addr_r;

	cp0 CP0(
		.clk(clk),
		`ifdef DEBUG
		.debug_addr(debug_addr_1),
		.debug_data(debug_data_1),
		`endif
		.oper(cp_oper),//in
		.addr_r(cp_addr_r),//in
		.data_r(cp_data_r),//out
		.addr_w(cp_addr_w),//in
		.data_w(cp_data_w),//in
		.rst(rst),
		.ir_en(ir_en),//in
		.ir_in(ir_in),//in
		.ret_addr(ret_addr),//in
		.jump_en(jump_en),//out
		.jump_addr(jump_addr)//out
	);


endmodule
