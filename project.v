// CSCB58 Winter 2018 Final Project
// Bubble Trouble Knockoff
// Names: Jeffrey So, Ricky Chen, Byron Leung, Brandon Shewnarain
// Description: Insert Description Here

`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

`define SCREEN_W 8'd160
`define SCREEN_H 7'd120
`define PLAYER_WIDTH 2'd3
`define PLAYER_SIZE `PLAYER_WIDTH * `PLAYER_WIDTH
`define PLAYER_COLOR 3'b111

module project
    (
        CLOCK_50,                       //  On Board 50 MHz
        // Your inputs and outputs here
        KEY,
        SW,
        LEDR,
        // The ports below are for the VGA output.  Do not change.
        VGA_CLK,                        //  VGA Clock
        VGA_HS,                         //  VGA H_SYNC
        VGA_VS,                         //  VGA V_SYNC
        VGA_BLANK_N,                        //  VGA BLANK
        VGA_SYNC_N,                     //  VGA SYNC
        VGA_R,                          //  VGA Red[9:0]
        VGA_G,                          //  VGA Green[9:0]
        VGA_B                           //  VGA Blue[9:0]
    );

    input           CLOCK_50;               //  50 MHz
    input   [9:0]   SW;
    input   [3:0]   KEY;
    output [17:0] LEDR;
    // Declare your inputs and outputs here
    // Do not change the following outputs
    output          VGA_CLK;                //  VGA Clock
    output          VGA_HS;                 //  VGA H_SYNC
    output          VGA_VS;                 //  VGA V_SYNC
    output          VGA_BLANK_N;                //  VGA BLANK
    output          VGA_SYNC_N;             //  VGA SYNC
    output  [9:0]   VGA_R;                  //  VGA Red[9:0]
    output  [9:0]   VGA_G;                  //  VGA Green[9:0]
    output  [9:0]   VGA_B;                  //  VGA Blue[9:0]

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

    assign go = ~KEY[0];
    assign left = ~KEY[3];
    assign right = ~KEY[2];

    wire load_level, level_pause, play, game_over; // game states
    wire [7:0] playerX, enemy0X, enemy1X;
    wire [6:0] playerY, enemy0Y, enemy1Y;
    wire [2:0] ani_state, enemy_out;
    wire player_move, animate_done;
    wire player_hit, player_hit0, player_hit1;
    wire enemy_move, enemy0_move, enemy1_move;
    wire [27:0] count;
    wire [2:0] enemy0_width, enemy1_width;
    reg [7:0] enemyX;
    reg [6:0] enemyY;
    reg [2:0] enemy_width;

    assign enemy_move = enemy0_move || enemy1_move;
    assign player_hit = player_hit0 || player_hit1;

    always@(enemy_out, enemy0X, enemy0Y) begin
        case(enemy_out)
            3'd0: begin
                enemyX <= enemy0X;
                enemyY <= enemy0Y;
                enemy_width <= enemy0_width;
            end
            3'd1: begin
                enemyX <= enemy1X;
                enemyY <= enemy1Y;
                enemy_width <= enemy1_width;
            end
            default: begin
                enemyX <= enemy0X;
                enemyY <= enemy0Y;
                enemy_width <= enemy0_width;
            end
        endcase
    end

    // DEBUGGING
    //assign LEDR[0] = load_level;
    //assign LEDR[1] = level_pause;
    //assign LEDR[2] = play;
    //assign LEDR[14:11] = count;

    datapath d0(
        .playerX(playerX),
        .playerY(playerY),
        .enemyX(enemyX),
        .enemyY(enemyY),
        .enemy_width(enemy_width),
        .enemy_count(3'd2),
        .ani_state(ani_state),
        .resetn(resetn),
        .clk(CLOCK_50),
        .ani_done(animate_done),
        .enemy_out(enemy_out),
        .x(x),
        .y(y),
        .colour(colour),
        .drawEn(writeEn)
    );

    control c0(
        .go(go),
        .player_hit(player_hit),
        .resetn(resetn),
        .clk(CLOCK_50),
        .load_level(load_level),
        .level_pause(level_pause),
        .play(play),
        .game_over(game_over)
    );

    player_control pc0(
        .left(left),
        .right(right),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .move(player_move),
        .playerX(playerX),
        .playerY(playerY)
    );

    animate_control ac0(
        .load_level(load_level),
        .game_over(game_over),
        .player_move(player_move),
        .enemy_move(enemy_move),
        .ani_done(animate_done),
        .resetn(resetn),
        .clk(CLOCK_50),
        .ani_state(ani_state)
    );

    // test 3x3 enemy spawned at (80, 60) moving at 45 degree angle down and to the right
    // I didn't actually try to draw the enemy yet, only calculated the x and y
    enemy_control ec0(
        .width(3'd7),
        .start_x(8'd80),
        .start_y(7'd60),
        .d_x(3'd1),
        .d_y(3'd1),
        .leftwards(1'b0),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit0),
        .move(enemy0_move),
        .enemyX(enemy0X),
        .enemyY(enemy0Y),
        .enemy_width(enemy0_width)
    );

    enemy_control ec1(
        .width(3'd7),
        .start_x(8'd100),
        .start_y(7'd50),
        .d_x(3'd1),
        .d_y(3'd1),
        .leftwards(1'b1),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit1),
        .move(enemy1_move),
        .enemyX(enemy1X),
        .enemyY(enemy1Y),
        .enemy_width(enemy1_width)
    );
endmodule

// controls game states
module control(go, player_hit, resetn, clk, load_level, level_pause, play, game_over);
    input go, player_hit, resetn, clk;
    output load_level, level_pause, play, game_over;

    reg [2:0] state, state_next;
    localparam LEVEL_SELECT = 3'b000, LOAD_LEVEL = 3'b001, LEVEL_PAUSE = 3'b010,    // states
            PLAY_START = 3'b011, PLAY = 3'b100, GAME_OVER = 3'b101, PAUSING = 3'b110;

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
                else if (player_hit) state_next <= GAME_OVER;
                else state_next <= PLAY;
            end
            PAUSING: begin
                if (!go) state_next <= LEVEL_PAUSE;
                else state_next <= PAUSING;
            end
            GAME_OVER: begin
                if (go) state_next <= LOAD_LEVEL;
                else state_next <= GAME_OVER;
            end
            default: state_next = LEVEL_SELECT;
        endcase
    end // state_table

    // State Registers
    always @(posedge clk)
    begin: state_FFs
        if(!resetn)
            state <= LEVEL_SELECT;
        else
            state <= state_next;
    end // state_FFS

    // Output logic
    assign load_level = (state == LOAD_LEVEL);
    assign level_pause = (state == LEVEL_PAUSE);
    assign play = (state == PLAY);
    assign game_over = (state == GAME_OVER);
endmodule

// controls what is being drawn
module animate_control(
    input load_level,
    input game_over,
    input player_move,
    input enemy_move,
    input ani_done,
    input resetn,
    input clk,
    output reg [2:0] ani_state
    );

    reg [2:0] state_next;
    localparam IDLE = 3'b000, DRAW = 3'b001, LEVEL = 3'b010, ERASE = 3'b011,
            ERASEtoDRAW = 3'b100; // draw states

    always@(*)
    begin: state_table
        case (ani_state)
            IDLE: begin
                if (game_over) state_next <= IDLE;
                else if (player_move || enemy_move) state_next <= ERASE;
                else if (load_level) state_next <= LEVEL;
                else state_next <= IDLE;
            end
            DRAW: begin
                if (ani_done) state_next <= IDLE;
                else state_next <= DRAW;
            end
            ERASE: begin
                if (ani_done) state_next <= ERASEtoDRAW;
                else state_next <= ERASE;
            end
            LEVEL: begin
                if (ani_done) state_next <= IDLE;
                else state_next <= LEVEL;
            end
            ERASEtoDRAW: begin
                if (!ani_done) state_next <= DRAW;
                else state_next <= ERASEtoDRAW;
            end
            default: state_next = IDLE;
        endcase
    end // state_table

    // State Registers
    always @(posedge clk)
    begin: state_FFs
        if(!resetn)
            ani_state <= IDLE;
        else
            ani_state <= state_next;
    end // state_FFS
endmodule

// does the drawing
module datapath(
    input [7:0] playerX,
    input [6:0] playerY,
    input [7:0] enemyX,
    input [6:0] enemyY,
    input [2:0] enemy_width,
    input [2:0] enemy_count,
    input [2:0] ani_state,
    input resetn,
    input clk,
    output reg ani_done,
    output reg [2:0] enemy_out,
    output reg [7:0] x,
    output reg [6:0] y,
    output reg [2:0] colour,
    output reg drawEn
    );

    localparam IDLE = 3'b000, DRAW = 3'b001, LEVEL = 3'b010, ERASE = 3'b011; // draw states
    reg [27:0] counter;

    initial begin
        ani_done <= 0;
        counter <= 0;
        enemy_out <= 0;
    end

    always@(posedge clk) begin
        if (!resetn) begin
            ani_done <= 0;
            drawEn <= 0;
            counter <= 0;
            enemy_out <= 0;
        end else if (ani_state == LEVEL || ani_state == DRAW) begin
            drawEn <= 1;
            colour <= `PLAYER_COLOR;
            if (counter == 0) begin
                x <= playerX;
                y <= playerY;
            end else if (counter < `PLAYER_SIZE) begin
                // draw player
                if (y <= playerY + `PLAYER_WIDTH - 1) begin
                    if (x < playerX + `PLAYER_WIDTH - 1) begin
                        x <= x + 1;
                    end else if (y < playerY + `PLAYER_WIDTH - 1) begin
                        x <= playerX;
                        y <= y + 1;
                    end
                end
            end else if (counter <= `PLAYER_SIZE + (enemy_width * enemy_width)) begin
                // draw enemies
                if (counter <= `PLAYER_SIZE + 1) begin
                    x <= enemyX;
                    y <= enemyY;
                end else if (y <= enemyY + enemy_width - 1) begin
                    if (x < enemyX + enemy_width - 1) begin
                        x <= x + 1;
                    end else if (y < enemyY + enemy_width - 1) begin
                        x <= enemyX;
                        y <= y + 1;
                    end
                end
            end else if (counter <= `PLAYER_SIZE + (enemy_width * enemy_width) + 1) begin
                // draw phallus
                x <= playerX + 1;
                y <= playerY - 1;
            end

            if (counter == `PLAYER_SIZE + (enemy_width * enemy_width) && enemy_out < enemy_count - 1) begin
                // draw next enemy
                enemy_out <= enemy_out + 1;
                counter <= `PLAYER_SIZE;
            end else begin
                counter <= counter + 1;
            end

            // done drawing
            if (counter > `PLAYER_SIZE + (enemy_width * enemy_width) + 1) begin
                ani_done <= 1'b1;
                enemy_out <= 0;
            end
        end else if (!resetn || ani_state == ERASE) begin
            drawEn <= 1;
            colour <= 3'b000;
            if (counter == 0) begin
                x <= 1;
                y <= 1;
            end else if (counter < `SCREEN_W * `SCREEN_H) begin
                if (y <= `SCREEN_H) begin
                    if (x < `SCREEN_W) begin
                        x <= x + 1;
                    end else if (y < `SCREEN_H) begin
                        x <= 1;
                        y <= y + 1;
                    end
                end
            end
            counter <= counter + 1;

            // done drawing
            if (counter > `SCREEN_W * `SCREEN_H) begin
                ani_done <= 1'b1;
            end
        end else begin
            drawEn <= 0;
            ani_done <= 0;
            counter <= 0;
        end
    end
endmodule
