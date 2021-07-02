//`timescale 1ns/1ps
// instruction memory
module IM(
        input[6:0] Iaddr, //instruction address
        output reg[31:0] IDataOut //instruction content output
    );

    reg[31:0] rom[127:0];

    always@(Iaddr)
    begin
        IDataOut = rom[Iaddr];
    end

endmodule
