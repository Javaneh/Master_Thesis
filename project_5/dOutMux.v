`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2017 01:49:31 PM
// Design Name: 
// Module Name: dOutMux
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


module dOutMux( dOutLcdSetUp, dOutCharGen, dOutSel, dOutFinal );
    input [ 7:0 ] dOutLcdSetUp, dOutCharGen;
    input [ 1:0 ] dOutSel;
    
    output reg [ 7:0 ] dOutFinal;
    
    always @ ( dOutLcdSetUp or dOutCharGen or dOutSel )
        case ( dOutSel )
            0: dOutFinal <= dOutLcdSetUp;
            1: dOutFinal <= dOutCharGen;
        endcase
endmodule
