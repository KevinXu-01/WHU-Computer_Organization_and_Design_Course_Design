//top level design

module PCPU();
   reg clk, rst; //clk is clock, rst is reset
   initial
	begin
		$readmemh( "C:/Users/KevinXu/Desktop/testcode/mipstest_pipelinedloop.dat" , PCPU_IM.rom); // load instructions into instruction memory
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
   //IF_NPC = IF_NPC(in NPC)/////////////////////////////////changed


   //NPC
   //RS = RD1;
   //PC = PC(in PC)
   //NPCOp = PCSrc(in ControlUnit)
   //IMM = addr(in IF)
   wire[31:0] IF_NPC;
   wire Bubble;/////////////////////new signal
   wire Flush;//////////////////////new signal


   //IM
   wire[6:0] Iaddr;  //Iaddr = PC[8:2]
   wire[31:0] IDataOut; //Instruction


   //IF
   wire[31:0] instruction;
   wire[5:0] op; //op also appears in ControlUnit, IDataOut[31:26]
   wire[4:0] rs; // A1(in RF), IDataOut[25:21]
   wire[4:0] rt; // A2(in RF), IDataOut[20:16]
   wire[4:0] rd;
   wire[4:0] sa;
   wire[5:0] funct; //funct also appears in ControlUnit
   wire[15:0] IMM;//for I-type instruction, different from IMM(addr in IF) in NPC
   wire[25:0] addr;
   
   //RF
   //RFWr = MEMWB_RegWrite(in ControlUnit)////////////////changed
   //A1 = rs(in IF)
   //A2 = rt(in IF)
   wire[4:0] RFWAddr1;// 	temp_A3
   wire[4:0] RFWAddr2;//	mux2_5 RFW1(Ins[20:16],Ins[15:11],RegDst,RFWAddr2);
	              //	mux2_5 RFW2(RFWAddr2,5'b11111,JalAndJalr,RFWAddr1);
		      //	RFWAddr1 and RFWAddr2 are NOT used for instantiation of RF
   wire[31:0] WD;
   wire[31:0] RD1;
   wire[31:0] RD2;


   //EXT
   wire[15:0] EXTDataIn;
   //EXTOp = ExtSel(in ControlUnit)
   wire[31:0] EXTDataOut;


   //DM
   //DMRd = EXEMEM_MemRead(in ControlUnit)//////////////////////////////////////changed
   //DMWr = EXEMEM_MemWrite(in ControlUnit)/////////////////////////////////////changed
   wire[6:0] Daddr;//(=EXEMEM_ALUDataOut[6:0])//////////////////////////////////changed
   //DDataIn = EXEMEM_RD2(in RF)////////////////////////////////////////////////changed
   wire[31:0] DDataOut;


   //Shifter
   //Input = RD2(in RF)
   wire[4:0] ShifterIndex;
   wire[31:0] ShifterOut;

   //ALU
   wire[31:0] ALUDataIn1;//A
   wire[31:0] ALUDataIn1_temp;/////////////////////////////////////////new signal
   wire[31:0] ALUDataIn2;//B
   //ALUOp = IDEXE_ALUOp(in ControlUnit)///////////////////////////////changed
   wire[31:0] ALUDataOut;//////////////needs to store in EXE_MEM pipeline register
   wire Zero;//zero flag
   wire ID_Zero;

   //CU
   //op = op(in IF)
   //funct = funct(in IF)
   //Zero = Zero (in ALU)
   wire ExtSel;
   wire RegDst;//Register Write Source
   wire RegWrite;//Register Write Control
   wire[1:0] ALUSrcA;
   wire ALUSrcB;
   wire[1:0] PCSrc;
   wire[3:0] ALUOp;
   wire MemRead;
   wire MemWrite;
   wire MemtoReg;
   wire ShiftIndex;
   wire ShiftDirection;
   wire JalAndJalr;


   assign Iaddr = IF_NPC[8:2];
   assign EXTDataIn = IMM;


   wire[31:0] RD1_forwarding;//RD1 after forwarding
   wire[31:0] RD2_forwarding;//RD2 after forwardind

   //IF_ID pipeline register
   wire[64-1:0] IFID_DataIn;
   wire[64-1:0] IFID_DataOut;
   wire[64-1:0] IFID_temp;
   wire IFID_rst;
   assign IFID_rst = rst;
   PRF#(.WIDTH(64)) IFID_PRF(.clk(clk),.rst(rst),.DataIn(IFID_DataIn),.DataOut(IFID_temp));
   assign IFID_DataIn = Bubble ? IFID_temp : {IF_NPC, IDataOut};
   assign IFID_DataOut = Flush ? 64'b0 : IFID_temp; //If flush=1, flush IF_ID pipeline register

   wire[31:0] ID_NPC;
   assign ID_NPC = IFID_DataOut[63:32];

   //instruction related information
   assign instruction = IFID_DataOut[31:0];
   assign op = instruction[31:26];
   assign rs = instruction[25:21];
   assign rt = instruction[20:16];
   assign rd = instruction[15:11];
   assign sa = instruction[10:6];
   assign funct = instruction[5:0];// for R-type instruction
   assign IMM = instruction[15:0]; // for I-type instruction
   assign addr = instruction[25:0]; // for J-type instruction



   //Solution to Control Hazard(branch taken/not taken in ID stage)
   assign ID_Zero = RD1_forwarding == RD2_forwarding ? 1 : 0;
   assign Zero = ID_Zero;



   assign ALUDataIn1 = (ALUSrcA[1] == 0) ? ((ALUSrcA[0] == 0) ? RD1_forwarding : RD2_forwarding) : ShifterOut;
   assign ALUDataIn2 = (ALUSrcB == 1) ? EXTDataOut : RD2_forwarding;


   //ID_EXE pipeline register
   wire[210-1:0] IDEXE_DataIn;
   wire[210-1:0] IDEXE_DataOut;
   wire IDEXE_rst;
   assign IDEXE_rst = rst;
   wire[4:0] ID_RFWAddr1;
   assign ID_RFWAddr1 = (Bubble == 1 ? 5'b00000 : RFWAddr1);

   PRF#(.WIDTH(210)) IDEXE_PRF(.clk(clk),.rst(IDEXE_rst),.DataIn(IDEXE_DataIn),.DataOut(IDEXE_DataOut));
   //                   32     32         32         5           32         32         32             2       1       1      1        4     1       1        1        1
   assign IDEXE_DataIn={ID_NPC,ALUDataIn1,ALUDataIn2,ID_RFWAddr1,EXTDataOut,ShifterOut,RD2_forwarding,ALUSrcA,ALUSrcB,RegDst,RegWrite,ALUOp,MemRead,MemWrite,MemtoReg,JalAndJalr};

   wire[31:0] IDEXE_ALUDataIn1;
   wire[31:0] IDEXE_ALUDataIn2;
   wire[4:0] IDEXE_RFWAddr1;
   wire[31:0] IDEXE_EXTDataOut;
   wire[31:0] IDEXE_ShifterOut;
   wire[31:0] IDEXE_RD2;//RD2 is later used in DM as the content written into Data Memory
   wire[1:0] IDEXE_ALUSrcA;
   wire IDEXE_ALUSrcB;
   wire IDEXE_RegDst;
   wire IDEXE_RegWrite;
   wire[3:0] IDEXE_ALUOp;
   wire IDEXE_MemRead;
   wire IDEXE_MemWrite;
   wire IDEXE_MemtoReg;
   wire IDEXE_JalAndJalr;
   
   assign IDEXE_ALUDataIn1 = IDEXE_DataOut[177:146];
   assign IDEXE_ALUDataIn2 = IDEXE_DataOut[145:114];
   assign IDEXE_RFWAddr1 = IDEXE_DataOut[113:109];
   assign IDEXE_EXTDataOut = IDEXE_DataOut[108:77];
   assign IDEXE_ShifterOut = IDEXE_DataOut[76:45];
   assign IDEXE_RD2 = IDEXE_DataOut[44:13];
   assign IDEXE_ALUSrcA = IDEXE_DataOut[12:11];
   assign IDEXE_ALUSrcB = IDEXE_DataOut[10];
   assign IDEXE_RegDst = IDEXE_DataOut[9];
   assign IDEXE_RegWrite = IDEXE_DataOut[8];
   assign IDEXE_ALUOp = IDEXE_DataOut[7:4];
   assign IDEXE_MemRead = IDEXE_DataOut[3];
   assign IDEXE_MemWrite = IDEXE_DataOut[2];
   assign IDEXE_MemtoReg = IDEXE_DataOut[1];
   assign IDEXE_JalAndJalr = IDEXE_DataOut[0];

   wire[31:0] EXE_NPC;
   assign EXE_NPC = IDEXE_DataOut[209:178];






   //EXE_MEM pipeline register
   wire[107-1:0] EXEMEM_DataIn;
   wire[107-1:0] EXEMEM_DataOut;
   wire EXEMEM_rst;
   assign EXEMEM_rst = rst;

   PRF#(.WIDTH(107)) EXEMEM_PRF(.clk(clk),.rst(EXEMEM_rst),.DataIn(EXEMEM_DataIn),.DataOut(EXEMEM_DataOut));

   //                      32    32        5              32         1            1              1             1              1              1
   assign EXEMEM_DataIn = {EXE_NPC,IDEXE_RD2,IDEXE_RFWAddr1,ALUDataOut,IDEXE_RegDst,IDEXE_RegWrite,IDEXE_MemRead,IDEXE_MemWrite,IDEXE_MemtoReg,IDEXE_JalAndJalr};

   wire[31:0] EXEMEM_RD2;
   wire[4:0] EXEMEM_RFWAddr1;
   wire[31:0] EXEMEM_ALUDataOut;
   wire EXEMEM_RegDst;
   wire EXEMEM_RegWrite;
   wire EXEMEM_MemRead;
   wire EXEMEM_MemWrite;
   wire EXEMEM_MemtoReg;
   wire EXEMEM_JalAndJalr;


   assign EXEMEM_RD2 = EXEMEM_DataOut[74:43];
   assign EXEMEM_RFWAddr1 = EXEMEM_DataOut[42:38];
   assign EXEMEM_ALUDataOut = EXEMEM_DataOut[37:6];
   assign EXEMEM_RegDst = EXEMEM_DataOut[5];
   assign EXEMEM_RegWrite = EXEMEM_DataOut[4];
   assign EXEMEM_MemRead = EXEMEM_DataOut[3];
   assign EXEMEM_MemWrite = EXEMEM_DataOut[2];
   assign EXEMEM_MemtoReg = EXEMEM_DataOut[1];
   assign EXEMEM_JalAndJalr = EXEMEM_DataOut[0];

   assign Daddr = EXEMEM_ALUDataOut[6:0];

   wire[31:0] MEM_NPC;
   assign MEM_NPC = EXEMEM_DataOut[106:75];



   //MEM_WB pipeline register
   wire[72-1:0] MEMWB_DataIn;
   wire[72-1:0] MEMWB_DataOut;
   wire MEMWB_rst;
   assign MEMWB_rst = rst;

   PRFNeg#(.WIDTH(72)) MEMWB_PRF(.clk(clk),.rst(MEMWB_rst),.DataIn(MEMWB_DataIn),.DataOut(MEMWB_DataOut));

   //                     32     32 5               1             1               1
   assign MEMWB_DataIn = {MEM_NPC,WD,EXEMEM_RFWAddr1,EXEMEM_RegDst,EXEMEM_RegWrite,EXEMEM_MemtoReg};

   wire[31:0] MEMWB_WD;
   wire[4:0] MEMWB_RFWAddr1;
   wire MEMWB_RegDst;
   wire MEMWB_RegWrite;
   wire MEMWB_MemtoReg;

   assign MEMWB_WD = MEMWB_DataOut[39:8];
   assign MEMWB_RFWAddr1 = MEMWB_DataOut[7:3];
   assign MEMWB_RegDst = MEMWB_DataOut[2];
   assign MEMWB_RegWrite = MEMWB_DataOut[1];
   assign MEMWB_MemtoReg = MEMWB_DataOut[0];

   assign WD = (EXEMEM_JalAndJalr == 0) ? (EXEMEM_MemtoReg == 1 ? DDataOut : EXEMEM_ALUDataOut) : MEM_NPC + 4;




   //bypassing or forwarding
   assign RD1_forwarding = (rs == 5'b00000) ? 32'b0 : ((IDEXE_RFWAddr1 == rs) ? ALUDataOut : ((EXEMEM_RFWAddr1 == rs) ? WD : RD1));
   assign RD2_forwarding = (rt == 5'b00000) ? 32'b0 : ((IDEXE_RFWAddr1 == rt) ? ALUDataOut : ((EXEMEM_RFWAddr1 == rt) ? WD : RD2));

   //bubble
   assign Bubble =
    ((op == 6'b000100 || op == 6'b000101) && (IDEXE_ALUOp != 0) && (IDEXE_RFWAddr1 != 0) && ((IDEXE_RFWAddr1 == rs) || (IDEXE_RFWAddr1 == rt))) 
    || 
    (IDEXE_MemtoReg &&(IDEXE_RFWAddr1 != 0) && ((IDEXE_RFWAddr1 == rs) || (IDEXE_RFWAddr1 == rt)))
    ||
    (EXEMEM_MemtoReg &&(EXEMEM_RFWAddr1 != 0) && ((EXEMEM_RFWAddr1 == rs) || (EXEMEM_RFWAddr1 == rt)))
    ||
    (IDEXE_MemWrite &&(IDEXE_RFWAddr1 != 0) && ((IDEXE_RFWAddr1 == rs) || (IDEXE_RFWAddr1 == rt)))
    ||
    (EXEMEM_MemWrite &&(EXEMEM_RFWAddr1 != 0) && ((EXEMEM_RFWAddr1 == rs) || (EXEMEM_RFWAddr1 == rt)));





//Instantiation of NPC
   NPC PCPU_NPC(.clk(clk),.rst(rst),.RS(RD1),.PC(PC),.NPCOp(PCSrc),.IMM(addr),.Bubble(Bubble),.NPC(IF_NPC),.Flush(Flush));

//Instantiation of IM
   IM PCPU_IM(.Iaddr(Iaddr),.IDataOut(IDataOut));

//Instantiation of RF
   RF PCPU_RF(.clk(clk),.rst(rst),.RFWr(MEMWB_RegWrite),.A1(rs),.A2(rt),.A3(MEMWB_RFWAddr1),.WD(MEMWB_WD),.RD1(RD1),.RD2(RD2));

//Instantiation of EXT
   EXT PCPU_EXT(.Imm16(EXTDataIn),.EXTOp(ExtSel),.Imm32(EXTDataOut));//in ID stage

//Instantiation of DM
   DM PCPU_DM(.DMRd(EXEMEM_MemRead),.DMWr(EXEMEM_MemWrite),.clk(clk),.Daddr(Daddr),.DataIn(EXEMEM_RD2),.DataOut(DDataOut));

//Instantiation of Shifter, in ID stage
   Shifter PCPU_Shifter(.Input(RD2_forwarding),.index(ShifterIndex),.direction(ShiftDirection),.Result(ShifterOut));

//Instantiation of ALU
   alu PCPU_ALU(.A(IDEXE_ALUDataIn1),.B(IDEXE_ALUDataIn2),.ALUOp(IDEXE_ALUOp),.C(ALUDataOut),.Zero(Zero));

//Instantiation of ControlUnit
   ControlUnit PCPU_CU(.op(op),.funct(funct),.zero(Zero),.ExtSel(ExtSel),.RegDst(RegDst),.RegWrite(RegWrite),.ALUSrcA(ALUSrcA),.ALUSrcB(ALUSrcB),.PCSrc(PCSrc),.ALUOp(ALUOp),.MemRead(MemRead),.MemWrite(MemWrite),.MemtoReg(MemtoReg),.ShiftIndex(ShiftIndex),.ShiftDirection(ShiftDirection),.JalAndJalr(JalAndJalr));

//Instantiation of Muxes
   mux2_5bits RFW1(.d0(rt),.d1(rd),.s(RegDst),.y(RFWAddr2));
   mux2_5bits RFW2(.d0(RFWAddr2),.d1(5'b11111),.s(JalAndJalr),.y(RFWAddr1));//RFWAddr1 is used in instantiation of RF
   //RFWAddr1 can be determined in ID stage

   mux2_5bits Shift1(.d0(sa),.d1(RD1[4:0]),.s(ShiftIndex),.y(ShifterIndex));//Shifter, in ID stage

endmodule
