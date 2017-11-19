`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2017 07:35:01 AM
// Design Name: 
// Module Name: Setup_LCD
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


module Setup_LCD( CLK, dOut, ctrl, done );
    input CLK;              // on board 50 MHz clock
    output done;            // done signal for LCD setup
    output [ 7:0 ] dOut;    // data output
    output [ 2:0 ] ctrl;    // control output
    
    // registers, parameters & wires
    wire [ 7:0 ] dOut;
    wire [ 2:0 ] ctrl;
    
    //LCD control state machine
    parameter [ 2:0 ]  stFunctionSet = 0,                        // Initialization states
                        stDisplayCtrlSet = 1,
                        stDisplayClear = 2,
                        stPowerOn_Delay = 3,                    // Delay states
                        stFunctionSet_Delay = 4,
                        stDisplayCtrlSet_Delay = 5,
                        stDisplayClear_Delay = 6,
                        stInitDne = 7;
                        
    /* These constants are used to initialize the LCD pannel.
                        
        --  FunctionSet:
                            Bit 0 and 1 are arbitrary
                            Bit 2:  Displays font type(0=5x8, 1=5x11)
                            Bit 3:  Numbers of display lines (0=1, 1=2)
                            Bit 4:  Data length (0=4 bit, 1=8 bit)
                            Bit 5-7 are set
        --  DisplayCtrlSet:
                            Bit 0:  Blinking cursor control (0=off, 1=on)
                            Bit 1:  Cursor (0=off, 1=on)
                            Bit 2:  Display (0=off, 1=on)
                            Bit 3-7 are set
        --  DisplayClear:
                            Bit 1-7 are set    */
    reg [ 6:0 ] clkCount = 7'b0000000;
    reg [ 20:0 ] count = 21'b000000000000000000000;    // 21 bit count variable for timing delays
    wire delayOK;                                // High when count has reached the right delay time
    reg oneUSClk = 0;                                // Signal is treated as a 1 MHz clock    
    reg [ 3:0 ] stCur = stPowerOn_Delay;            // LCD control state machine
    reg [ 3:0 ] stNext;
    wire writeDone;                                    // Command set finish
    reg [ 9:0 ] LCD_CMDS;
    
    always @ ( lcd_cmd_ptr )
        case ( lcd_cmd_ptr )
            0: LCD_CMDS <= { 2'b00, 8'h3C }; // 0, Function Set
            1: LCD_CMDS <= { 2'b00, 8'h0C }; // 1, Display ON, Cursor OFF, Blink OFF
            2: LCD_CMDS <= { 2'b00, 8'h01 }; // 2, Clear Display
            3: LCD_CMDS <= { 2'b00, 8'h02 }; // 3, Return Home // initially 02...changing for funsies
        endcase
                
    reg [ 2:0 ] lcd_cmd_ptr;
    
    // This process counts to 100, and then resets.  It is used to divide the clock signal.
    // This makes oneUSClock peak aprox. once every 1microsecond
    always @ ( posedge CLK ) begin
	
        if( clkCount == 7'b0110010 ) begin // before was: 7'b1100100
            clkCount <= 7'b0000000;
            oneUSClk <= ~oneUSClk;
        end
			else begin
				clkCount <= clkCount + 1'b1;
			end
    
	end
    
    
	// This process increments the count variable unless delayOK = 1.
	always @ ( posedge oneUSClk ) begin

		if ( delayOK == 1'b1 ) begin
			count <= 21'b000000000000000000000;
		end
		else begin
			count <= count + 1'b1;
		end

	end
    
	// Determines when count has gotten to the right number, depending on the state.
	assign delayOK = (
				( ( stCur == stPowerOn_Delay ) && ( count == 21'b111101000010010000000 ) ) ||            // 2000000        -> 20 ms
				( ( stCur == stFunctionSet_Delay ) && ( count == 21'b000000000111110100000 ) ) ||        // 4000         -> 40 us
				( ( stCur == stDisplayCtrlSet_Delay ) && ( count == 21'b000000000111110100000 ) ) ||    // 4000         -> 40 us
				( ( stCur == stDisplayClear_Delay ) && ( count == 21'b000100111000100000000 ) )        // 160000         -> 1.6 ms
	) ? 1'b1 : 1'b0;
	
	// For simulation purposes
	/*assign delayOK = (
						( ( stCur == stPowerOn_Delay ) && ( count == 21'd2000 ) ) ||            // 2000000        -> 20 ms
						( ( stCur == stFunctionSet_Delay ) && ( count == 21'd4 ) ) ||        // 4000         -> 40 us
						( ( stCur == stDisplayCtrlSet_Delay ) && ( count == 21'd4) ) ||    // 4000         -> 40 us
						( ( stCur == stDisplayClear_Delay ) && ( count == 21'd160 ) ) ||        // 160000         -> 1.6 ms
						( ( stCur == stCharDelay ) && ( count == 21'd260 ) )                    // 260000        -> 2.6 ms - Max Delay for character writes and shifts
			) ? 1'b1 : 1'b0;*/
                    
	// writeDone goes high when all commands have been run    
	assign writeDone = ( lcd_cmd_ptr == 3'b100 ) ? 1'b1 : 1'b0; // need to change this or remove this maybe


	// Increments the pointer so the statemachine goes through the commands
	always @ ( posedge oneUSClk ) begin
		if ( ( stNext == stInitDne || stNext == stDisplayCtrlSet || stNext == stDisplayClear ) && writeDone == 1'b0 ) begin
			lcd_cmd_ptr <= lcd_cmd_ptr + 1'b1;
		end
		else if ( stCur == stPowerOn_Delay || stNext == stPowerOn_Delay ) begin
			lcd_cmd_ptr <= 5'b00000;
		end
		else begin
			lcd_cmd_ptr <= lcd_cmd_ptr;
		end
	end
        
	// This process runs the LCD state machine
	always @ ( posedge oneUSClk ) begin
		stCur <= stNext;
	end
        
    
	// This process generates the sequence of outputs needed to initialize and write to the LCD screen
	always @ ( stCur or delayOK or writeDone or lcd_cmd_ptr ) begin
		case ( stCur )
			// Delays the state machine for 20ms which is needed for proper startup.
			stPowerOn_Delay : 
			begin
				if ( delayOK == 1'b1 ) begin
					stNext <= stFunctionSet;
				end
				else begin
					stNext <= stPowerOn_Delay;
				end
			end
				
			// This issues the function set to the LCD as follows 
			// 8 bit data length, 1 lines, font is 5x8.
			stFunctionSet : 
			begin
				stNext <= stFunctionSet_Delay;
			end
			
			// Gives the proper delay of 37us between the function set and
			// the display control set.
			stFunctionSet_Delay : 
			begin
				if ( delayOK == 1'b1 ) begin
					stNext <= stDisplayCtrlSet;
				end
				else begin
						stNext <= stFunctionSet_Delay;
				end
			end
			
			// Issuse the display control set as follows
			// Display ON,  Cursor OFF, Blinking Cursor OFF.
			stDisplayCtrlSet : 
			begin
				stNext <= stDisplayCtrlSet_Delay;
			end

			// Gives the proper delay of 37us between the display control set
			// and the Display Clear command. 
			stDisplayCtrlSet_Delay : 
			begin
				if ( delayOK == 1'b1 ) begin
					stNext <= stDisplayClear;
				end
				else begin
					stNext <= stDisplayCtrlSet_Delay;
				end
			end
			
			// Issues the display clear command.
			stDisplayClear    : 
			begin
				stNext <= stDisplayClear_Delay;
			end

			// Gives the proper delay of 1.52ms between the clear command
			// and the state where you are clear to do normal operations.
			stDisplayClear_Delay : 
			begin
				if ( delayOK == 1'b1 ) begin
					stNext <= stInitDne;
				end
				else begin
					stNext <= stDisplayClear_Delay;
				end
			end
			
			// State for normal operations for displaying characters, changing the
			// Cursor position etc.
			stInitDne : 
			begin        
				stNext <= stInitDne;
			end

			default : stNext <= stPowerOn_Delay;

		endcase
	end
            
            
	// Assign outputs
	assign ctrl[ 0 ] = LCD_CMDS[ 9 ]; 
	assign ctrl[ 1 ] = LCD_CMDS[ 8 ]; 
	assign dOut = LCD_CMDS[ 7:0 ]; 
	assign ctrl[ 2 ] = ( stCur == stFunctionSet || stCur == stDisplayCtrlSet || stCur == stDisplayClear ) ? 1'b1 : 1'b0;
	assign done = ( stCur == stInitDne || stNext == stInitDne ) ? 1'b1 : 1'b0;
endmodule
