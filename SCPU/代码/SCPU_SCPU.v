//top level design
module SCPU();
   reg clk, rst; //clk is clock, rst is reset
   initial
	begin
		$readmemh( "C:/Users/KevinXu/Desktop/testcode/extendedtest.dat" , SCPU_IM.rom); // load instructions into instruction memory
		//$readmemh( "mipstest_extloop.dat" , U_IM.ins_mem); // load instructions into instruction memory
		//$readmemh( "mipstestloopjal_sim.dat" , U_IM.ins_mem); // load instructions into instruction memory
		clk = 1;
		rst = 0;
		#5 rst = 1;
		#5 rst = 0;
	end	

	always
		#(50) clk = ~clk;
			

   //PC
   wire[31:0] PC;
   //NPC = NPC(in NPC)


   //NPC
   //RS = RD1;
   //PC = PC(in PC)
   //NPCOp = PCSrc(in ControlUnit)
   //IMM = addr(in IF)
   wire[31:0] NPC;


   //IM
   wire[6:0] Iaddr;  //Iaddr = PC[8:2]
   wire[31:0] IDataOut; //Instruction


   //IF
   //instruction = IDataOut(in IM)
   wire[5:0] op; //op also appears in ControlUnit, IDataOut[31:26]
   wire[4:0] rs; // A1(in RF), IDataOut[25:21]
   wire[4:0] rt; // A2(in RF), IDataOut[20:16]
   wire[4:0] rd;
   wire[4:0] sa;
   wire[5:0] funct; //funct also appears in ControlUnit
   wire[15:0] IMM;//for I-type instruction, different from IMM(addr in IF) in NPC
   wire[25:0] addr;


   //RF
   //RFWr = RegWrite(in ControlUnit)
   //A1 = rs(in IF)
   //A2 = rt(in IF)
   wire[4:0] RFWAddr1;// 	A3
   wire[4:0] RFWAddr2;//	mux2_5 RFW1(Ins[20:16],Ins[15:11],RegDst,RFWAddr2);	
	              //	mux2_5 RFW2(RFWAddr2,5'b11111,JalAndJalr,RFWAddr1);
		      //	RFWAddr1 is used for instantiation of RF
   wire[31:0] WD;
   wire[31:0] RD1;
   wire[31:0] RD2;


   //EXT
   wire[15:0] EXTDataIn;
   //EXTOp = ExtSel(in ControlUnit)
   wire[31:0] EXTDataOut;


   //DM
   //DMRd = MemRead(in ControlUnit)
   //DMWr = MemWrite(in ControlUnit)
   //half, byte, unsign(in ControlUnit)
   wire[6:0] Daddr;//(=ALUDataOut[6:0])
   //DDataIn = RD2(in RF)
   wire[31:0] DDataOut;


   //Shifter
   //Input = RD2(in RF)
   wire[4:0] ShifterIndex;
   wire[31:0] ShifterOut;

   //ALU
   wire[31:0] ALUDataIn1;//A
   wire[31:0] ALUDataIn2;//B
   //ALUOp = ALUOp(in ControlUnit)
   wire[31:0] ALUDataOut;
   wire Zero;//zero flag


   //CU
   //op = op(in IF)
   //funct = funct(in IF)
   //Zero = Zero (in ALU)
   wire ExtSel;
   wire RegDst;
   wire RegWrite;
   wire ALUSrcA;
   wire ALUSrcB;
   wire[1:0] PCSrc;
   wire[3:0] ALUOp;
   wire MemRead;
   wire MemWrite;
   wire MemtoReg;
   wire ShiftIndex;
   wire ShiftDirection;
   wire AorL;
   wire JalAndJalr;
   wire HalfAndByte;
   wire Byte;
   wire Half;
   wire unsign;

   //MUX
   wire[31:0] preRFDataIn;


   assign Iaddr = PC[8:2];
   assign Daddr = ALUDataOut[6:0];
   assign EXTDataIn = IMM;

//Instantiation of PC
   PC SCPU_PC(.clk(clk),.rst(rst),.NPC(NPC),.PC(PC));

//Instantiation of NPC
   NPC SCPU_NPC(.RS(RD1),.PC(PC),.NPCOp(PCSrc),.IMM(addr),.NPC(NPC));

//Instantiation of IM
   IM SCPU_IM(.Iaddr(Iaddr),.IDataOut(IDataOut));

//Instantiation of IF
   IF SCPU_IF(.instruction(IDataOut),.op(op),.rs(rs),.rt(rt),.rd(rd),.sa(sa),.funct(funct),.IMM(IMM),.addr(addr));

//Instantiation of RF
   RF SCPU_RF(.clk(clk),.rst(rst),.RFWr(RegWrite),.A1(rs),.A2(rt),.A3(RFWAddr1),.WD(WD),.RD1(RD1),.RD2(RD2));

//Instantiation of EXT
   EXT SCPU_EXT(.Imm16(EXTDataIn),.EXTOp(ExtSel),.Imm32(EXTDataOut));

//Instantiation of DM
   DM SCPU_DM(.DMRd(MemRead),.DMWr(MemWrite),.clk(clk),.half(Half),.byte(Byte),.unsign(unsign),.Daddr(Daddr),.DataIn(RD2),.DataOut(DDataOut));

//Instantiation of Shifter
   Shifter SCPU_Shifter(.Input(RD2),.index(ShifterIndex),.direction(ShiftDirection),.AorL(AorL),.Result(ShifterOut));

//Instantiation of ALU
   alu SCPU_ALU(.A(ALUDataIn1),.B(ALUDataIn2),.ALUOp(ALUOp),.C(ALUDataOut),.Zero(Zero));

//Instantiation of ControlUnit
   ControlUnit SCPU_CU(.op(op),.funct(funct),.zero(Zero),.ExtSel(ExtSel),.RegDst(RegDst),.RegWrite(RegWrite),.ALUSrcA(ALUSrcA),.ALUSrcB(ALUSrcB),.PCSrc(PCSrc),.ALUOp(ALUOp),.MemRead(MemRead),.MemWrite(MemWrite),.MemtoReg(MemtoReg),.ShiftIndex(ShiftIndex),.ShiftDirection(ShiftDirection),.AorL(AorL),.JalAndJalr(JalAndJalr),.HalfAndByte(HalfAndByte),.Byte(Byte),.Half(Half),.unsign(unsign));

//Instantiation of Muxes
   mux2_5bits RFW1(.d0(rt),.d1(rd),.s(RegDst),.y(RFWAddr2));
   mux2_5bits RFW2(.d0(RFWAddr2),.d1(5'b11111),.s(JalAndJalr),.y(RFWAddr1));//RFWAddr1 is used in instantiation of RF

   mux2_5bits Shift1(.d0(sa),.d1(RD1[4:0]),.s(ShiftIndex),.y(ShifterIndex));//Shifter

   mux2_32bits outSelection(.d0(ALUDataOut),.d1(DDataOut),.s(MemtoReg),.y(preRFDataIn));
   mux2_32bits RFDIn(.d0(preRFDataIn),.d1(PC+4),.s(JalAndJalr),.y(WD));//WriteBack content selection

   mux2_32bits ALUASrc(.d0(RD1),.d1(ShifterOut),.s(ALUSrcA),.y(ALUDataIn1));//ALU Oprand A source
   mux2_32bits ALUBSrc(.d0(RD2),.d1(EXTDataOut),.s(ALUSrcB),.y(ALUDataIn2));//ALU Oprand B source
endmodule
