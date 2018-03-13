// CSCB58 Winter 2018 Final Project
// Bubble Trouble Knockoff
// Names: Jeffrey So, Ricky Chen, Byron Leung, Brandon Shewnarain
// Description: Insert Description Here

`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

module project
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		LEDR,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	output [10:0] LEDR;
	assign LEDR[0] = load_level;
	assign LEDR[1] = level_pause;
	assign LEDR[2] = play;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = SW[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
	wire go;
	assign go = ~KEY[0];
	assign left = ~KEY[3];
	assign right = ~KEY[2];
	
	wire load_level, level_pause, play;
	wire [7:0] playerX, playerY;
	wire [2:0] animate;
	wire done;
	
    // Instantiate datapath
	datapath d0(
	.playerX(playerX),
	.playerY(playerY),
	.load_level(load_level),
	.level_pause(level_pause),
	.play(play),
	.animate(animate),
	.resetn(resetn),
	.clk(CLOCK_50),
	.done(done),
   .x(x),
	.y(y),
	.colour(colour),
	.drawEn(writeEn)
    );
	
   // Instantiate FSM control
   control c0(.resetn(resetn), .clk(CLOCK_50), .go(go), .load_level(load_level), .level_pause(level_pause), .play(play));
	
	player_control pc0 (
	.left(left),
	.right(right),
	.play(play),
	.clk(CLOCK_50),
	.resetn(resetn),
	.move(move),
	.playerX(playerX),
	.playerY(playerY)
	);
    
endmodule

module control(go, resetn, clk, load_level, level_pause, play);
	input clk, resetn, go;
	output load_level, level_pause, play;
	
	reg [2:0] state_next, state;
	localparam LEVEL_SELECT = 3'b000, LOAD_LEVEL = 3'b001, LEVEL_PAUSE = 3'b010, PLAY_START = 3'b011, PLAY = 3'b100, GAME_OVER = 3'b101, PAUSING = 3'b110; // states
	
	always@(*)
    begin: state_table
        case (state)
            LEVEL_SELECT: begin
					if (go) state_next <= LOAD_LEVEL;
					else state_next <= LEVEL_SELECT;
            end
            LOAD_LEVEL: begin
					if (!go) state_next <= LEVEL_PAUSE;
					else state_next <= LOAD_LEVEL;
            end
            LEVEL_PAUSE: begin
					if (go) state_next <= PLAY_START;
					else state_next <= LEVEL_PAUSE;
				end
            PLAY_START: begin
					if (!go) state_next <= PLAY;
					else state_next <= PLAY_START;
				end
				PLAY: begin
					if (go) state_next <= PAUSING;
					else state_next <= PLAY;
				end
				PAUSING: begin
					if (!go) state_next <= LEVEL_PAUSE;
					else state_next <= PAUSING;
				end
            default: state_next = LEVEL_SELECT;
        endcase
    end // state_table
    
    // State Registers
    always @(posedge clk)
    begin: state_FFs
        if(resetn == 1'b0)
            state <= LEVEL_SELECT;
        else
            state <= state_next;
    end // state_FFS

    // Output logic
	 assign load_level = (state == LOAD_LEVEL);
	 assign level_pause = (state == LEVEL_PAUSE);
	 assign play = (state == PLAY);
endmodule

module player_control(
	input left,
	input right,
	input play,
	input clk,
	input resetn,
	output reg move,
	output reg [7:0] playerX,
	output reg [6:0] playerY
	);
	
	localparam rate_div = 249999; // move speed
	reg [27:0] counter;
	
	always@(posedge clk) begin
	    if (!resetn) begin
			counter <= 0;
			move <= 1'b0;
			playerX <= 80;
			playerY <= 100;
		end
		if (play) begin
			if (left && playerX > 0) begin 
				// move player left
				if (counter == rate_div) begin
					playerX <= playerX - 2;
					move <= 1'b1;
					counter <= 0;
				end
				
				counter <= counter + 1'b1;
			end else if (right && playerX < 100) begin
				// move player right
				if (counter == rate_div) begin
					playerX <= playerX + 2;
					move <= 1'b1;
					counter <= 0;
				end
				
				counter <= counter + 1'b1;
			end else begin
				move <= 1'b0;
				counter <= 0;
			end
		end
	end
endmodule

// Telling vga what its drawing
module animate_control(
	input done,
	input player_move,
	input resetn,
	input clk,
	output animate
	);
	
	reg [2:0] state, state_next;
	localparam IDLE = 3'b000, PLAYER = 3'b001;
	
	always@(*)
    begin: state_table
        case (state)
            IDLE: begin
				if (player_move) state_next <= PLAYER;
				else state_next <= IDLE;
            end
            PLAYER: begin
				if (done) state_next <= IDLE;
				else state_next <= PLAYER;
            end
            default: state_next = IDLE;
        endcase
    end // state_table
    
    // State Registers
    always @(posedge clk)
    begin: state_FFs
        if(resetn == 1'b0)
            state <= IDLE;
        else
            state <= state_next;
    end // state_FFS

    // Output logic
    assign player = (state == PLAYER);
endmodule

// does the drawing
module datapath(
	input [7:0] playerX,
	input [6:0] playerY,
	input load_level,
	input level_pause,
	input play,
	input [2:0] animate,
	input resetn,
	input clk,
	output reg done,
   output reg [7:0] x,
	output reg [6:0] y,
	output reg [2:0] colour,
	output reg drawEn
    );

	
	localparam IDLE = 3'b000, PLAYER = 3'b001;
	
	reg [27:0] counter;
	
	always@(posedge clk) begin
	   if (!resetn) begin
			drawEn <= 1'b0;
		end
		if (load_level) begin
			x <= 80;
			y <= 100;
			colour <= 3'b111;
			drawEn <= 1'b1;
		end else if (play) begin
			x <= playerX;
			y <= playerY;
			drawEn <= 1;
		end
		else begin
			drawEn <= 1'b0;
		end
	end
endmodule
