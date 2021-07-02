//pipelined register file
module PRF #(parameter WIDTH = 32)(clk, rst, DataIn, DataOut);//IF_ID 
               
   input         clk;
   input         rst;
   input  [WIDTH - 1:0] DataIn;
   output [WIDTH - 1:0] DataOut;
   
   reg [WIDTH - 1:0] DataOut;
               
   always @(posedge clk or posedge rst) begin
      if (rst) 
         DataOut <= 0;
      else
         DataOut <= DataIn;
   end // end always
      
endmodule

module PRFNeg #(parameter WIDTH = 32)(clk, rst, DataIn, DataOut);//ID_EXE, EXE_MEM, MEM_WB
               
   input         clk;
   input         rst;
   input  [WIDTH - 1:0] DataIn;
   output [WIDTH - 1:0] DataOut;
   
   reg [WIDTH - 1:0] DataOut;
               
   always @(negedge clk or posedge rst) begin
      if (rst) 
         DataOut <= 0;
      else
         DataOut <= DataIn;
   end // end always

endmodule
