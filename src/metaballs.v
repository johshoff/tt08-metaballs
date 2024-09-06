`default_nettype none

module vga(
	input wire clk_50mhz,
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
	parameter H_TIME_VISIBLE_AREA  =  8_00,
		      H_TIME_FRONT_PORCH   =    56,
		      H_TIME_SYNC_PULSE    =  1_20,
		      H_TIME_WHOLE_LINE    = 10_40,

		      V_LINES_VISIBLE_AREA =   600,
		      V_LINES_FRONT_PORCH  =    37,
		      V_LINES_SYNC_PULSE   =     6,
		      V_LINES_WHOLE_FRAME  =   666;

	reg[10:0] h_counter;
	reg h_display;
	reg v_display;
	assign display = h_display & v_display;
	assign x = h_counter[9:0];

	always @(posedge clk_50mhz) begin
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
	output wire[7:0] out,

	input wire v_sync
);
	parameter SCREEN_WIDTH    = 800,
		      SCREEN_HEIGHT   = 600,
		      BALL_DIM        = 25;

	reg[7:0] bs[0:255];

	reg[9:0] ball_x = BALL_SPEED*START_X;
	reg[9:0] ball_y = BALL_SPEED*START_Y;
	reg ball_vx = 1;
	reg ball_vy = 1;

	wire[9:0] dx = x-ball_x;
	wire[9:0] dy = y-ball_y;

	assign out[7:0] =
	          x < ball_x ? 0
	        : y < ball_y ? 0
	        : x >= ball_x + 64 ? 0
	        : y >= ball_y + 64 ? 0
	        : bs[{ dy[3:0], dx[3:0] }];

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

	initial begin
		bs[0] = 8'h02;
		bs[1] = 8'h02;
		bs[2] = 8'h02;
		bs[3] = 8'h03;
		bs[4] = 8'h03;
		bs[5] = 8'h04;
		bs[6] = 8'h04;
		bs[7] = 8'h04;
		bs[8] = 8'h05;
		bs[9] = 8'h05;
		bs[10] = 8'h05;
		bs[11] = 8'h06;
		bs[12] = 8'h06;
		bs[13] = 8'h06;
		bs[14] = 8'h06;
		bs[15] = 8'h06;
		bs[16] = 8'h02;
		bs[17] = 8'h03;
		bs[18] = 8'h03;
		bs[19] = 8'h03;
		bs[20] = 8'h04;
		bs[21] = 8'h04;
		bs[22] = 8'h05;
		bs[23] = 8'h05;
		bs[24] = 8'h06;
		bs[25] = 8'h06;
		bs[26] = 8'h06;
		bs[27] = 8'h07;
		bs[28] = 8'h07;
		bs[29] = 8'h07;
		bs[30] = 8'h07;
		bs[31] = 8'h07;
		bs[32] = 8'h02;
		bs[33] = 8'h03;
		bs[34] = 8'h03;
		bs[35] = 8'h04;
		bs[36] = 8'h04;
		bs[37] = 8'h05;
		bs[38] = 8'h05;
		bs[39] = 8'h06;
		bs[40] = 8'h06;
		bs[41] = 8'h07;
		bs[42] = 8'h07;
		bs[43] = 8'h08;
		bs[44] = 8'h08;
		bs[45] = 8'h08;
		bs[46] = 8'h09;
		bs[47] = 8'h09;
		bs[48] = 8'h03;
		bs[49] = 8'h03;
		bs[50] = 8'h04;
		bs[51] = 8'h04;
		bs[52] = 8'h05;
		bs[53] = 8'h05;
		bs[54] = 8'h06;
		bs[55] = 8'h07;
		bs[56] = 8'h07;
		bs[57] = 8'h08;
		bs[58] = 8'h08;
		bs[59] = 8'h09;
		bs[60] = 8'h09;
		bs[61] = 8'h0a;
		bs[62] = 8'h0a;
		bs[63] = 8'h0a;
		bs[64] = 8'h03;
		bs[65] = 8'h04;
		bs[66] = 8'h04;
		bs[67] = 8'h05;
		bs[68] = 8'h06;
		bs[69] = 8'h06;
		bs[70] = 8'h07;
		bs[71] = 8'h08;
		bs[72] = 8'h08;
		bs[73] = 8'h09;
		bs[74] = 8'h0a;
		bs[75] = 8'h0a;
		bs[76] = 8'h0b;
		bs[77] = 8'h0b;
		bs[78] = 8'h0b;
		bs[79] = 8'h0c;
		bs[80] = 8'h04;
		bs[81] = 8'h04;
		bs[82] = 8'h05;
		bs[83] = 8'h05;
		bs[84] = 8'h06;
		bs[85] = 8'h07;
		bs[86] = 8'h08;
		bs[87] = 8'h08;
		bs[88] = 8'h09;
		bs[89] = 8'h0a;
		bs[90] = 8'h0b;
		bs[91] = 8'h0c;
		bs[92] = 8'h0c;
		bs[93] = 8'h0d;
		bs[94] = 8'h0d;
		bs[95] = 8'h0e;
		bs[96] = 8'h04;
		bs[97] = 8'h05;
		bs[98] = 8'h05;
		bs[99] = 8'h06;
		bs[100] = 8'h07;
		bs[101] = 8'h08;
		bs[102] = 8'h09;
		bs[103] = 8'h09;
		bs[104] = 8'h0a;
		bs[105] = 8'h0b;
		bs[106] = 8'h0c;
		bs[107] = 8'h0d;
		bs[108] = 8'h0e;
		bs[109] = 8'h0f;
		bs[110] = 8'h10;
		bs[111] = 8'h10;
		bs[112] = 8'h04;
		bs[113] = 8'h05;
		bs[114] = 8'h06;
		bs[115] = 8'h07;
		bs[116] = 8'h08;
		bs[117] = 8'h08;
		bs[118] = 8'h09;
		bs[119] = 8'h0b;
		bs[120] = 8'h0c;
		bs[121] = 8'h0d;
		bs[122] = 8'h0e;
		bs[123] = 8'h0f;
		bs[124] = 8'h10;
		bs[125] = 8'h11;
		bs[126] = 8'h12;
		bs[127] = 8'h13;
		bs[128] = 8'h05;
		bs[129] = 8'h06;
		bs[130] = 8'h06;
		bs[131] = 8'h07;
		bs[132] = 8'h08;
		bs[133] = 8'h09;
		bs[134] = 8'h0a;
		bs[135] = 8'h0c;
		bs[136] = 8'h0d;
		bs[137] = 8'h0e;
		bs[138] = 8'h10;
		bs[139] = 8'h12;
		bs[140] = 8'h13;
		bs[141] = 8'h14;
		bs[142] = 8'h15;
		bs[143] = 8'h16;
		bs[144] = 8'h05;
		bs[145] = 8'h06;
		bs[146] = 8'h07;
		bs[147] = 8'h08;
		bs[148] = 8'h09;
		bs[149] = 8'h0a;
		bs[150] = 8'h0b;
		bs[151] = 8'h0d;
		bs[152] = 8'h0e;
		bs[153] = 8'h10;
		bs[154] = 8'h12;
		bs[155] = 8'h14;
		bs[156] = 8'h16;
		bs[157] = 8'h18;
		bs[158] = 8'h1a;
		bs[159] = 8'h1b;
		bs[160] = 8'h05;
		bs[161] = 8'h06;
		bs[162] = 8'h07;
		bs[163] = 8'h08;
		bs[164] = 8'h0a;
		bs[165] = 8'h0b;
		bs[166] = 8'h0c;
		bs[167] = 8'h0e;
		bs[168] = 8'h10;
		bs[169] = 8'h12;
		bs[170] = 8'h15;
		bs[171] = 8'h17;
		bs[172] = 8'h1a;
		bs[173] = 8'h1d;
		bs[174] = 8'h1f;
		bs[175] = 8'h20;
		bs[176] = 8'h06;
		bs[177] = 8'h07;
		bs[178] = 8'h08;
		bs[179] = 8'h09;
		bs[180] = 8'h0a;
		bs[181] = 8'h0c;
		bs[182] = 8'h0d;
		bs[183] = 8'h0f;
		bs[184] = 8'h12;
		bs[185] = 8'h14;
		bs[186] = 8'h17;
		bs[187] = 8'h1b;
		bs[188] = 8'h1e;
		bs[189] = 8'h22;
		bs[190] = 8'h26;
		bs[191] = 8'h29;
		bs[192] = 8'h06;
		bs[193] = 8'h07;
		bs[194] = 8'h08;
		bs[195] = 8'h09;
		bs[196] = 8'h0b;
		bs[197] = 8'h0c;
		bs[198] = 8'h0e;
		bs[199] = 8'h10;
		bs[200] = 8'h13;
		bs[201] = 8'h16;
		bs[202] = 8'h1a;
		bs[203] = 8'h1e;
		bs[204] = 8'h24;
		bs[205] = 8'h2a;
		bs[206] = 8'h30;
		bs[207] = 8'h34;
		bs[208] = 8'h06;
		bs[209] = 8'h07;
		bs[210] = 8'h08;
		bs[211] = 8'h0a;
		bs[212] = 8'h0b;
		bs[213] = 8'h0d;
		bs[214] = 8'h0f;
		bs[215] = 8'h11;
		bs[216] = 8'h14;
		bs[217] = 8'h18;
		bs[218] = 8'h1d;
		bs[219] = 8'h22;
		bs[220] = 8'h2a;
		bs[221] = 8'h33;
		bs[222] = 8'h3d;
		bs[223] = 8'h47;
		bs[224] = 8'h06;
		bs[225] = 8'h07;
		bs[226] = 8'h09;
		bs[227] = 8'h0a;
		bs[228] = 8'h0b;
		bs[229] = 8'h0d;
		bs[230] = 8'h10;
		bs[231] = 8'h12;
		bs[232] = 8'h15;
		bs[233] = 8'h1a;
		bs[234] = 8'h1f;
		bs[235] = 8'h26;
		bs[236] = 8'h30;
		bs[237] = 8'h3d;
		bs[238] = 8'h51;
		bs[239] = 8'h69;
		bs[240] = 8'h06;
		bs[241] = 8'h07;
		bs[242] = 8'h09;
		bs[243] = 8'h0a;
		bs[244] = 8'h0c;
		bs[245] = 8'h0e;
		bs[246] = 8'h10;
		bs[247] = 8'h13;
		bs[248] = 8'h16;
		bs[249] = 8'h1b;
		bs[250] = 8'h20;
		bs[251] = 8'h29;
		bs[252] = 8'h34;
		bs[253] = 8'h47;
		bs[254] = 8'h69;
		bs[255] = 8'hab;
	end

endmodule

module metaballs(
	output wire rgb,
	input wire v_sync,

	input wire display,
	input wire[9:0] x,
	input wire[9:0] y
);
	wire[7:0] out_0;
	ball b_0(x, y, out_0, v_sync);
	// wire[14:0] dist_sq_1;
	// wire overflow_1;
	// ball #(.START_X(10), .START_Y(50)) b_1(x, y, dist_sq_1, overflow_1, v_sync);

	reg pix = 0;
	always @(posedge x[0]) begin
		//pix <= (!overflow_0 && dist_sq_0 < 625); // || (!overflow_1 && dist_sq_1 < 625);
		pix <= (out_0 > 10);
	end

	assign rgb = display && pix;

endmodule
