module fp_tb();
shortreal a = 1.5;
shortreal b = 1.5;
reg clk = 1'b0;
reg load = 1'b0;
reg op = 1'b0;
wire [31:0] out;
wire valid;
initial begin
    #20 load = 1'b1;
    op = 1'b0;
    a = 1.5;
    b = 1.5;
    #40 load = 1'b0;
    
    #60 load = 1'b1;
    op = 1'b1;
    a = 12.4;
    b = 7.2;
    #80 load = 1'b0;
    
    #100 load = 1'b1;
    op = 1'b1;
    a = $bitstoshortreal(32'hffffffff);
    b = 7.2;
    #120 load = 1'b0;
end
always @(posedge valid) begin
    $display("%f %s %f = %f", a, (op==1'b0)?"+":"-", b, $bitstoshortreal(out));
end
always begin
    #5 clk = ~clk;
end
float_adder_subtractor ins (.inA($shortrealtobits(a)),.inB($shortrealtobits(b)),.clk(clk),.op(op),.load(load),.out(out),.valid(valid));
endmodule