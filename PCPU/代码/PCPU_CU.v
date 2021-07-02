//Control Unit
///////////////////////////////////changed
module ControlUnit(
        input [5:0] op,//instruction[31:26]
	input [5:0] funct,//instruction[5:0]
        input zero,//zero flag, from ALU, used in bne & beq instruction
        output reg ExtSel,//extension, 0 zero extension, 1 sign extension
        output reg RegDst,// Register Write Source, 0 instruction[20:16], 1 instruction[15:11],or 'A3'
        output reg RegWrite,//in WriteBack stage, 'RFWr', 1 write
        output reg [1:0]ALUSrcA,//ALU oprand A source
        output reg ALUSrcB,//ALU oprand B source
        output reg [1:0]PCSrc,//Next PC source
        output reg [3:0]ALUOp,//ALUOp
        output reg MemRead,//Memory Read(load word/half word/byte/half byte),'DMRd'
        output reg MemWrite,//Memory Write(save word/half word/byte/half byte),'DMWr'
	output reg MemtoReg,//in WriteBack stage,Write ALU result or Memory back to Register
	output reg ShiftIndex,//input source for Shifter, 0 Instruction[10:6](srl/sll/sra), 1 Instruction[25:21](srlv/sllv/srav)
	output reg ShiftDirection,//0 left(sll/sllv), 1 right(srl/srlv)
	output reg JalAndJalr//1 jal/jalr
    );

    initial
    begin
        MemRead = 0;
        MemWrite = 0;
    end

    always@(op or zero or funct)
    begin
	ExtSel = (op == 6'b001000||op == 6'b100011||op == 6'b101011||op == 6'b100000||op == 6'b100001||op == 6'b101000||op == 6'b101001) ? 1 : 0;//addi/lw/sw/lb/lh/sb/sh; //detele lbu/lhu
	PCSrc[0] = (op == 6'b000000&&funct == 6'b001001||op == 6'b000000&&funct == 6'b001000||(op == 6'b000100&&zero)||(op == 6'b000101&&!zero)) ? 1 : 0;//jalr/jr/beq&zero/bne&~zero
	PCSrc[1] = (op == 6'b000010||op == 6'b000011||(op == 6'b000000&&funct == 6'b001001)||(op == 6'b000000&&funct == 6'b001000)) ? 1 : 0;//j/jal/jalr/jr
        MemRead = (op == 6'b100000||op == 6'b100100||op == 6'b100001||op == 6'b100101||op == 6'b100011) ? 1 : 0;//lb/lbu/lh/lhu/lw
	MemWrite = (op == 6'b101000||op == 6'b101001||op == 6'b101011) ? 1 : 0;//sb/sh/sw
        MemtoReg = (op == 6'b100000||op == 6'b100100||op == 6'b100001||op == 6'b100101||op == 6'b100011) ? 1 : 0;//lb/lbu/lh/lhu/lw
        ALUSrcA[1] = (op == 6'b000000&&funct == 6'b000010||op == 6'b000000&&funct == 6'b000000||op == 6'b000000&&funct == 6'b000110||op == 6'b000000&&funct == 6'b000100);//srl/sll/srlv/sllv

	//ShiftIndex
	if(op == 6'b000000&&funct == 6'b000111||op == 6'b000000&&funct == 6'b000110||op == 6'b000000&&funct == 6'b000100)//srav/srlv/sllv
	   begin
		ShiftIndex = 1;
	   end
	else if(op == 6'b000000&&funct == 6'b000011||op == 6'b000000&&funct == 6'b000010||op == 6'b000000&&funct == 6'b000000)//sra/srl/sll
	   begin
		ShiftIndex = 0;
	   end
	
	//ShiftDirection
	if(op == 6'b000000&&funct == 6'b000010||op == 6'b000000&&funct == 6'b000110)//srl/srlv
	   begin
		ShiftDirection = 1;
	   end
	else if(op == 6'b000000&&funct == 6'b000000||op == 6'b000000&&funct == 6'b000100)//sll/sllv
	   begin
		ShiftDirection = 0;
	   end

	JalAndJalr = (op == 6'b000011||op == 6'b000000&&funct == 6'b001001) ? 1 : 0;//jal and jalr

        case(op)
            6'b000000:
                begin
		    case(funct)
			//add
			6'b100000:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 0;
				ALUSrcB = 0;
				ALUOp = 4'b0001;
			    end
			//sub
			6'b100010:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 0;
				ALUSrcB = 0;
				ALUOp = 4'b0010;
			    end
			//and
			6'b100100:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 0;
				ALUSrcB = 0;
				ALUOp = 4'b0011;
			    end
			//or
			6'b100101:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 0;
				ALUSrcB = 0;
				ALUOp = 4'b0100;
			    end
			//slt
			6'b101010:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 0;
				ALUSrcB = 0;
				ALUOp = 4'b0101;
			    end
			//sltu
			6'b101011:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 0;
				ALUSrcB = 0;
				ALUOp = 4'b0110;
			    end
			//addu
			6'b100001:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 0;
				ALUSrcB = 0;
				ALUOp = 4'b0111;
			    end
			//subu
			6'b100011:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 0;
				ALUSrcB = 0;
				ALUOp = 4'b1000;
			    end
			//sll
			6'b000000:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 1;
				ALUSrcB = 0;
				ALUOp = 4'b0000;
			    end
			//sllv
			6'b000100:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 1;
				ALUSrcB = 0;
				ALUOp = 4'b0000;
			    end
			//srl
			6'b000010:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 1;
				ALUSrcB = 0;
				ALUOp = 4'b0000;
			    end
			//srlv
			6'b000110:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 1;
				ALUSrcB = 0;
				ALUOp = 4'b0000;
			    end
			//nor
			6'b100111:
			    begin
				RegDst = 1;
				RegWrite = 1;
				ALUSrcA[0] = 0;
				ALUSrcB = 0;
				ALUOp = 4'b1010;
			    end
			//jalr
			6'b001001:
			    begin
				RegDst = 0;
				RegWrite = 1;
				ALUSrcA[0] = 0;
				ALUSrcB = 0;
				ALUOp = 4'b0000;
			    end
			//jr
			6'b001000:
			    begin
				RegDst = 0;
				RegWrite = 0;
				ALUSrcA[0] = 0;
				ALUSrcB = 0;
				ALUOp = 4'b0000;
			    end
		    endcase
                end
            //addi
            6'b001000:
                begin
                    RegDst = 0;
                    RegWrite = 1;
                    ALUSrcA[0] = 0;
                    ALUSrcB = 1;
                    ALUOp = 4'b0001;
                end
            //andi
            6'b001100:
                begin
                    RegDst = 0;
                    RegWrite = 1;
                    ALUSrcA[0] = 0;
                    ALUSrcB = 1;
                    ALUOp = 4'b0011;
                end
            //ori
            6'b001101:
                begin
                    RegDst = 0;
                    RegWrite = 1;
                    ALUSrcA[0] = 0;
                    ALUSrcB = 1;
                    ALUOp = 4'b0100;
                end
            //slti
            6'b001010:
                begin
                    RegDst = 0;
                    RegWrite = 1;
                    ALUSrcA[0] = 0;
                    ALUSrcB = 1;
                    ALUOp = 4'b0101;
                end
            //lw
            6'b100011:
                begin
                    RegDst = 0;
                    RegWrite = 1;
                    ALUSrcA[0] = 0;
                    ALUSrcB = 1;
                    ALUOp = 4'b0001;
                end
            //sw
            6'b101011:
                begin
                    RegDst = 0;
                    RegWrite = 0;
                    ALUSrcA[0] = 0;
                    ALUSrcB = 1;
                    ALUOp = 4'b0001;
                end
            //beq
            6'b000100:
                begin
                    RegDst = 0;
                    RegWrite = 0;
                    ALUSrcA[0] = 0;
                    ALUSrcB = 0;
                    ALUOp = 4'b0010;
                end
            //bne
            6'b000101:
                begin
                    RegDst = 0;
                    RegWrite = 0;
                    ALUSrcA[0] = 0;
                    ALUSrcB = 0;
                    ALUOp = 4'b0010;
                end
            //j
            6'b000010:
                begin
                    RegDst = 0;
                    RegWrite = 0;
                    ALUSrcA[0] = 0;
                    ALUSrcB = 0;
                    ALUOp = 4'b0000;
                end
            //jal
            6'b000011:
                begin
                    RegDst = 0;
                    RegWrite = 1;
                    ALUSrcA[0] = 0;
                    ALUSrcB = 0;
                    ALUOp = 4'b0000;
                end
            //lui
            6'b001111:
                begin
                    RegDst = 0;
                    RegWrite = 1;
                    ALUSrcA[0] = 0;
                    ALUSrcB = 1;
                    ALUOp = 4'b1011;
                end
        endcase
    end
endmodule

