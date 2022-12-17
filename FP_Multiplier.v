module FP_Multiplier( 
Result, A, B); 
 input [31:0] A, B ; //the two floating inputs 
 output [31:0] Result ; // the floating product 
 wire [31:0] Result ; 
 ////////////////////////////////////////////////////////////////////////////
 //					assembly values for output Result                        //
 
 reg sign ; // the output sign 
 
 reg [22:0] norm_mul ; // the output mantissa 
 
 reg [8:0] exp_out ; // the output exponent extended to 9-bits for overflow 
 
 /////////////////////////////////////////////////////////////////////////////
 //      					        Special Numbers                             //
 
 localparam zero = 32'b00000000000000000000000000000000;
 localparam NaN = 32'bX111111111XXXXXXXXXXXXXXXXXXXXXX;
 localparam p_inf = 32'b01111111100000000000000000000000;
 localparam n_inf = 32'b11111111100000000000000000000000;
 
 /////////////////////////////////////////////////////////////////////////////
 //										Divding Operands									//
 
 wire s1, s2; // the two input signs 
 
 wire [22:0] m1, m2 ; // the two input mantissas 
 
 wire [8:0] e1, e2, sum_e1_e2 ; // extend exp to track overflow 
 
 wire [47:0] non_norm_mul ; // raw multiplier output 
 
 ////////////////////////////////////////////////////////////////////////////////
 //										Assignmenet Stage										//
 
 assign s1 = A[31]; // sign 
 assign e1 = {1'b0, A[30:23]}; // exponent extended one bit 
 assign m1 = A[22:0] ; // mantissa // parse A 
 
 assign s2 = B[31]; 
 assign e2 = {1'b0, B[30:23]}; //extended exponent to track overflow
 assign m2 = B[22:0] ; 
 
 
assign sum_e1_e2 = e1 + e2 ; // first step in mult is to add extended exponents 

// extend mantissa by 1 for each and multiply

assign non_norm_mul={1'b1,m1}*{1'b1,m2}; 

 // assemble output bits 
 
assign Result = {sign, exp_out[7:0], norm_mul} ; 
 
 always @(*)
 begin
 if (((A==0)&&((B==p_inf)||(B==n_inf)))||((B==0)&&((A==p_inf)||(A==n_inf))))
 begin
  sign = 1'bX;
 exp_out[7:0] = 8'b11111111;
 norm_mul[22:0] = 23'b1XXXXXXXXXXXXXXXXXXXXXX;
 end
 else if ((A==p_inf && B==p_inf) || (A==n_inf && B==n_inf))
 begin
 sign = 1'b0;
 exp_out[7:0] = 8'b11111111;
 norm_mul[22:0] = 23'b00000000000000000000000;
 end
 else if (((A==p_inf) && (B==n_inf)) || ((A==n_inf) && (B==p_inf)))
 begin
 sign = 1'b1;
 exp_out[7:0] = 8'b11111111;
 norm_mul[22:0] = 23'b00000000000000000000000;
 end
 else if((A==0) || (B==0))
 begin
 sign = 1'b0;
 exp_out[7:0] = 8'b00000000;
 norm_mul[22:0] = 23'b00000000000000000000000;
 end
 else if (sum_e1_e2[8]==1'b1)
 begin
 sign = 1'bX;
 exp_out[7:0] = 8'b11111111;
 norm_mul[22:0] = 23'b1XXXXXXXXXXXXXXXXXXXXXX;
 end
 else
 //None of the special cases above ? then work normally 
 begin
 sign = s1 ^ s2 ; // output sign 
 if (non_norm_mul[47]==1) //Normalizaion with rounding \
 begin 
 exp_out = sum_e1_e2 - 9'd126; 
 norm_mul = non_norm_mul[46:24] ; 
 end 
else 
 begin 
 exp_out = sum_e1_e2 - 9'd127; 
 norm_mul = non_norm_mul[45:23] ; 
 end
 end 
 end
endmodule