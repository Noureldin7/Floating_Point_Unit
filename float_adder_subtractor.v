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
localparam mantInf = (PRECISION==32) ? {1'h1,23'h0} : {1'h1,52'h0};
localparam expNaN = (PRECISION==32) ? 8'hff : 11'hfff;
localparam mantNaN = (PRECISION==32) ? {1'h1,23'hffffff} : {1'h1,52'hfffffffffffff};
localparam expZero = (PRECISION==32) ? 8'h0 : 11'h0;
localparam mantZero = (PRECISION==32) ? {1'h1,23'h0} : {1'h1,52'h0};
localparam neglectThreshold = (PRECISION==32) ? 5'd23 : 6'd52;


wire wire_signA = inA[PRECISION-1];
wire [expSize-1:0] wire_expA = inA[PRECISION-2:mantSize];
wire [mantSize:0] wire_mantA = {1'b1,inA[mantSize-1:0]};
wire wire_signB = inB[PRECISION-1] ^ op;
wire [expSize-1:0] wire_expB = inB[PRECISION-2:mantSize];
wire [mantSize:0] wire_mantB = {1'b1,inB[mantSize-1:0]};


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
		if (wire_expA>wire_expB)
			Aisbig <= 1'b1;
		else if (wire_expB>wire_expA)
			Aisbig <= 1'b0;
		else
			if(wire_mantA>wire_mantB)
				Aisbig <= 1'b1;
			else
				Aisbig <= 1'b0;
		diffSign <= wire_signA ^ wire_signB;
		subShiftPhase <= 1'b0;
		addShiftPhase <= 1'b0;
		validOutput <= 1'b0;
		//! Filtering Special Numbers
		if((wire_expA==expNaN && wire_mantA[mantSize-1]==1'b1) || (wire_expB==expNaN && wire_mantB[mantSize-1]==1'b1)) begin
			signOut <= 1'b0;
			expOut <= expNaN;
			mantOut <= {2'h0,mantNaN};
			specialCase <= 1'b1;
		end
		else if(wire_expA==expInf && wire_mantA==mantInf) begin
			if(wire_expB==expInf && wire_mantB==mantInf && diffSign==1'b1) begin
				signOut <= 1'b0;
				expOut <= expNaN;
				mantOut <= {2'h0,mantNaN};
			end
			else begin
				signOut <= wire_signA;
				expOut <= expInf;
				mantOut <= {2'h0,mantInf};
			end
			specialCase <= 1'b1;
		end
		else if(wire_expB==expInf && wire_mantB[mantSize-1]==1'b0) begin
			if(wire_expA==expInf &&wire_mantA==mantInf && diffSign==1'b1) begin
				signOut <= 1'b0;
				expOut <= expNaN;
				mantOut <= {2'h0,mantNaN};
			end
			else begin
				signOut <= wire_signB;
				expOut <= expInf;
				mantOut <= {2'h0,mantInf};
			end
			specialCase <= 1'b1;
		end
		else if(wire_expA == expZero && wire_mantA == mantZero) begin
			signOut <= wire_signB;
			expOut <= wire_expB;
			mantOut <= {1'h0,wire_mantB};
			specialCase <= 1'b1;
		end
		else if(wire_expB == expZero && wire_mantB == mantZero) begin
			signOut <= wire_signA;
			expOut <= wire_expA;
			mantOut <= { 1'h0 , wire_mantA };
			specialCase <= 1'b1;
		end
		else if (Aisbig==1'b1 && wire_expA-wire_expB > neglectThreshold) begin
			signOut <= wire_signA;
			expOut <= wire_expA;
			mantOut <= {1'h0,wire_mantA};
			specialCase <= 1'b1;
		end
		else if (Aisbig==1'b0 && wire_expB-wire_expA > neglectThreshold) begin
			signOut <= wire_signB;
			expOut <= wire_expB;
			mantOut <= {1'h0,wire_mantB};
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
			//!Small Shift
			if (expA-expB<4) begin
				mantB <= {1'b0,mantB[mantSize:1]};
				expB <= expB + 1'b1;
			end
			//!Big Shift
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