`include "PCPU_ctrl_encode_def.v"

module NPC(clk, rst, RS, PC, NPCOp, IMM, Bubble, NPC, Flush);  // next pc module, /////////////////////////////////////changed
   input  clk;
   input  rst;
   input  [31:0] RS;        // content stored in register
   input  [31:0] PC;        // pc
   input  [1:0]  NPCOp;     // next pc operation
   input  [25:0] IMM;       // immediate, address
   input  Bubble;           //bubble
   output reg [31:0] NPC;   // next pc
   output reg Flush; //flush
   
   //wire [31:0] PCPLUS4;
   
   //assign PCPLUS4 = NPC + 4; // pc + 4          ///////////////////////////////no longer used
   
   always @(posedge clk or posedge rst)
   begin
	if(rst == 1)
		NPC = 32'h0000_0000;
		Flush = 0;

     if(Bubble == 0)
       begin
         case (NPCOp)
             `NPC_PLUS4:  begin NPC = NPC + 4; Flush = 0; end
             `NPC_BRANCH: begin NPC = NPC + {{14{IMM[15]}}, IMM[15:0], 2'b00}; Flush = 1; end //branch, beq & bne
             `NPC_JUMP:   begin NPC = {NPC[31:28], IMM[25:0], 2'b00}; Flush = 1; end //j & jal
             `NPC_RS:     begin NPC = RS; Flush = 1; end //jalr & jr
             default:     begin NPC = NPC + 4; Flush = 0; end
         endcase
       end
   end // end always
   
endmodule
