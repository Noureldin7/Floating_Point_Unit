module fp_tb();
shortreal a = 1.5;
shortreal b = 1.5;
localparam No = 32;
//reg op = 1'b0;
wire [No-1:0] out;
initial begin
    //op = 1'b0;
    a = -0.01;
    b = 0.1;
    //op = 1'b1;
    a = 6.446;
    b = 4.542;
	 
    //op = 1'b1;
    a = $bitstoshortreal(32'hffffffff);
    b = 7.2;
end

always @(out)
begin 
$display("%f * %f = %f", a, b, $bitstoshortreal(out));
end

FP_Multiplier #(.N(No)) fp_mul_ins (.A($shortrealtobits(a)),.B($shortrealtobits(b)),.Result(out));
//float_adder_subtractor ins (.inA($shortshortrealtobits(a)),.inB($shortshortrealtobits(b)),.clk(clk),.op(op),.load(load),.out(out),.valid(valid));
endmodule