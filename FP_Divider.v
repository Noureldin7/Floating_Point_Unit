module FP_Divider
	#(
		//Parameter for single or double precision
		parameter PRECISION = 32
	) (
		// External Inputs
		input [PRECISION-1:0] A,
		input [PRECISION-1:0] B,
		input Load,
		input Enable,
		input Clk,
		// External Outputs
		output reg [PRECISION-1:0] Result, //Will be used for intermediate values too
		output reg Valid, // 1 if calculations are done
		// Inputs from adder and mul
		input fromAddValid,
		input [PRECISION-1:0] fromAddOut,
		input [PRECISION-1:0] fromMulResult,
		// Outputs to control adder and mul
		output reg [PRECISION-1:0] toAddA,
		output reg [PRECISION-1:0] toAddB,
		output reg toAddOp,
		output reg toAddLoad,
		output reg [PRECISION-1:0] toMulA,
		output reg [PRECISION-1:0] toMulB
	);

	// Constants
	localparam S = PRECISION - 1;
	localparam E = (PRECISION == 32) ? 30 : 62;
	localparam M = (PRECISION == 32) ? 22 : 51;
	localparam ZERO = (PRECISION==32) ? 32'b0_00000000_00000000000000000000000 : 64'b0_00000000000_0000000000000000000000000000000000000000000000000000;
	localparam HALF = (PRECISION==32) ? 32'b0_01111110_00000000000000000000000 : 64'b0_01111111110_0000000000000000000000000000000000000000000000000000;
	localparam ONE = (PRECISION==32) ? 32'b0_01111111_00000000000000000000000 : 64'b0_01111111111_0000000000000000000000000000000000000000000000000000;
	localparam THIRTYTWO_OVER_SEVENTEEN = (PRECISION==32) ? 32'b0_01111111_11100001111000011110001 : 64'b0_01111111111_1110000111100001111000011110000111100001111000011110;
	localparam TWO = (PRECISION==32) ? 32'b0_10000000_00000000000000000000000 : 64'b0_10000000000_0000000000000000000000000000000000000000000000000000;
	localparam FORTYEIGHT_OVER_SEVENTEEN = (PRECISION==32) ? 32'b0_10000000_01101001011010010110101 : 64'b0_10000000000_0110100101101001011010010110100101101001011010010111;
	localparam PINF = (PRECISION==32) ? 32'b0_11111111_00000000000000000000000 : 64'b0_11111111111_0000000000000000000000000000000000000000000000000000;
	localparam NINF = (PRECISION==32) ? 32'b1_11111111_00000000000000000000000 : 64'b1_11111111111_0000000000000000000000000000000000000000000000000000;
	localparam NAN = (PRECISION==32) ? 32'b0_11111111_11111111111111111111111 : 64'b0_11111111111_1111111111111111111111111111111111111111111111111111;

	// Helping Registers
	reg [PRECISION-1:0] StoredA; // Stores N
	reg [PRECISION-1:0] StoredB; // Stores D
	reg [PRECISION-1:0] StoredX; // Stores Xi
	reg [E+1:M+1] ExponentDifference;
	reg [2:0] IterationCounter;
	// reg [2:0] IterationCounter_Next;
	reg [2:0] StepCounter;
	// reg [2:0] StepCounter_Next;

	// Conditions on A
	wire isInf_A = (&A[E:M+1]) & (~|A[M:0]);
	wire isZero_A = ~|A[E:0];
	wire isNaN_A = (&A[E:M+1]) & (|A[M:0]);

	// Conditions on B
	wire isInf_B = (&B[E:M+1]) & (~|B[M:0]);
	wire isZero_B = ~|B[E:0];
	wire isNaN_B = (&B[E:M+1]) & (|B[M:0]);

	wire [E+1:M+1] exponentDifferenceCalculation = A[E:M+1] - B[E:M+1] + {ONE[E-1:M+1], 1'b0}; //check it works?
	wire [E:M+1] resultExponent = ExponentDifference[E+1:M+1] - {ONE[E:M+1], 1'b0} + fromMulResult[E:M+1];

	always @(posedge Clk) begin
		if (Load & Enable) begin
			StoredA <= {A[S], HALF[E:M+1], A[M:0]};
			StoredB <= {B[S], HALF[E:M+1], B[M:0]};
			// Add bias twice to simplify comparisons
			// let E = Ea - Eb + 2 * bias,
			// 0 <= Ea, Eb <= 2*bias given valid Ea and Eb
			// i.e (0 <= E <= 4 * bias) (unsigned comparison)
			// for valid output b <= E <= 3b
			// recall to adjust later
			ExponentDifference <= exponentDifferenceCalculation;
			StoredX <= {PRECISION{1'b0}};
			toAddA <= {PRECISION{1'b0}};
			toAddB <= {PRECISION{1'b0}};
			toAddOp <= 1'b0;
			toAddLoad <= 1'b0;
			if (isNaN_A | isNaN_B | (isZero_A & isZero_B) | (isInf_A & isInf_B)) begin //NaN cases
				IterationCounter <= 3'b111;
				StepCounter <= 2'b11;
				Valid <= 1'b1;
				Result <= NAN;
				toMulA <= {PRECISION{1'b0}};
				toMulB <= {PRECISION{1'b0}};
			end
			else if (isZero_A | (exponentDifferenceCalculation < ONE[E+1:M+1])) begin //underflow
				IterationCounter <= 3'b111;
				StepCounter <= 2'b11;
				Valid <= 1'b1;
				Result <= ZERO;
				toMulA <= {PRECISION{1'b0}};
				toMulB <= {PRECISION{1'b0}};
			end
			else if (isInf_A | isZero_B | (exponentDifferenceCalculation > (3 * ONE[E-1:M+1]))) begin //Inf cases and overflow
				IterationCounter <= 3'b111;
				StepCounter <= 2'b11;
				Valid <= 1'b1;
				Result <= {A[S] ^ B[S],PINF[E:0]};
				toMulA <= {PRECISION{1'b0}};
				toMulB <= {PRECISION{1'b0}};
			end
			else begin
				IterationCounter <= 3'b000;
				StepCounter <= 2'b00;
				Valid <= 1'b0;
				//Perform 31/17 * B
				Result <= {PRECISION{1'b0}};
				toMulA <= THIRTYTWO_OVER_SEVENTEEN;
				toMulB <= {B[S], HALF[E:M+1], B[M:0]};
			end
		end
		else if (Enable) begin
			case (IterationCounter)
				3'b000: begin
					case (StepCounter)
						2'b00: begin
							StepCounter <= 2'b01;
							// Disable multiplier
							toMulA <= ZERO;
							toMulB <= ZERO;
							// Result <= fromMulResult;
							// Perform 48/17 - Product
							toAddA <= FORTYEIGHT_OVER_SEVENTEEN;
							toAddB <= fromMulResult;
							toAddOp <= 1'b1;
							toAddLoad <= 1'b1;
						end
						2'b01: begin //Adder
							toAddLoad <= 1'b0;
							if (fromAddValid) begin
								IterationCounter <= 3'b001;
								StepCounter <= 2'b00;
								// Disable Adder
								toAddA <= ZERO;
								toAddB <= ZERO;
								toAddOp <= 1'b0;
								// Store x0
								StoredX <= fromAddOut;
								// Perform x0D
								toMulA <= fromAddOut;
								toMulB <= StoredB;
							end
						end
						default: begin
							IterationCounter <= 3'b111;
							StepCounter <= 2'b11;
						end
					endcase
				end
				3'b111: begin
					case (StepCounter)
						2'b00: begin
							StepCounter <= 2'b01;
							// Discard output from multiplier
							// Perform N * x(n)
							toMulA <= StoredA;
							toMulB <= StoredX;
						end
						2'b01: begin // Renormalize
							StepCounter <= 2'b11;
							Result <= {fromMulResult[S], resultExponent, fromMulResult[M:0]};
							toMulA <= ZERO;
							toMulB <= ZERO;
							Valid <= 1'b1;
						end
						default: begin
							IterationCounter <= 3'b111;
							StepCounter <= 2'b11;
						end
					endcase
				end
				default: begin
					case (StepCounter)
						2'b00: begin
							StepCounter <= 2'b01;
							// Disable multiplier
							toMulA <= ZERO;
							toMulB <= ZERO;
							// Perform 2 - x(n-1)D
							toAddA <= TWO;
							toAddB <= fromMulResult;
							toAddOp <= 1'b1;
							toAddLoad <= 1'b1;
						end
						2'b01: begin //Adder
							toAddLoad <= 1'b0;
							if (fromAddValid) begin
								StepCounter <= 2'b10;
								// Disable Adder
								toAddA <= ZERO;
								toAddB <= ZERO;
								toAddOp <= 1'b0;
								// Perform x(n-1) (2- x(n-1)D)
								toMulA <= fromAddOut;
								toMulB <= StoredX;
							end
						end
						3'b10: begin
							//Increment n
							if (StoredX != fromMulResult)
								IterationCounter <= IterationCounter + 3'b001;
							else
								IterationCounter <= 3'b111;
							StepCounter <= 2'b00;
							// Store x(n)
							StoredX <= fromMulResult;
							// Perform x(n)D
							toMulA <= fromMulResult;
							toMulB <= StoredB;
						end
						default: begin
							IterationCounter <= 3'b111;
							StepCounter <= 2'b11;
						end
					endcase
				end
			endcase
		end
	end

endmodule