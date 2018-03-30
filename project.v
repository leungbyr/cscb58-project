// CSCB58 Winter 2018 Final Project
// Bubble Trouble Knockoff
// Names: Jeffrey So, Ricky Chen, Byron Leung, Brandon Shewnarain
// Description: Insert Description Here

`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

`define SCREEN_W 8'd160
`define SCREEN_H 7'd121
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
    assign resetn = SW[9];

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
    assign fire = ~KEY[1];
    wire [2:0] level;
    assign level = SW[2:0];

    wire load_level, level_pause, play, game_over, level_select; // game states
    wire [7:0] playerX, bulletX, enemy0X, enemy1X, enemy2X;
    wire [6:0] playerY, bulletY, enemy0Y, enemy1Y, enemy2Y;
    wire [2:0] ani_state;
    wire [3:0] enemy_count, enemy_out;
    wire player_move, bullet_move, animate_done;
    wire enemy_move, enemy0_move, enemy1_move, enemy2_move;
    wire player_hit, player_hit0, player_hit1, player_hit2;
    wire bullet_hit, bullet_hit0, bullet_hit1, bullet_hit2;
    wire [2:0] enemy0_width, enemy1_width, enemy2_width;
    reg [7:0] enemyX;
    reg [6:0] enemyY;
    reg [2:0] enemy_width;
    reg [3:0] enemies_alive;
    wire [3:0] enemies_enabled;
    wire [14:0] enemies;
    wire [2:0] enemy_color;

    assign enemy_count = 4'd3;
    assign enemy_move = enemy0_move || enemy1_move || enemy2_move;
    assign player_hit = player_hit0 || player_hit1 || player_hit2;
    assign bullet_hit = bullet_hit0 || bullet_hit1 || bullet_hit2;
    assign enemy0_enable = (enemies & 15'b000000000000001) > 0 ? 1 : 0;
    assign enemy1_enable = (enemies & 15'b000000000000010) > 0 ? 1 : 0;
    assign enemy2_enable = (enemies & 15'b000000000000100) > 0 ? 1 : 0;

    always@(*) begin
        case(enemy_out)
            4'd0: begin
                enemyX <= enemy0X;
                enemyY <= enemy0Y;
                enemy_width <= enemy0_width;
            end
            4'd1: begin
                enemyX <= enemy1X;
                enemyY <= enemy1Y;
                enemy_width <= enemy1_width;
            end
            4'd2: begin
                enemyX <= enemy2X;
                enemyY <= enemy2Y;
                enemy_width <= enemy2_width;
            end
            default: begin
                enemyX <= enemy0X;
                enemyY <= enemy0Y;
                enemy_width <= enemy0_width;
            end
        endcase
        
        if (load_level) begin
            enemies_alive <= enemies_enabled;
        end
    end
    
    always@(posedge bullet_hit) begin
        enemies_alive <= enemies_alive - 1;
    end
    
    // DEBUGGING
    //assign LEDR[0] = load_level;
    //assign LEDR[1] = level_pause;
    //assign LEDR[2] = play
    //assign LEDR[3] = game_over;
    //assign LEDR[14:11] = count;

    datapath d0(
        .playerX(playerX),
        .playerY(playerY),
        .enemyX(enemyX),
        .enemyY(enemyY),
        .enemy_color(enemy_color),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enemy_width(enemy_width),
        .enemy_count(enemy_count),
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
        .enemies_alive(enemies_alive),
        .resetn(resetn),
        .clk(CLOCK_50),
        .load_level(load_level),
        .level_pause(level_pause),
        .play(play),
        .game_over(game_over),
        .level_select(level_select)
    );

    player_control pc0(
        .left(left),
        .right(right),
        .play(play),
        .load_level(load_level),
        .resetn(resetn),
        .clk(CLOCK_50),
        .move(player_move),
        .playerX(playerX),
        .playerY(playerY)
    );
    
    bullet_control bc0(
        .fire(fire),
        .playerX(playerX),
        .playerY(playerY),
        .bullet_hit(bullet_hit),
        .play(play),
        .load_level(load_level),
        .resetn(resetn),
        .clk(CLOCK_50),
        .move(bullet_move),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enemy_color(enemy_color)
    );

    animate_control ac0(
        .load_level(load_level),
        .game_over(game_over),
        .player_move(player_move),
        .bullet_move(bullet_move),
        .enemy_move(enemy_move),
        .ani_done(animate_done),
        .resetn(resetn),
        .clk(CLOCK_50),
        .ani_state(ani_state)
    );
    
    level_select ls0(
        .level(level),
        .level_select(level_select),
        .clk(CLOCK_50),
        .enemies_enabled(enemies_enabled),
        .enemies(enemies)
    );

    // TODO: having different size enemies causes random stuff
    // adding enemies screws up game over
    enemy_control ec0(
        .width(3'd3),
        .start_x(8'd80),
        .start_y(7'd60),
        .d_x(3'd1),
        .d_y(3'd1),
        .leftwards(1'b0),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy0_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit0),
        .bullet_hit(bullet_hit0),
        .move(enemy0_move),
        .enemyX(enemy0X),
        .enemyY(enemy0Y),
        .enemy_width(enemy0_width)
    );

    enemy_control ec1(
        .width(3'd5),
        .start_x(8'd100),
        .start_y(7'd50),
        .d_x(3'd1),
        .d_y(3'd1),
        .leftwards(1'b1),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy1_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit1),
        .bullet_hit(bullet_hit1),
        .move(enemy1_move),
        .enemyX(enemy1X),
        .enemyY(enemy1Y),
        .enemy_width(enemy1_width)
    );

    enemy_control ec2(
        .width(3'd7),
        .start_x(8'd30),
        .start_y(7'd100),
        .d_x(3'd1),
        .d_y(3'd1),
        .leftwards(1'b0),
        .upwards(1'b1),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy2_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit2),
        .bullet_hit(bullet_hit2),
        .move(enemy2_move),
        .enemyX(enemy2X),
        .enemyY(enemy2Y),
        .enemy_width(enemy2_width)
    );
endmodule

// controls game states
module control(
    input go,
    input player_hit,
    input [3:0] enemies_alive,
    input resetn,
    input clk,
    output load_level,
    output level_pause,
    output play,
    output game_over,
    output level_select
    );

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
                else if (player_hit || enemies_alive == 0) state_next <= GAME_OVER;
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
    assign level_select = (state == LEVEL_SELECT);
endmodule

// controls what is being drawn
module animate_control(
    input load_level,
    input game_over,
    input player_move,
    input bullet_move,
    input enemy_move,
    input ani_done,
    input resetn,
    input clk,
    output reg [2:0] ani_state
    );

    reg [2:0] state_next;
    localparam IDLE = 3'b000, DRAW = 3'b001, LEVEL = 3'b010, ERASE = 3'b011,    // draw states
            ERASEtoDRAW = 3'b100, OVER_ERASE = 3'b101, GAME_OVER = 3'b110, OVERtoLEVEL = 3'b111;

    always@(*)
    begin: state_table
        case (ani_state)
            IDLE: begin
                if (game_over) state_next <= GAME_OVER;
                else if (player_move || enemy_move || bullet_move) state_next <= ERASE;
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
            GAME_OVER: begin
                if (load_level) state_next <= OVER_ERASE;
                else state_next <= GAME_OVER;
            end
            OVER_ERASE: begin
                if (ani_done) state_next <= OVERtoLEVEL;
                else state_next <= OVER_ERASE;
            end
            OVERtoLEVEL: begin
                if (!ani_done) state_next <= LEVEL;
                else state_next <= OVERtoLEVEL;
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

module level_select(
    input [2:0] level,
    input level_select,
    input clk,
    output reg [3:0] enemies_enabled,
    output reg [14:0] enemies
    );
    
    always@(posedge clk) begin
        if (level_select) begin
            case (level)
                3'd1: begin
                    enemies <= 15'b000000000000011;  
                    enemies_enabled <= 4'd2;
                end
                3'd2: begin
                    enemies <= 15'b000000000000111;
                    enemies_enabled <= 4'd3;
                end
                default: begin
                    enemies <= 15'b000000000000011;
                    enemies_enabled <= 4'd2;
                end
            endcase
        end
    end
endmodule

// does the drawing
module datapath(
    input [7:0] playerX,
    input [6:0] playerY,
    input [7:0] enemyX,
    input [6:0] enemyY,
    input [2:0] enemy_color,
    input [7:0] bulletX,
    input [6:0] bulletY,
    input [2:0] enemy_width,
    input [3:0] enemy_count,
    input [2:0] ani_state,
    input resetn,
    input clk,
    output reg ani_done,
    output reg [3:0] enemy_out,
    output reg [7:0] x,
    output reg [6:0] y,
    output reg [2:0] colour,
    output reg drawEn
    );

    localparam IDLE = 3'b000, DRAW = 3'b001, LEVEL = 3'b010, ERASE = 3'b011,    // draw states
            ERASEtoDRAW = 3'b100, OVER_ERASE = 3'b101, GAME_OVER = 3'b110, OVERtoLEVEL = 3'b111;
    reg [27:0] counter;
    reg [7:0] player_x, enemy_x, bullet_x;
    reg [6:0] player_y, enemy_y, bullet_y;

    initial begin
        ani_done <= 0;
        counter <= 0;
        enemy_out <= 0;
    end

    always@(posedge clk) begin
        if (!resetn || ani_state == ERASE || ani_state == OVER_ERASE) begin
            drawEn <= 1;
            colour <= 3'b000;
            if (counter == 0) begin
                x <= 0;
                y <= 0;
            end else if (counter < `SCREEN_W * `SCREEN_H) begin
                if (y <= `SCREEN_H) begin
                    if (x < `SCREEN_W) begin
                        x <= x + 1;
                    end else if (y < `SCREEN_H) begin
                        x <= 0;
                        y <= y + 1;
                    end
                end
            end
            counter <= counter + 1;

            // done drawing
            if (counter > `SCREEN_W * `SCREEN_H) begin
                ani_done <= 1'b1;
                drawEn <= 0;
            end
        end else if (ani_state == LEVEL || ani_state == DRAW) begin
            drawEn <= 1;
            colour <= `PLAYER_COLOR; // default
            if (counter == 0) begin
                player_x <= playerX;
                player_y <= playerY;
                bullet_x <= bulletX;
                bullet_y <= bulletY;
                x <= playerX;
                y <= playerY;
            end else if (counter < `PLAYER_SIZE) begin
                // draw player
                if (y <= player_y + `PLAYER_WIDTH - 1) begin
                    if (x < player_x + `PLAYER_WIDTH - 1) begin
                        x <= x + 1;
                    end else if (y < player_y + `PLAYER_WIDTH - 1) begin
                        x <= player_x;
                        y <= y + 1;
                    end
                end
            end else if (counter < `PLAYER_SIZE + (enemy_width * enemy_width)) begin
                // draw enemies
                colour <= enemy_color;
                if (counter == `PLAYER_SIZE) begin
                    x <= enemyX;
                    y <= enemyY;
                    enemy_x <= enemyX;
                    enemy_y <= enemyY;
                end else if (y <= enemy_y + enemy_width - 1) begin
                    if (x < enemy_x + enemy_width - 1) begin
                        x <= x + 1;
                    end else if (y < enemy_y + enemy_width - 1) begin
                        x <= enemy_x;
                        y <= y + 1;
                    end
                end
            end else if (counter < `PLAYER_SIZE + (enemy_width * enemy_width) + 1) begin
                // draw phallus
                x <= player_x + 1;
                y <= player_y - 1;
            end else if (counter < `PLAYER_SIZE + (enemy_width * enemy_width) + 2) begin
                // draw bullet
                x <= bullet_x;
                y <= bullet_y;
            end
            
            if ((counter == `PLAYER_SIZE + (enemy_width * enemy_width) - 1
                || (counter >= `PLAYER_SIZE + (enemy_width * enemy_width) && enemy_width == 0))
                && enemy_out < enemy_count - 1) begin
                // draw next enemy
                enemy_out <= enemy_out + 1;
                counter <= `PLAYER_SIZE;
            end else begin
                counter <= counter + 1;
            end

            // done drawing
            if (counter >= `PLAYER_SIZE + (enemy_width * enemy_width) + 1) begin
                ani_done <= 1'b1;
                enemy_out <= 0;
            end
        end else begin
            drawEn <= 0;
            ani_done <= 0;
            counter <= 0;
        end
    end
endmodule
