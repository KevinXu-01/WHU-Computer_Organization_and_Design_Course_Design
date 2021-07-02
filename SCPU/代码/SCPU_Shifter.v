// shifter unit
module Shifter(Input, index, direction, AorL, Result);
   input  [31:0] Input;        // Input of shifter
   input [4:0] index; // how many bits
   input direction; // input direction, 0 left 1 right
   input AorL; // Arithmatic or Logic, 0 Logic 1 Arithmatic
   output [31:0] Result;

   reg[31:0] Result;

   always@(*)
	begin
	   if(!direction)
	      begin
		Result=Input<<index;
	      end
	   else if(!AorL)
	      begin
		Result=Input>>index;
	      end
	   else
	      begin
		Result = $signed(Input)>>>index;
	      end
	   end
endmodule
