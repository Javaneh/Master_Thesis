`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2017 10:34:12 PM
// Design Name: 
// Module Name: echoCounter
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


module echoCounter( triggerDone, echo, CLK, distance, done );
    parameter n1 = 15;
    input triggerDone, echo, CLK;
    output reg [ n1 - 1: 0 ] distance = 15'b000000000000000;
    output reg done;
    
    parameter [ 1:0 ] startCount = 0, count = 1, endCount = 2;
    reg PS = startCount;
    reg NS;
    reg oneUSClk = 0;
    reg [ 5:0 ] clkCount = 0;
    
    always @ ( triggerDone ) begin
        if ( triggerDone )
        begin
            PS <= startCount;
            done <= 0;
        end
    end
    
    // clock divider
    always @ ( posedge CLK ) begin
        if ( clkCount == 6'b110010 ) begin
            clkCount <= 6'b000000;
            oneUSClk <= ~oneUSClk;
        end
        else
            clkCount <= clkCount + 1'b1;
    end
    
    always @ ( posedge oneUSClk ) begin
        case ( PS )
            startCount:
                begin
                    distance <= 15'bb000000000000000;
                    if ( echo )
                        NS <= count;
                    else
                        NS <= PS;
                end
            count:
                begin
                    if ( echo )
                    begin
                        if ( distance == 15'b101101010100000 ) begin
                            NS <= endCount;
                        end
                        else begin
                            NS <= count;
                            distance <= distance + 1'b1;
                        end
                    end
                    else
                        NS <= endCount;
                end
            endCount:
                begin
                    done <= 1;
                    NS <= endCount;
                end
        endcase
        
        PS <= NS;
    end
endmodule
