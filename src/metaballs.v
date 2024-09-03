`default_nettype none

module vga(
	input wire clk_100mhz,
	input wire reset,
	output reg h_sync,
	output reg v_sync,

	output wire display,
	output wire[9:0] x,
	output reg[9:0] y
);
	// H_TIME_* is in hundreds of microseconds, writen nn_mm, where
	// nn is the microsecond part, _ is substituting for a decimal
	// separator, and mm is the fractional microsecond.

	// 800x600 @ 72Hz
	parameter H_TIME_VISIBLE_AREA  = 16_00,
		      H_TIME_FRONT_PORCH   =  1_12,
		      H_TIME_SYNC_PULSE    =  2_40,
		      H_TIME_WHOLE_LINE    = 20_80,

		      V_LINES_VISIBLE_AREA =   600,
		      V_LINES_FRONT_PORCH  =    37,
		      V_LINES_SYNC_PULSE   =     6,
		      V_LINES_WHOLE_FRAME  =   666,

		      H_LOG_DIVISOR        =     1; // 50MHz pixel clock

	reg[11:0] h_counter;
	reg h_display;
	reg v_display;
	assign display = h_display & v_display;
	assign x = h_counter[10:H_LOG_DIVISOR]; // 50MHz pixel clock
	// wire half_x = h_counter[0];

	always @(posedge clk_100mhz) begin
		// 0.00000001s = 0.00001ms = 0.01us
		// (31_77+1) * 0.01 = 31.78us
		//if (h_counter == 31_77) begin

		if (reset) begin
			h_counter <= 0;
			h_display <= 1;
			v_display <= 1;
			y <= 0;
			h_sync <= 1;
			v_sync <= 1;
		end else begin
			if (h_counter == H_TIME_WHOLE_LINE-1) begin
				h_counter <= 0;
				if (y == V_LINES_WHOLE_FRAME-1) begin
					v_display <= 1; // begining of vertical display
					y <= 0;
				end else begin
					y <= y + 1;
				end

				if (y == V_LINES_VISIBLE_AREA-1) v_display <= 0; // all way display
				if (y == V_LINES_VISIBLE_AREA+V_LINES_FRONT_PORCH-1) v_sync <= 0; // v_sync start
				if (y == V_LINES_VISIBLE_AREA+V_LINES_FRONT_PORCH+V_LINES_SYNC_PULSE-1) v_sync <= 1; // v_sync end
			end else begin
				h_counter <= h_counter + 1;
			end

			if (h_counter == H_TIME_WHOLE_LINE-1) h_display <= 1; // beginning of horizontal display
			if (h_counter == H_TIME_VISIBLE_AREA-1) h_display <= 0; // all the way display

			if (h_counter == H_TIME_VISIBLE_AREA+H_TIME_FRONT_PORCH-1) h_sync <= 0; // start h_sync
			if (h_counter == H_TIME_VISIBLE_AREA+H_TIME_FRONT_PORCH+H_TIME_SYNC_PULSE-1) h_sync <= 1; // end   h_sync
		end
	end
endmodule

module ball
#(
	parameter START_X = 30,
	parameter START_Y = 20,
	parameter BALL_SPEED = 5
)
(
	input wire[9:0] x,
	input wire[9:0] y,
	output wire[14:0] dist_sq,
	output wire overflow,

	input wire v_sync
);
	parameter SCREEN_WIDTH    = 800,
		      SCREEN_HEIGHT   = 600,
		      BALL_DIM        = 25;

	reg[9:0] ball_x = BALL_SPEED*START_X;
	reg[9:0] ball_y = BALL_SPEED*START_Y;
	reg ball_vx = 1;
	reg ball_vy = 1;

	wire[9:0] dx = x > ball_x ? x-ball_x : ball_x-x;
	wire[9:0] dy = y > ball_y ? y-ball_y : ball_y-y;

	wire[3:0] bit_count_x =
		  dx[9] == 1 ? 10
		: dx[8] == 1 ? 9
		: dx[7] == 1 ? 8
		: dx[6] == 1 ? 7
		: dx[5] == 1 ? 6
		: dx[4] == 1 ? 5
		: dx[3] == 1 ? 4
		: dx[2] == 1 ? 3
		: dx[1] == 1 ? 2
		: 0;

	wire[3:0] bit_count_y =
		  dy[9] == 1 ? 10
		: dy[8] == 1 ? 9
		: dy[7] == 1 ? 8
		: dy[6] == 1 ? 7
		: dy[5] == 1 ? 6
		: dy[4] == 1 ? 5
		: dy[3] == 1 ? 4
		: dy[2] == 1 ? 3
		: dy[1] == 1 ? 2
		: 0;

	wire overflow_x = bit_count_x + bit_count_x > 14;
	wire overflow_y = bit_count_y + bit_count_y > 14;

	// 800*800+600*600 = 1_000_000
	// log2 = 19.9
	// needs 20 bits
	//wire[14:0] dist_sq = dx*dx + dy*dy;
	assign dist_sq = dx*dx + dy*dy;
	assign overflow = overflow_x || overflow_y;

	always @(posedge v_sync) begin
		if (ball_vy) ball_y <= ball_y + BALL_SPEED;
		else         ball_y <= ball_y - BALL_SPEED;

		if (ball_y == BALL_SPEED)       ball_vy <= 1;
		if (ball_y == SCREEN_HEIGHT-BALL_DIM-BALL_SPEED) ball_vy <= 0;

		if (ball_vx) ball_x <= ball_x + BALL_SPEED;
		else         ball_x <= ball_x - BALL_SPEED;

		ball_vx <=
			ball_x == BALL_SPEED ? 1
			: ball_x == SCREEN_WIDTH-BALL_DIM-BALL_SPEED ? 0
			: ball_vx;
	end

endmodule

module metaballs(
	output wire rgb,
	input wire v_sync,

	input wire display,
	input wire[9:0] x,
	input wire[9:0] y
);
	wire[14:0] dist_sq_0;
	wire overflow_0;
	ball b_0(x, y, dist_sq_0, overflow_0, v_sync);
	wire[14:0] dist_sq_1;
	wire overflow_1;
	ball #(.START_X(10), .START_Y(50)) b_1(x, y, dist_sq_1, overflow_1, v_sync);

	reg pix = 0;
	always @(posedge x[0]) begin
		pix <= (!overflow_0 && dist_sq_0 < 625) || (!overflow_1 && dist_sq_1 < 625);
	end

	assign rgb = display && pix;

endmodule
