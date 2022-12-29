module fp_tb();
real a = 1.5;
real b = 1.5;
reg clk = 1'b0;
reg load = 1'b0;
localparam No = 32;
//reg op = 1'b0;
wire [No-1:0] out;
wire valid;
initial begin
    #20 load = 1'b1;
    //op = 1'b0;
    a = 1.37432432;
    b = 1.0;
    #40 load = 1'b0;
    
    #60 load = 1'b1;
    //op = 1'b1;
    a = 1.39040394;
    b = 0.5;
    #80 load = 1'b0;
    
    #100 load = 1'b1;
    //op = 1'b1;
    a = $bitstoreal(32'hffffffff);
    b = 7.2;
    #120 load = 1'b0;
end

always @(out)
begin 
$display("%f * %f = %f", a, b, $bitstoreal(out));
end

FP_Multiplier #(.N(No)) fp_mul_ins (.A($realtobits(a)),.B($realtobits(b)),.Result(out));
//float_adder_subtractor ins (.inA($shortrealtobits(a)),.inB($shortrealtobits(b)),.clk(clk),.op(op),.load(load),.out(out),.valid(valid));
endmodule