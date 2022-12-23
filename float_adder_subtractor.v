module float_adder_subtractor(
	inA,
	inB,
	clk,
	op,
	load,
	out,
	valid
);
parameter PRECISION = 32;

input [PRECISION-1:0] inA;
input [PRECISION-1:0] inB;
input clk;
input op;
input load;
output [PRECISION-1:0] out;
output valid;

localparam expSize = (PRECISION==32) ? 8 : 11;
localparam mantSize = (PRECISION==32) ? 23 : 52;

localparam expInf = (PRECISION==32) ? 8'hff : 11'hfff;
localparam mantInf = (PRECISION==32) ? 23'h0 : 52'h0;
localparam expNaN = (PRECISION==32) ? 8'hff : 11'hfff;
localparam mantNaN = (PRECISION==32) ? 23'hffffff : 52'hfffffffffffff;
localparam expZero = (PRECISION==32) ? 8'h0 : 11'h0;
localparam mantZero = (PRECISION==32) ? 23'h0 : 52'h0;
localparam neglectThreshold = (PRECISION==32) ? 5'd23 : 6'd52;


reg signA;
reg [expSize-1:0] expA;
reg [mantSize:0] mantA;
reg signB;
reg [expSize-1:0] expB;
reg [mantSize:0] mantB;
reg signOut;
reg [expSize-1:0] expOut;
reg [mantSize+1:0] mantOut;
reg Aisbig;
reg diffSign;
reg subShiftPhase;
reg addShiftPhase;
reg specialCase;
reg validOutput;
// Handle negligible operations

always @(posedge clk) begin
	
	//!Input Fetch Cycle
	if (load==1'b1) begin
		signA <= inA[PRECISION-1];
		expA <= inA[PRECISION-2:mantSize];
		mantA <= {1'b1,inA[mantSize-1:0]};
		signB <= inB[PRECISION-1] ^ op;
		expB <= inB[PRECISION-2:mantSize];
		mantB <= {1'b1,inB[mantSize-1:0]};
		if (expA>expB)
			Aisbig <= 1'b1;
		else if (expB>expA)
			Aisbig <= 1'b0;
		else
			if(mantA>mantB)
				Aisbig <= 1'b1;
			else
				Aisbig <= 1'b0;
		diffSign <= signA ^ signB;
		subShiftPhase <= 1'b0;
		addShiftPhase <= 1'b0;
		validOutput <= 1'b0;
		//! Filtering Special Numbers
		if((expA==expNaN && mantA[mantSize-1]==1'b1) || (expB==expNaN && mantB[mantSize-1]==1'b1)) begin
			signOut <= 1'b0;
			expOut <= expNaN;
			mantOut <= {2'h0,mantNaN};
			specialCase <= 1'b1;
		end
		else if(expA==expInf && mantA==mantInf) begin
			if(expB==expInf && mantB==mantInf && diffSign==1'b1) begin
				signOut <= 1'b0;
				expOut <= expNaN;
				mantOut <= {2'h0,mantNaN};
			end
			else begin
				signOut <= signA;
				expOut <= expInf;
				mantOut <= {2'h0,mantInf};
			end
			specialCase <= 1'b1;
		end
		else if(expB==expInf && mantB[mantSize-1]==1'b0) begin
			if(expA==expInf &&mantA==mantInf && diffSign==1'b1) begin
				signOut <= 1'b0;
				expOut <= expNaN;
				mantOut <= {2'h0,mantNaN};
			end
			else begin
				signOut <= signB;
				expOut <= expInf;
				mantOut <= {2'h0,mantInf};
			end
			specialCase <= 1'b1;
		end
		else if(expA == expZero && mantA == mantZero) begin
			signOut <= signB;
			expOut <= expB;
			mantOut <= {1'h0,mantB};
			specialCase <= 1'b1;
		end
		else if(expB == expZero && mantB == mantZero) begin
			signOut <= signA;
			expOut <= expA;
			mantOut <= { 1'h0 , mantA };
			specialCase <= 1'b1;
		end
		else if (Aisbig==1'b1 && expA-expB > neglectThreshold) begin
			signOut <= signA;
			expOut <= expA;
			mantOut <= {1'h0,mantA};
			specialCase <= 1'b1;
		end
		else if (Aisbig==1'b0 && expB-expA > neglectThreshold) begin
			signOut <= signB;
			expOut <= expB;
			mantOut <= {1'h0,mantB};
			specialCase <= 1'b1;
		end
		else
			specialCase <= 1'b0;
	end
	else if(specialCase==1'b1) begin
		validOutput <= 1'b1;
	end
	//! Shifting For Addition Only
	else if (addShiftPhase==1'b1) begin
		if (validOutput <= 1'b0) begin
			if(mantOut[mantSize+1]==1'b1) begin
				mantOut[mantSize-1:0] <= mantOut[mantSize:1];
				expOut <= expOut + 1'b1;
			end
			if(expOut==expInf)
				mantOut <= {2'h0,mantInf};
			validOutput <= 1'b1;
		end
	end
	
	//! Shifting For Subtraction Only
	else if (subShiftPhase==1'b1) begin
		if (validOutput <= 1'b0)
			if(mantOut[mantSize:mantSize-3]==4'b0000) begin
				mantOut[mantSize:0] <= {mantOut[mantSize-4:0],4'b0000};
				if(expOut<3'h4) begin
					mantOut <= {2'h0,mantZero};
					validOutput <= 1'b1;
				end
				else
					expOut <= expOut - 3'h4;
			end
			else if (mantOut[mantSize]==1'b0) begin
				mantOut[mantSize:0] <= {mantOut[mantSize-1:0],1'b0};
				if(expOut==expZero) begin
					mantOut <= {2'h0,mantZero};
					validOutput <= 1'b1;
				end
				else
					expOut <= expOut - 1'b1;
			end
			else
				validOutput <= 1'b1;
	end
	//!Exponent Synchronization Shifting
	else begin	
		//!Check Who Is Bigger To Set Sign Bit And Shift The Smaller Number
		if (Aisbig==1'b1) begin
			//!Big Shift
			if (expA-expB<4) begin
				mantB <= {1'b0,mantB[mantSize:1]};
				expB <= expB + 1'b1;
			end
			//!Small Shift
			else begin
				mantB <= {4'b0000,mantB[mantSize:4]};
				expB <= expB + 3'h4;
			end
			//!Synchronization Finished
			if (expA==expB) begin
				if(diffSign==1'b1) begin
					mantOut <= mantA - mantB;
					subShiftPhase <= 1'b1;
				end
				else begin
					mantOut <= mantA + mantB;
					addShiftPhase <= 1'b1;
				end
				signOut <= signA;
				expOut <= expA;
			end
		end
		else begin
			//!Big Shift
			if (expB-expA<4) begin
				mantA <= {1'b0,mantA[mantSize:1]};
				expA <= expA + 1'b1;
			end
			//!Small Shift
			else begin
				mantA <= {4'b0000,mantA[mantSize:4]};
				expA <= expA + 3'h4;
			end
			//!Synchronization Finished
			if (expA==expB) begin
				if(diffSign==1'b1) begin
					mantOut <= mantB - mantA;
					subShiftPhase <= 1'b1;
				end
				else begin
					mantOut <= mantB + mantA;
					addShiftPhase <= 1'b1;
				end
				signOut <= signB;
				expOut <= expB;
			end
		end
	end
end


assign out[PRECISION-1] = signOut;
assign out[PRECISION-2:mantSize] = expOut;
assign out[mantSize-1:0] = mantOut[mantSize-1:0];
assign valid = validOutput;

endmodule