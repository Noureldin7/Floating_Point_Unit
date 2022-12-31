module fp_divider_tb();
localparam PRECISION = 32;

	reg Clk = 1'b0;
	always begin
		#5 Clk = ~Clk;
	end

	// Main Test Scenario
	reg [1:0] StoredOperation = 2'b00;
	reg LoadDiv = 1'b0;
	shortreal a = 1.5;
	shortreal b = 1.5;
	initial begin
		#20 LoadDiv = 1'b1;
		StoredOperation = 2'b11;
		#10 LoadDiv = 1'b0;

		#500 a = 3.14;
		b = 0.02;
		LoadDiv = 1'b1;
		StoredOperation = 2'b11;
		#10 LoadDiv = 1'b0;

		#500 a = 0.02;
		b = 3.14;
		LoadDiv = 1'b1;
		StoredOperation = 2'b11;
		#10 LoadDiv = 1'b0;


		#500 $finish();
	end	

	// print each final result
	wire [PRECISION-1:0] DivResult;
	wire DivValid;
	always @(posedge DivValid) begin
		$display("Division done %f / %f = %f, %s", a, b, $bitstoshortreal(DivResult), DivResult == $shortrealtobits(a/b) ? "Valid" : "Not Valid");
		if (DivResult != $shortrealtobits(a/b))
			$display("Expected %b \nGot      %b", $shortrealtobits(a/b), DivResult);
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
		$display("At time %t, requested %f %s %f", $time, x1, DivToAddOp ? "-" : "+", x2);
		AddValid = 1'b0;
		if (DivToAddOp)
			x2 = -1 * x2;
		#25 AddValid = 1'b1;
		AddOut = $shortrealtobits(x1 + x2);
		$display("At time %t, request %f %s %f got response %f", $time, x1, DivToAddOp ? "-" : "+", x2, $bitstoshortreal(AddOut));
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
		if (|{DivToMulA, DivToMulB})
			$display("At time %t, requested %f x %f and got %f", $time, x1, x2, $bitstoshortreal(MulResult));
	end


	FP_Divider #(.PRECISION(PRECISION)) divider ($shortrealtobits(a), $shortrealtobits(b), LoadDiv, &StoredOperation, Clk, DivResult, DivValid, AddValid, AddOut, MulResult, DivToAddA, DivToAddB, DivToAddOp, DivToAddLoad, DivToMulA, DivToMulB);

endmodule