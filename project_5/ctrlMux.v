`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2017 01:30:56 PM
// Design Name: 
// Module Name: masterThesis
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


module ctrlMux( ctrlLcdSetUp, ctrlCharGen, ctrlSel, ctrlOut);
    input [ 2:0 ] ctrlLcdSetUp, ctrlCharGen;
    input [ 1:0 ] ctrlSel;
    
    output reg [ 2:0 ] ctrlOut;
    
    always @ ( ctrlLcdSetUp or ctrlCharGen or ctrlSel ) begin
        case ( ctrlSel )
            0: ctrlOut <= ctrlLcdSetUp;
            1: ctrlOut <= ctrlCharGen;
        endcase
    end
endmodule