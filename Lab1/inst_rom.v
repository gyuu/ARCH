module inst_rom (
	input wire clk,
	input wire [31:0] addr,
	output wire [31:0] dout
	);
	
	parameter
		ADDR_WIDTH = 6;
	// ROM 地址的宽度是 6 位，说明 ROM 容量是 2^6 = 64 word = 64 * 4 = 256 Byte。
	
	reg [31:0] data [0:(1<<ADDR_WIDTH)-1];
	
	initial	begin
		$readmemh("inst_mem.hex", data);
	end
	
	// 只使用 addr 的最后 6 位来访问内存？！
	assign dout = (addr[31:ADDR_WIDTH] != 0) ? 32'b0 : data[addr[ADDR_WIDTH-1:0]];

//	always @(*) begin
//		if (addr[31:ADDR_WIDTH] != 0)
//			dout = 32'h0;
//		else
//			dout = data[addr[ADDR_WIDTH-1:0]];
//	end
	
endmodule
