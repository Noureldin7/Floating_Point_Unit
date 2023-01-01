module fpu_tb();

	localparam PRECISION = 32;
	localparam PINF = (PRECISION==32) ? 32'b0_11111111_00000000000000000000000 : 64'b0_11111111111_0000000000000000000000000000000000000000000000000000;
	localparam NINF = (PRECISION==32) ? 32'b1_11111111_00000000000000000000000 : 64'b1_11111111111_0000000000000000000000000000000000000000000000000000;
	localparam NAN = (PRECISION==32) ? 32'b0_11111111_11111111111111111111111 : 64'b0_11111111111_1111111111111111111111111111111111111111111111111111;
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
		$display("Addition started at %0t, %e + %e", $time, a, b);
		#12 Reset = 1'b0;
		#988;
	endtask
	task Sub(shortreal input1, shortreal input2);
		a = input1;
		b = input2;
		#20 Reset = 1'b1;
		Operation = 2'b01;
		$display("Subtraction started at %0t, %e - %e", $time, a, b);
		#12 Reset = 1'b0;
		#988;
	endtask
	task Mul(shortreal input1, shortreal input2);
		a = input1;
		b = input2;
		#20 Reset = 1'b1;
		Operation = 2'b10;
		$display("Multiplication started at %0t, %e x %e", $time, a, b);
		#12 Reset = 1'b0;
		#988;
	endtask
	task Div(shortreal input1, shortreal input2);
		a = input1;
		b = input2;
		#20 Reset = 1'b1;
		Operation = 2'b11;
		$display("Division started at %0t, %e / %e", $time, a, b);
		#12 Reset = 1'b0;
		#2088;
	endtask

	initial begin
		#5;
		$finish();
		Mul(1.0,1.0);
		Mul(10.0,2.0);
		Mul(10.0,5.0);
		Mul(10,0.000123);
		Mul(1.7014118346e+38,2);
		Mul(-2,1.7014118346e+38);
		Mul(5.87747175411e-39,0.5);
		Mul(-0.5,5.87747175411e-39);
		Mul(1.5,1.5);
		Mul(8.50705917302e+37,4);
		Mul(8.50705917302e+37,2);
		Mul(0,1.7014118346e+38);
		Mul(5.87747175411e-39,0);
		Mul($bitstoshortreal(NAN),2);
		Mul(5.87747175411e-39,$bitstoshortreal(NAN));
		Mul(0,$bitstoshortreal(PINF));
		Mul($bitstoshortreal(NINF),0);
		Mul($bitstoshortreal(PINF),2);
		Mul(-0.3,$bitstoshortreal(PINF));
		Mul(0,1000);
		Mul(0.0005,0);
		Add(1,1);
		Add(1,-1);
		Add(2,2);
		Add(2,-2);
		Add(5,2);
		Add(5,-2);
		Add(2,5);
		Add(2,-5);
		Add(8388608,1);
		Add(5.87747175411E-39,0.5);
		Add(1.7014118346e+38,2);
		Add(1.7014118346e+38,10);
		Add(10,-9.999999);
		Add(1.7014118346e+38,2e+38);
		Add(10,-9.9999996);
		Add(0,$bitstoshortreal(NAN));
		Add($bitstoshortreal(PINF),$bitstoshortreal(NINF));
		Add($bitstoshortreal(NINF),$bitstoshortreal(PINF));
		Add($bitstoshortreal(PINF),5000);
		Add(0.0005,$bitstoshortreal(NINF));
		Add(0,341);
		Add(0.01234432,0);

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
	always @(posedge Done or negedge Reset) begin
		if (Done) begin
			case (Operation)
				2'b00: begin
					$display("Addition done at %0t, %e + %e = %e, %s", $time, a, b, $bitstoshortreal(Result), (Result == $shortrealtobits(a + b)) ? "Valid" : "Not Valid");
					if (Result != $shortrealtobits(a + b))
						$display("Expected %b \nGot      %b", $shortrealtobits(a + b), Result);
				end
				2'b01: begin
					$display("Subtraction done at %0t, %e - %e = %e, %s", $time, a, b, $bitstoshortreal(Result), (Result == $shortrealtobits(a - b)) ? "Valid" : "Not Valid");
					if ($bitstoshortreal(Result) != a - b)
						$display("Expected %b \nGot      %b", $shortrealtobits(a - b), Result);
				end
				2'b10: begin
					$display("Multiplication done at %0t, %e x %e = %e, %s", $time, a, b, $bitstoshortreal(Result), (Result == $shortrealtobits(a * b)) ? "Valid" : "Not Valid");
					if (Result != $shortrealtobits(a * b))
						$display("Expected %b \nGot      %b", $shortrealtobits(a * b), Result);
				end
				2'b11: begin
					$display("Division done at %0t, %e / %e = %e, %s", $time, a, b, $bitstoshortreal(Result), (Result == $shortrealtobits(a / b)) ? "Valid" : "Not Valid");
					if (Result != $shortrealtobits(a / b))
						$display("Expected %b \nGot      %b", $shortrealtobits(a/b), Result);
				end
			endcase
			$display("\n\n");
		end
	end

	FPU #(.PRECISION(PRECISION)) floatunit ($shortrealtobits(a), $shortrealtobits(b), Clk, Reset, Operation, Result, Done);


endmodule