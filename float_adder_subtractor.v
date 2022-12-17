module float_adder_subtractor(
	port_signA,
	port_expA,
	port_mantA,
	port_signB,
	port_expB,
	port_mantB,
	clk,
	op,
	load,
	port_signOut,
	port_expOut,
	port_mantOut,
	valid
);
input port_signA;
input [7:0] port_expA;
input [22:0] port_mantA;
input port_signB;
input [7:0] port_expB;
input [22:0] port_mantB;
input clk;
input op;
input load;
output port_signOut;
output [7:0] port_expOut;
output [22:0] port_mantOut;
output valid;

reg signA;
reg [7:0] expA;
reg [23:0] mantA;
reg signB;
reg [7:0] expB;
reg [23:0] mantB;
reg signOut;
reg [7:0] expOut;
reg [24:0] mantOut;
reg Aisbig;
reg diffSign;
reg shiftPhase;
reg validOutput;
//Zero Handling

always @(posedge clk) begin
	
	
	//Input Fetch Cycle
	if (load==1'b1) begin
		signA <= port_signA;
		expA <= port_expA;
		//mantA <= (signA==1'b1)?(-{1'b1,port_mantA}):{1'b1,port_mantA};
		mantA <= {1'b1,port_mantA};
		signB <= port_signB ^ op;
		expB <= port_expB;
		//mantB <= (signB==1'b1)?(-{1'b1,port_mantB}):{1'b1,port_mantB};
		mantB <= {1'b1,port_mantB};
		if (expA>expB)
			Aisbig <= 1'b1;
		else if (expB>expA)
			Aisbig <= 1'b0;
		else
			if(mantA>mantB)
				Aisbig <= 1'b1;
			else
				Aisbig <= 1'b0;
		//Aisbig <= (expA>expB)? 1'b1 : ((expA<expB) ? 1'b0 : ((mantA>mantB) 1'b1 ? : 1'b0));
		diffSign <= signA ^ signB;
		shiftPhase <= 1'b0;
		validOutput <= 1'b0;
	end
	
	
	
	// Shifting For Subtraction Only
	else if (shiftPhase==1'b1) begin
		if (validOutput <= 1'b0)
			if(mantOut[23:20]==4'b0000) begin
				mantOut[23:0] <= {mantOut[19:0],4'b0000};
				expOut <= expOut - 3'h4;
			end
			else if (mantOut[23]==1'b0) begin
				mantOut[23:0] <= {mantOut[22:0],1'b0};
				expOut <= expOut - 1'b1;
			end
			else
				validOutput <= 1'b1;
	end
	
	
	//Exponent Synchronization Shifting
	else begin
	
		//Check Who Is Bigger To Set Sign Bit And Shift The Smaller Number
		if (Aisbig==1'b1) begin
			//Big Shift
			if (expA-expB<4) begin
				mantB <= {1'b0,mantB[23:1]};
				expB <= expB + 1'b1;
			end
			//Small Shift
			else begin
				mantB <= {4'b0000,mantB[23:4]};
				expB <= expB + 3'h4;
			end
			//Synchronization Finished
			if (expA==expB) begin
				if(diffSign==1'b1)
					mantOut <= mantA - mantB;
				else begin
					mantOut <= mantA + mantB;
					validOutput <= 1'b1;
				end
				signOut <= signA;
				expOut <= expA;
				shiftPhase <= 1'b1;
			end
		end
		else begin
			//Big Shift
			if (expB-expA<4) begin
				mantA <= {1'b0,mantA[23:1]};
				expA <= expA + 1'b1;
			end
			//Small Shift
			else begin
				mantA <= {4'b0000,mantA[23:4]};
				expA <= expA + 3'h4;
			end
			//Synchronization Finished
			if (expA==expB) begin
				if(diffSign==1'b1)
					mantOut <= mantB - mantA;
				else begin
					mantOut <= mantB + mantA;
					validOutput <= 1'b1;
				end
				signOut <= signB;
				expOut <= expB;
				shiftPhase <= 1'b1;
			end
		end
	end
end


assign port_signOut = signOut;
assign port_expOut = (mantOut[24]==1'b1)?expOut+1'b1:expOut;
assign port_mantOut = (mantOut[24]==1'b1)?mantOut[23:1]:mantOut[22:0];
assign valid = validOutput;

endmodule