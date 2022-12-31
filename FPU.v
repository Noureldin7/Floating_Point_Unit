module FPU
	#(
		parameter PRECISION = 32
	) (
		input [PRECISION-1:0] A,
		input [PRECISION-1:0] B,
		input Clk,
		input Reset,
		input [1:0] Operation,
		output [PRECISION-1:0] Result,
		output Done
	);


	reg [PRECISION-1:0] StoredA;
	reg [PRECISION-1:0] StoredB;
	reg [1:0] StoredOperation;
	reg ExternalAddLoad;
	reg LoadDiv;


	wire [PRECISION-1:0] AddA = (~StoredOperation[1]) ? StoredA : DivToAddA;
	wire [PRECISION-1:0] AddB = (~StoredOperation[1]) ? StoredB : DivToAddB;
	wire AddOp = (~StoredOperation[1]) ? StoredOperation[0] : DivToAddOp;
	wire AddLoad = (~StoredOperation[1]) ? ExternalAddLoad : DivToAddLoad;
	wire [PRECISION-1:0] AddOut;
	wire AddValid;


	wire [PRECISION-1:0] MulA = (~StoredOperation[0]) ? StoredA : DivToMulA;
	wire [PRECISION-1:0] MulB = (~StoredOperation[0]) ? StoredB : DivToMulB;
	wire [PRECISION-1:0] MulResult;


	wire [PRECISION-1:0] DivToAddA;
	wire [PRECISION-1:0] DivToAddB;
	wire DivToAddOp;
	wire DivToAddLoad;
	wire [PRECISION-1:0] DivToMulA;
	wire [PRECISION-1:0] DivToMulB;
	wire [PRECISION-1:0] DivResult;
	wire DivValid;



	assign Result = (~StoredOperation[1]) ? AddOut :
					(~StoredOperation[0]) ? MulResult : DivResult;

	assign Done = (~StoredOperation[1]) ? AddValid :
					(~StoredOperation[0]) ? 1'b1 : DivValid;


	always @(negedge Clk) begin
		if (Reset) begin
			StoredA <= A;
			StoredB <= B;
			StoredOperation <= Operation;
			ExternalAddLoad <= ~Operation[1];
			LoadDiv <= &Operation;
		end
		else begin
			ExternalAddLoad <= 1'b0;
			LoadDiv <= 1'b0;
		end
	end


	float_adder_subtractor #(.PRECISION(PRECISION)) adder (.inA(AddA),.inB(AddB),.clk(Clk),.op(AddOp),.load(AddLoad),.out(AddOut),.valid(AddValid));

	FP_Multiplier #(.N(PRECISION)) multiplier (.Result(MulResult), .A(MulA), .B(MulB));

	FP_Divider #(.PRECISION(PRECISION)) divider (StoredA, StoredB, LoadDiv, &StoredOperation, Clk, DivResult, DivValid, AddValid, AddOut, MulResult, DivToAddA, DivToAddB, DivToAddOp, DivToAddLoad, DivToMulA, DivToMulB);

endmodule