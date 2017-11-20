`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineers: Dan Pederson, 2004
//				  Barron Barnett, 2004
//				  Jacob Beck, 2006
//				  Tudor Ciuleanu, 2007
//				  Josh Sackos, 2012
// 
// Create Date:    13:03:39 06/26/2012 
// Module Name:    PmodCLP 
// Project Name:   PmodCLP_Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.1
// Description: Displays "Hello from Digilent" text on the PmodCLP LCD screen.
//
// Revision: 6
// Revision 0.01 - File Created
// Revision History:								    
//		 05/27/2004(DanP):  created
//		 07/01/2004(BarronB): (optimized) and added writeDone as output
//		 08/12/2004(BarronB): fixed timing issue on the D2SB
//		 12/07/2006(JacobB): Revised code to be implemented on a Nexys Board
//						Changed "Hello from Digilent" to be on one line"
//						Added a Shift Left command so that the message
//						"Hello from Diligent" is shifted left by 1 repeatedly
//						Changed the delay of character writes
//		 11/21/2007(TudorC): Revised code to work with the CLP module.
//						Removed the write state machine and other unnecessary signals
//						Added backlight toggling
//		 08/17/2011(MichelleY): remove the backlight toggling
//									modify to be compatible with Nexys2 master UCF
//		 06/26/2012(JoshS): Converted VHDL to Verilog
//
//
//
//
//		11/19/2017 (JavanehTaghipour): 
//						1. Modified character table to personal use
//						2. Changed parameter to a case statement
//						3. Tweeked timing for character delay (from 2.6 ms wait to
//							40 us wait)
//						4. Added inputs from other modules [ issues: there is an
//							space not needed between : and the first number
//							of the sensor input ]
//						5. Modified PmodCLP_Top to change the 1s digits of the
//							two sensor inputs
//						6. Increased timing for character delay from 40 us to
//							80 us (constantly changing to have correct results show up)
//////////////////////////////////////////////////////////////////////////////////


// ==============================================================================
// 										  Define Module
// ==============================================================================
module PmodCLP( btnr, CLK, d10_1, d1_1, d10ths_1, d10_2, d1_2, d10ths_2, JB, JC, test );

	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================
    input btnr;					// use BTNR as reset input
    input CLK;					// 50 MHz clock input
	
	// sensor inputs
	input [ 7:0 ] d10_1;		// 10s digit of sensor1 input
	input [ 7:0 ] d1_1;			// 1s digit of sensor1 input
	input [ 7:0 ] d10ths_1;		// 10ths digit of sensor1 input
	input [ 7:0 ] d10_2;		// 10s digit of sensor2 input
	input [ 7:0 ] d1_2;			// 1s digit of sensor2 input
	input [ 7:0 ] d10ths_2;		// 10ths digit of sensor2 input
	
	// lcd input signals
	// signal on connector JB
	output [ 7:0 ] JB;			//output bus, used for data transfer (DB)
	output reg [ 3:0 ] test;
	
	// signal on connector JC
	// JC[ 7 ]register selection pin  (RS)
	// JC[ 8 ]selects between read/write modes (RW)
	// JC[ 9 ]enable signal for starting the data read/write (E)
    output [ 9:7 ] JC;


	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================
	wire [ 7:0 ] JB;
	wire [ 9:7 ] JC;

	//LCD control state machine
	parameter [ 3:0 ] stFunctionSet = 0,			// Initialization states
						stDisplayCtrlSet = 1,
						stDisplayClear = 2,
						stPowerOn_Delay = 3,		// Delay states
						stFunctionSet_Delay = 4,
						stDisplayCtrlSet_Delay = 5,
						stDisplayClear_Delay = 6,
						stInitDne = 7,				// Display characters and perform standard operations
						stActWr = 8,
						stCharDelay = 9;			// Write delay for operations
	
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
			Bit 1-7 are set	*/
		
	reg [ 6:0 ] clkCount = 7'b0000000;
	reg [ 20:0 ] count = 21'b000000000000000000000;	// 21 bit count variable for timing delays
	wire delayOK;									// High when count has reached the right delay time
	reg oneUSClk;									// Signal is treated as a 1 MHz clock	
	reg [ 3:0 ] stCur = stPowerOn_Delay;			// LCD control state machine
	reg [ 3:0 ] stNext;
	wire writeDone;									// Command set finish
	reg [ 9:0 ] LCD_CMDS;
	
	always @ ( lcd_cmd_ptr ) begin
		case ( lcd_cmd_ptr )
			0: 	LCD_CMDS <= { 2'b00, 8'h3C };		// 0, Function Set
			1: 	LCD_CMDS <= { 2'b00, 8'h0C };		// 1, Display ON, Cursor OFF, Blink OFF
			2: 	LCD_CMDS <= { 2'b00, 8'h01 };		// 2, Clear Display
			3: 	LCD_CMDS <= { 2'b00, 8'h02 };		// 3, Return Home

			4: 	LCD_CMDS <= { 2'b10, 8'h53 };		// 4, S
			5: 	LCD_CMDS <= { 2'b10, 8'h31 };		// 5, 1
			6: 	LCD_CMDS <= { 2'b10, 8'h3A };		// 6, :
			
			7: 	LCD_CMDS <= { 2'b00, 8'hC0 };		// 7, Move cursor to bottom left
			8: 	LCD_CMDS <= { 2'b10, 8'h53 };		// 8, S
			9: 	LCD_CMDS <= { 2'b10, 8'h32 };		// 9, 2
			10: LCD_CMDS <= { 2'b10, 8'h3A };		// 10, :
			
			11:	LCD_CMDS <= { 2'b00, 8'h85 };		// 11, Move cursor to 5 char position, 1st row
			12:	LCD_CMDS <= { 2'b10, d10_1 };		// 12, 10s digit of sensor1
			13:	begin LCD_CMDS <= { 2'b10, d1_1 };	test <= d1_1[ 3:0 ]; end	// 13, 1s digit of sensor1
			14:	LCD_CMDS <= { 2'b10, 8'h2E };		// 14, decimal of sensor1
			15: LCD_CMDS <= { 2'b10, d10ths_1 };	// 15, 10ths digit of sensor1
			
			16:	LCD_CMDS <= { 2'b00, 8'hC5 };		// 11, Move cursor to 5 char position, 2nd row
			17:	LCD_CMDS <= { 2'b10, d10_2 };		// 12, 10s digit of sensor2
			18:	LCD_CMDS <= { 2'b10, d1_2 };		// 13, 1s digit of sensor2
			19:	LCD_CMDS <= { 2'b10, 8'h2E };		// 14, decimal of sensor2
			20: LCD_CMDS <= { 2'b10, d10ths_2 };	// 15, 10ths digit of sensor2
		endcase
	end
	
	reg [ 4:0 ] lcd_cmd_ptr;

	// ===========================================================================
	// 										Implementation
	// ===========================================================================

	// This process counts to 100, and then resets.  It is used to divide the clock signal.
	// This makes oneUSClock peak aprox. once every 1microsecond
	always @ ( posedge CLK ) begin
		if ( clkCount == 7'b0110010 ) begin // used to be 7'b1100100
			clkCount <= 7'b0000000;
			oneUSClk <= ~oneUSClk;
		end
		else begin
			clkCount <= clkCount + 1'b1;
		end
	end

	// This process increments the count variable unless delayOK = 1.
	always @ ( posedge oneUSClk ) begin
		if(delayOK == 1'b1) begin
			count <= 21'b000000000000000000000;
		end
		else begin
			count <= count + 1'b1;
		end
	end

	// Determines when count has gotten to the right number, depending on the state.
	assign delayOK = (
		( ( stCur == stPowerOn_Delay ) && ( count == 21'b111101000010010000000 ) ) ||			// 2000000	 	-> 20 ms
		( ( stCur == stFunctionSet_Delay ) && ( count == 21'b000000000111110100000 ) ) ||		// 4000 		-> 40 us
		( ( stCur == stDisplayCtrlSet_Delay ) && ( count == 21'b000000000111110100000 ) ) ||	// 4000 		-> 40 us
		( ( stCur == stDisplayClear_Delay ) && ( count == 21'b000000000111110100000 ) ) ||		// 160000 		-> 1.6 ms
		( ( stCur == stCharDelay ) && ( count == 21'b000000011111010000000 ) )					// changed to 160 us (16000) 260000		-> 2.6 ms - Max Delay for character writes and shifts
		//( ( stCur == stCharDelay ) && ( count == 21'b000111111011110100000 ) )				// 260000		-> 2.6 ms - Max Delay for character writes and shifts
	) ? 1'b1 : 1'b0;

	// writeDone goes high when all commands have been run	
	assign writeDone = ( lcd_cmd_ptr == 5'b10101 ) ? 1'b1 : 1'b0;

	// Increments the pointer so the statemachine goes through the commands
	always @ ( posedge oneUSClk ) begin
		if ( ( stNext == stInitDne || stNext == stDisplayCtrlSet || stNext == stDisplayClear ) && writeDone == 1'b0 ) begin
			lcd_cmd_ptr <= lcd_cmd_ptr + 1'b1;
		end
		else if ( writeDone ) begin
			lcd_cmd_ptr <= 5'b01011;
		end
		else if( stCur == stPowerOn_Delay || stNext == stPowerOn_Delay ) begin
			lcd_cmd_ptr <= 5'b00000;
		end
		else begin
			lcd_cmd_ptr <= lcd_cmd_ptr;
		end
	end
	
	// This process runs the LCD state machine
	always @ ( posedge oneUSClk ) begin
		if ( btnr == 1'b1 ) begin
			stCur <= stPowerOn_Delay;
		end
		else begin
			stCur <= stNext;
		end
	end

	// This process generates the sequence of outputs needed to initialize and write to the LCD screen
	always @ ( stCur or delayOK or writeDone or lcd_cmd_ptr ) begin
		case (stCur)
			// Delays the state machine for 20ms which is needed for proper startup.
			stPowerOn_Delay: 
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
			stFunctionSet: 
			begin
				stNext <= stFunctionSet_Delay;
			end
			
			// Gives the proper delay of 37us between the function set and
			// the display control set.
			stFunctionSet_Delay: 
				begin
					if(delayOK == 1'b1) begin
						stNext <= stDisplayCtrlSet;
					end
					else begin
						stNext <= stFunctionSet_Delay;
					end
				end
			
			// Issuse the display control set as follows
			// Display ON,  Cursor OFF, Blinking Cursor OFF.
			stDisplayCtrlSet: 
				begin
						stNext <= stDisplayCtrlSet_Delay;
				end

			// Gives the proper delay of 37us between the display control set
			// and the Display Clear command. 
			stDisplayCtrlSet_Delay: 
				begin
					if ( delayOK == 1'b1 ) begin
						stNext <= stDisplayClear;
					end
					else begin
						stNext <= stDisplayCtrlSet_Delay;
					end
				end
			
			// Issues the display clear command.
			stDisplayClear: 
				begin
					stNext <= stDisplayClear_Delay;
				end

			// Gives the proper delay of 1.52ms between the clear command
			// and the state where you are clear to do normal operations.
			stDisplayClear_Delay: 
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
			stInitDne: 
				begin		
					stNext <= stActWr;
				end

			// stActWr
			stActWr: 
				begin
					stNext <= stCharDelay;
				end
				
			// Provides a max delay between instructions.
			stCharDelay: 
				begin
					if ( delayOK == 1'b1 ) begin
						stNext <= stInitDne;
					end
					else begin
						stNext <= stCharDelay;
					end
				end

			default: stNext <= stPowerOn_Delay;
		endcase
	end
		
	// Assign outputs
	assign JC[ 7 ] = LCD_CMDS[ 9 ];
	assign JC[ 8 ] = LCD_CMDS[ 8 ];
	assign JB = LCD_CMDS[ 7:0 ];
	assign JC[ 9 ] = ( stCur == stFunctionSet || stCur == stDisplayCtrlSet || stCur == stDisplayClear || stCur == stActWr ) ? 1'b1 : 1'b0;
	//assign test = d1_1[ 3:0 ];
endmodule
