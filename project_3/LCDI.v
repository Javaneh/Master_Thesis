`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Developed by: Toma H. Sacco, Ph.D. 
//
//code   |  character	 code  |  character code   |  character	 code   |  character
//00000  |   0		01000  |   8        10000  |   .	 11000  |   <
//00001  |   1		01001  |   9        10001  |   :	 11001  |   >
//00010  |   2		01010  |   A        10010  |   +	 11010  |   m
//00011  |   3		01011  |   B        10011  |   -	 11011  |   s
//00100  |   4		01100  |   C        10100  |   *	 11100  |   micro
//00101  |   5		01101  |   D        10101  |   /	 11101  |   ohm
//00110  |   6		01110  |   E        10110  |   (	 11110  |   =
//00111  |   7		01111  |   F        10111  |   )	 11111  |      
//////////////////////////////////////////////////////////////////////////////////
module LCDI(clk, datain, dataout, control);
    input clk;
    input [39:0] datain;
    output [3:0] dataout;
    output [2:0] control;
	 
	 reg [2:0] sel=0;
	 reg [25:0] delay=0;  
	 reg [5:0] state=0;
	 reg [3:0] dataout=0;
	 reg [2:0] control=0; // [E,D/C' , R/W'] 
	 reg [7:0] DR=0;
	 reg [7:0] MUX=0;
	 reg [4:0] temp=0;
	 
	 always @(sel or datain)
	 case(sel)
	 0:temp = datain[4:0];
	 1:temp = datain[9:5];
	 2:temp = datain[14:10];
	 3:temp = datain[19:15];
	 4:temp = datain[24:20];
	 5:temp = datain[29:25];
	 6:temp = datain[34:30];
	 7:temp = datain[39:35];
	 endcase
	 
	 always @(temp)
	 case(temp)
	 0:MUX = 8'h30;
	 1:MUX = 8'h31;
	 2:MUX = 8'h32;
	 3:MUX = 8'h33;
	 4:MUX = 8'h34;
	 5:MUX = 8'h35;
	 6:MUX = 8'h36;
	 7:MUX = 8'h37;
	 8:MUX = 8'h38;
	 9:MUX = 8'h39;
	 10:MUX = 8'h41;//A
	 11:MUX = 8'h42;//B
	 12:MUX = 8'h43;//C
	 13:MUX = 8'h44;//D
	 14:MUX = 8'h45;//E
	 15:MUX = 8'h46;//F
	 16:MUX = 8'h2E;//.
	 17:MUX = 8'h3A;//:
	 18:MUX = 8'h2B;//+
	 19:MUX = 8'h2D;//-
	 20:MUX = 8'h2A;//*
	 21:MUX = 8'h2F;///
	 22:MUX = 8'h28;//(
	 23:MUX = 8'h29;//)
	 24:MUX = 8'h3C;//<
	 25:MUX = 8'h3E;//>
	 26:MUX = 8'h6D;//m
	 27:MUX = 8'h53;//S
	 28:MUX = 8'hE4;//micro
	 29:MUX = 8'hF4;//ohm
	 30:MUX = 8'h3D;//=
	 31:MUX = 8'hFE;//blank 
	 endcase
	 
	 always @ (posedge clk)
	 begin
	 case(state)
	 //Power-On Initialization
	 0:begin delay <= 750_000; state<= 1;control <= 0;    end
	 1:begin 
	   if(delay==0)begin state <= 2; delay<=12; dataout<= 4'h3; control<=3'h4; end
		else delay <= delay -1; 
		end
	 2:begin if(delay==0)begin delay <= 205_000; state<= 3;control <= 0; end
	   else delay <= delay -1 ; 
		end
	 3:begin 
	   if(delay==0)begin state <= 4; delay<=12; dataout<= 4'h3; control<=3'h4; end
		else delay <= delay -1; 
		end
	 4:begin if(delay==0)begin delay <= 5_000; state<= 5;control <= 0; end
	   else delay <= delay -1 ; 
		end
	 5:begin 
	   if(delay==0)begin state <= 6; delay<=12; dataout<= 4'h3; control<=3'h4; end
		else delay <= delay -1; 
		end
	 6:begin if(delay==0)begin delay <= 2_000; state<= 7;control <= 0; end
	   else delay <= delay -1 ; 
		end
	 7:begin 
	   if(delay==0)begin state <= 8; delay<=12; dataout<= 4'h2; control<=3'h4; end
		else delay <= delay -1; 
		end
	 8:begin if(delay==0)begin delay <= 2_000; state<= 9;control <= 0; end
	   else delay <= delay -1 ; 
		end
	 9:begin 
	   if(delay==0)begin state <= 10;sel <= 4; end
		else delay <= delay -1; 
		end
		
	// Display Configuration
	10:begin  case(sel)
	                0: begin state <= 20; delay <= 82_000; end
						 1: begin state <= 11; DR <= 8'h01; end
						 2: begin state <= 11; DR <= 8'h0C; end
						 3: begin state <= 11; DR <= 8'h06; end
						 4: begin state <= 11; DR <= 8'h28; end 		 
				 default: state <= 0 ;
				 endcase end
	11:begin state <= 12; control <= 0; dataout <= DR[7:4]; delay <= 2; sel <= sel -1; end
	12:begin if(delay==0)begin delay <= 12; state<= 13; control<=3'h4; end
	         else delay <= delay -1 ;end
	13:begin if(delay==0)begin delay <= 2; state<= 14; control<=0; end
	         else delay <= delay -1 ; end
	14:begin if(delay==0)begin delay <= 50 ; state<= 15; end
	         else delay <= delay -1 ; end
	15:begin if(delay==0)begin state <= 16; control <= 0; dataout <=DR[3:0]; delay <= 2;end
	         else delay <= delay -1 ; end
	16:begin if(delay==0)begin delay <= 12; state<= 17; control<=3'h4; end
	         else delay <= delay -1 ; end
	17:begin if(delay==0)begin delay <= 2; state<= 18; control<=0; end
	         else delay <= delay -1 ; end
	18:begin if(delay==0)begin delay <= 2_000 ; state<= 19; end
	         else delay <= delay -1 ; end
	19:begin if(delay==0)begin state<= 10; end
	         else delay <= delay -1 ; end
	20:begin if(delay==0)begin state<= 21; end
	   else delay <= delay -1 ; 
		end
	
	// Displaying
	21:begin state <= 22;sel <= 8; end
	// setting the starting address
	22:begin state <= 23; DR <=8'h80; end
	23:begin state <= 24; control <= 0; dataout <= DR[7:4]; delay <= 2; sel <= sel -1; end
	24:begin if(delay==0)begin delay <= 12; state<= 25; control<=3'h4; end
	         else delay <= delay -1 ;end
	25:begin if(delay==0)begin delay <= 2; state<= 26; control<=0; end
	         else delay <= delay -1 ; end
	26:begin if(delay==0)begin delay <= 50 ; state<= 27; end
	         else delay <= delay -1 ; end
	27:begin if(delay==0)begin state <= 28; control <= 0; dataout <=DR[3:0]; delay <= 2;end
	         else delay <= delay -1 ; end
	28:begin if(delay==0)begin delay <= 12; state<= 29; control<=3'h4; end
	         else delay <= delay -1 ; end
	29:begin if(delay==0)begin delay <= 2; state<= 30; control<=0; end
	         else delay <= delay -1 ; end
	30:begin if(delay==0)begin delay <= 2_000 ; state<= 31; end
	         else delay <= delay -1 ; end
	31:begin if(delay==0)begin state<= 32; end
	         else delay <= delay -1 ; end
	
	// Writing data to the display
	32:begin state <= 33; DR <= MUX; end
	33:begin state <= 34; control <= 3'b010; dataout <= DR[7:4]; delay <= 2; end
	34:begin if(delay==0)begin delay <= 12; state<= 35; control<=3'b110; end
	         else delay <= delay -1 ;end
	35:begin if(delay==0)begin delay <= 2; state<= 36; control<=3'b010; end
	         else delay <= delay -1 ; end
	36:begin if(delay==0)begin delay <= 50 ; state<= 37;control<=0; end
	         else delay <= delay -1 ; end
	37:begin if(delay==0)begin state <= 38; control <= 3'b010; dataout <=DR[3:0]; delay <= 2;end
	         else delay <= delay -1 ; end
	38:begin if(delay==0)begin delay <= 12; state<= 39; control<=3'b110; end
	         else delay <= delay -1 ; end
	39:begin if(delay==0)begin delay <= 2; state<= 40; control<=3'b010; end
	         else delay <= delay -1 ; end
	40:begin if(delay==0)begin delay <= 2_000 ; state<= 41;control<=0; end
	         else delay <= delay -1 ; end
	41:begin if(delay==0)begin if(sel==0)state<= 42;else begin state<= 32; sel<=sel - 1; end end
	         else delay <= delay -1 ; end
	
	// delay between displaying
	42:begin state <= 43; delay <= 1_000_000; end
        43:begin if(delay==0)begin state<= 21; end
	         else delay <= delay -1 ; end	
	default: state <= 0;
	endcase
	 end

   

endmodule