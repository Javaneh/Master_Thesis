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


module masterThesis( CLK, dOut, ctrl, done );
    input CLK;
    output [ 7:0 ] dOut;
    output [ 2:0 ] ctrl;
    output [ 1:0 ] done;
    
    wire [ 7:0 ] lcdSetUpDout;
    wire [ 7:0 ] charGenDout;
    wire [ 2:0 ] lcdSetUpCtrl;
    wire [ 2:0 ] charGenCtrl;
    
    wire lcdSetUpDne, charGenDne;
    
    Setup_LCD Setup_LCD_mod( .CLK( CLK ), .dOut( lcdSetUpDout ), .ctrl( lcdSetUpCtrl) , .done( lcdSetUpDne ) );
    charGenerator charGen_mod( .LCD_SetUp_Done( lcdSetUpDne ), .CLK( CLK ), .dOut( charGenDout ), .ctrl( charGenCtrl ), .done( charGenDne ) );
    dOutMux dOutMux_mod( .dOutLcdSetUp( lcdSetUpDout ), .dOutCharGen( charGenDout ), .dOutSel( { charGenDne, lcdSetUpDne } ), .dOutFinal( dOut ) );
    ctrlMux ctrlMux_mod( .ctrlLcdSetUp( lcdSetUpCtrl ), .ctrlCharGen( charGenCtrl ), .ctrlSel( { charGenDne, lcdSetUpDne } ), .ctrlOut( ctrl ) );
    
    assign done = { charGenDne, lcdSetUpDne };
    
endmodule
