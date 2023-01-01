module fp_divider_tb();
	localparam PRECISION = 32;
	localparam PINF = (PRECISION==32) ? 32'b0_11111111_00000000000000000000000 : 64'b0_11111111111_0000000000000000000000000000000000000000000000000000;
	localparam NINF = (PRECISION==32) ? 32'b1_11111111_00000000000000000000000 : 64'b1_11111111111_0000000000000000000000000000000000000000000000000000;
	localparam NAN = (PRECISION==32) ? 32'b0_11111111_11111111111111111111111 : 64'b0_11111111111_1111111111111111111111111111111111111111111111111111;

	reg Clk = 1'b0;
	always begin
		#5 Clk = ~Clk;
	end

	// Main Test Scenario
	reg [1:0] StoredOperation = 2'b00;
	reg LoadDiv = 1'b0;
	shortreal a = 1.5;
	shortreal b = 1.5;

	task Div(shortreal input1, shortreal input2);
		a = input1;
		b = input2;
		#20 LoadDiv = 1'b1;
		StoredOperation = 2'b11;
		$display("Division started at %0t, %e / %e", $time, a, b);
		#10 LoadDiv = 1'b0;
		#500;
	endtask

	initial begin
		$finish();
		Div(1,2);
		Div(4,4);
		Div(100,50);
		Div(100,0.00001);
		Div(0.0005,0.00005);
		Div(0.0005,0.0005);
		Div(0.0005,1e38);
		Div(100,1e-37);
		Div($bitstoshortreal(NAN),500);
		Div($bitstoshortreal(PINF),$bitstoshortreal(NAN));
		Div(0,0);
		Div($bitstoshortreal(PINF),$bitstoshortreal(PINF));
		Div($bitstoshortreal(PINF),5);
		Div(0,$bitstoshortreal(PINF));
		Div(5000,0);
		$finish();
	end	

	// print each final result
	wire [PRECISION-1:0] DivResult;
	wire DivValid;
	always @(posedge DivValid or negedge LoadDiv) begin
		if (DivValid) begin
			$display("Division done at %0t, %e / %e = %e, %s", $time, a, b, $bitstoshortreal(DivResult), (DivResult == $shortrealtobits(a/b)) ? "Valid" : "Not Valid");
			if (DivResult != $shortrealtobits(a/b))
				$display("Expected %b \nGot      %b", $shortrealtobits(a/b), DivResult);
		end
	end


	//emulate adder
	wire [PRECISION-1:0] DivToAddA;
	wire [PRECISION-1:0] DivToAddB;
	wire DivToAddOp;
	wire DivToAddLoad;
	reg [PRECISION-1:0] AddOut = 0;
	reg AddValid = 0;
	always @(posedge DivToAddLoad) begin
		shortreal x1;
		shortreal x2;
		x1 = $bitstoshortreal(DivToAddA);
		x2 = $bitstoshortreal(DivToAddB);
		// $display("At time %0t, requested %e %s %e", $time, x1, DivToAddOp ? "-" : "+", x2);
		AddValid = 1'b0;
		if (DivToAddOp)
			x2 = -1 * x2;
		#25 AddValid = 1'b1;
		AddOut = $shortrealtobits(x1 + x2);
		// $display("At time %0t, request %e %s %e got response %e", $time, x1, DivToAddOp ? "-" : "+", x2, $bitstoshortreal(AddOut));
	end

	//emulate multiplier
	wire [PRECISION-1:0] DivToMulA;
	wire [PRECISION-1:0] DivToMulB;
	reg [PRECISION-1:0] MulResult;
	always @(DivToMulA or DivToMulB)begin
		shortreal x1;
		shortreal x2;
		x1 = $bitstoshortreal(DivToMulA);
		x2 = $bitstoshortreal(DivToMulB);
		MulResult = $shortrealtobits(x1 * x2);
		// if (|{DivToMulA, DivToMulB})
			// $display("At time %0t, requested %e x %e and got %e", $time, x1, x2, $bitstoshortreal(MulResult));
	end


	FP_Divider #(.PRECISION(PRECISION)) divider ($shortrealtobits(a), $shortrealtobits(b), LoadDiv, &StoredOperation, Clk, DivResult, DivValid, AddValid, AddOut, MulResult, DivToAddA, DivToAddB, DivToAddOp, DivToAddLoad, DivToMulA, DivToMulB);

endmodule