module fpu_tb();

	localparam PRECISION = 32;

	reg Reset;
	reg [1:0] Operation;
	reg Clk = 1'b0;
	wire [PRECISION-1:0] Result;
	wire Done;

	always begin
		#5 Clk = ~Clk;
	end

	// Main Test Scenario
	shortreal a = 1.5;
	shortreal b = 1.5;

	task Add(shortreal input1, shortreal input2);
		a = input1;
		b = input2;
		#20 Reset = 1'b1;
		Operation = 2'b00;
		$display("Addition started at %0t, %f + %f", $time, a, b);
		#12 Reset = 1'b0;
		#488;
	endtask
	task Sub(shortreal input1, shortreal input2);
		a = input1;
		b = input2;
		#20 Reset = 1'b1;
		Operation = 2'b01;
		$display("Subtraction started at %0t, %f - %f", $time, a, b);
		#12 Reset = 1'b0;
		#488;
	endtask
	task Mul(shortreal input1, shortreal input2);
		a = input1;
		b = input2;
		#20 Reset = 1'b1;
		Operation = 2'b10;
		$display("Multiplication started at %0t, %f x %f", $time, a, b);
		#12 Reset = 1'b0;
		#488;
	endtask
	task Div(shortreal input1, shortreal input2);
		a = input1;
		b = input2;
		#20 Reset = 1'b1;
		Operation = 2'b11;
		$display("Division started at %0t, %f / %f", $time, a, b);
		#12 Reset = 1'b0;
		#488;
	endtask

	initial begin
		#5;
		$finish();
		Add(0.0, 1.0);
		Sub(0.0, 8.0);
		Mul(0.0, 1.0);
		Div(0.0, 1.0);
		$finish();
	end	

	// print each final result
	always @(posedge Done or negedge Reset) begin
		if (Done) begin
			case (Operation)
				2'b00: begin
					$display("Addition done at %0t, %f + %f = %f, %s", $time, a, b, $bitstoshortreal(Result), ($bitstoshortreal(Result) == a + b) ? "Valid" : "Not Valid");
					if ($bitstoshortreal(Result) != a + b)
						$display("Expected %b \nGot      %b", $shortrealtobits(a + b), Result);
				end
				2'b01: begin
					$display("Subtraction done at %0t, %f - %f = %f, %s", $time, a, b, $bitstoshortreal(Result), ($bitstoshortreal(Result) == a - b) ? "Valid" : "Not Valid");
					if ($bitstoshortreal(Result) != a - b)
						$display("Expected %b \nGot      %b", $shortrealtobits(a - b), Result);
				end
				2'b10: begin
					$display("Multiplication done at %0t, %f / %f = %f, %s", $time, a, b, $bitstoshortreal(Result), ($bitstoshortreal(Result) == a * b) ? "Valid" : "Not Valid");
					if ($bitstoshortreal(Result) != a * b)
						$display("Expected %b \nGot      %b", $shortrealtobits(a * b), Result);
				end
				2'b11: begin
					$display("Division done at %0t, %f / %f = %f, %s", $time, a, b, $bitstoshortreal(Result), ($bitstoshortreal(Result) == a/b) ? "Valid" : "Not Valid");
					if ($bitstoshortreal(Result) != a/b)
						$display("Expected %b \nGot      %b", $shortrealtobits(a/b), Result);
				end
			endcase
		end
	end

	FPU #(.PRECISION(PRECISION)) floatunit ($shortrealtobits(a), $shortrealtobits(b), Clk, Reset, Operation, Result, Done);


endmodule