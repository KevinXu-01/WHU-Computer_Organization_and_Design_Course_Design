//data memory[needs to be changed], address based on byte(8 bits per address)
module DM(
        input DMRd,// 1 read, 0 not read
        input DMWr, // 1 write, 0 not write
        input clk, //clock
        input half, // to identify if the instruction is loadhalf or savehalf
        input byte, // to identify if the instruction is loadbyte or savebyte
        input unsign, // to identify if the instruction is lbu or lhu
        input [6:0] Daddr, // Data address
        input [31:0] DataIn, //Data input
        output reg[31:0] DataOut //Data output
    );

    reg [7:0] ram [0:512]; //storage of DM is 512 Bytes
    
    always@(DMRd or Daddr)
    begin
     //read, little endian
	if(half)
	    begin
		if(unsign)
		   begin  //lhu
		        DataOut[7:0] = DMRd ? ram[Daddr] : 8'bz;
		        DataOut[15:8] = DMRd ? ram[Daddr + 1] : 8'bz;     
		        DataOut[23:16] = DMRd ? 8'b0 : 8'bz;     
		        DataOut[31:24] = DMRd ? 8'b0 : 8'bz;
		   end
		else
		   begin  //lh
		        DataOut[7:0] = DMRd ? ram[Daddr] : 8'bz;
		        DataOut[15:8] = DMRd ? ram[Daddr + 1] : 8'bz;     
		        DataOut[23:16] = DMRd ? {8{ram[Daddr+1][7]}} : 8'bz;     
		        DataOut[31:24] = DMRd ? {8{ram[Daddr+1][7]}} : 8'bz;
		   end
	    end
	else if(byte)
	    begin
		if(unsign)
		   begin  //lbu
		        DataOut[7:0] = DMRd ? ram[Daddr] : 8'bz;
		        DataOut[15:8] = DMRd ? 8'b0 : 8'bz;     
		        DataOut[23:16] = DMRd ? 8'b0 : 8'bz;     
		        DataOut[31:24] = DMRd ? 8'b0 : 8'bz;
		   end
		else
		   begin  //lb
		        DataOut[7:0] = DMRd ? ram[Daddr] : 8'bz;
		        DataOut[15:8] = DMRd ? {8{ram[Daddr][7]}} : 8'bz;     
		        DataOut[23:16] = DMRd ? {8{ram[Daddr][7]}} : 8'bz;     
		        DataOut[31:24] = DMRd ? {8{ram[Daddr][7]}} : 8'bz;
		   end
	    end
	else
	    begin  //lw
	        DataOut[7:0] = DMRd ? ram[Daddr] : 8'bz;
	        DataOut[15:8] = DMRd ? ram[Daddr + 1] : 8'bz;     
	        DataOut[23:16] = DMRd ? ram[Daddr + 2] : 8'bz;     
	        DataOut[31:24] = DMRd ? ram[Daddr + 3] : 8'bz;
	    end
    end

    always@(negedge clk)
    begin   
     //write, little endian
        if(DMWr)
            begin
		if(half)
		  begin  //sh
			ram[Daddr] = DataIn[7:0];
			ram[Daddr+1] = DataIn[15:8];
		  end
		else if(byte)
		  begin  //sb
			ram[Daddr]=DataIn[7:0];
		  end
		else
		  begin  //sw
	                ram[Daddr] = DataIn[7:0];    
	                ram[Daddr + 1] = DataIn[15:8];
	                ram[Daddr + 2] = DataIn[23:16];     
	                ram[Daddr + 3] = DataIn[31:24];    
         	  end
            end
        //$display("mwr: %d $12 %d %d %d %d", mWR, ram[12], ram[13], ram[14], ram[15]);
    end

endmodule
