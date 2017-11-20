`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2017 12:33:37 PM
// Design Name: 
// Module Name: PmodCLP_Top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PmodCLP_Top( btnr, CLK, JB, JC, test );
    input btnr, CLK;
    output [ 7:0 ] JB;
    output [ 9:7 ] JC;
    output [ 3:0 ] test;
    
    reg [ 7:0 ] d10 = 8'h30;
	reg [ 7:0 ] d1 = 8'h30;
	reg [ 7:0 ] d10ths = 8'h30;
	reg [ 6:0 ] clkCount = 7'b0000000;
	reg oneUSClk;	
	
	always @ ( posedge CLK ) begin
	   if ( clkCount == 7'bb0110010 ) begin
	       clkCount <= 7'b0000000;
	       oneUSClk <= ~oneUSClk;
	   end
	   else
	       clkCount <= clkCount + 1'b1;
	end
	
	//always @ ( posedge oneUSClk ) begin
	always @ ( posedge CLK ) begin
		if ( d10ths == 8'h39 ) begin
		  if ( d1 == 8'h39 ) begin
		      if ( d10 == 8'h39 ) begin
		          d10 <= 8'h30;
		      end
		      else begin
                  d10 <= d10 + 1'b1;
		          d1 <= 8'h30;
		          d10ths <= 8'h30;
		      end
		  end
		  else begin
		      d1 <= d1 + 1'b1;
		      d10ths <= 8'h30;
		  end
		end
		else
		  d10ths <= d10ths + 1'b1;
	end
    
    PmodCLP PmodCLP_mod( .btnr( btnr ), .CLK( CLK ), 
						.d10( d10 ), .d1( d1 ), .d10ths( d10ths ),
						.JB( JB ), .JC( JC ), .test( test ) );
endmodule