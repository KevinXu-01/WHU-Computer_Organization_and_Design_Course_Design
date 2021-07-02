//instruction register and cut the instruction
module IF(
        input [31:0] instruction,
        output reg[5:0] op,
        output reg[4:0] rs,
        output reg[4:0] rt,
        output reg[4:0] rd,
        output reg[4:0] sa,
        output reg[5:0] funct, // for R-type instruction
        output reg[15:0] IMM, // for I-type instruction
        output reg[25:0] addr // for J-type instruction 
    );

    initial begin
        op = 5'b00000;
        rs = 5'b00000;
        rt = 5'b00000;
        rd = 5'b00000;
    end

    always@(instruction) 
    begin
        op = instruction[31:26];
        rs = instruction[25:21];
        rt = instruction[20:16];
        rd = instruction[15:11];
        sa = instruction[10:6];
	funct = instruction[5:0];// for R-type instruction
        IMM = instruction[15:0]; // for I-type instruction
        addr = instruction[25:0]; // for J-type instruction
    end
endmodule
