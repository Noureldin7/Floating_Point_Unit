//shewyet notes mn el slides 
// fl 32 bit , 1 sign , 8 exp (30:23) , 23 mantissa (22:0)
// fl 64 bit , 1 sign , 11 exp ( 62:52) , 52 mantissa (51:0)
// expected size of non_normalized mantissa is 53*2 = 106 
// how to normalize the double precision !! 

module FP_Multiplier( 
Result, A, B); 
parameter N = 32; 
 input [N-1:0] A, B ; //the two floating inputs 
 output [N-1:0] Result ; // the floating product 
 
 wire [N-1:0] Result ;
 ////////////////////////////////////////////////////////////////////////////
 ////////////////////////////Parameters settings ////////////////////////////
localparam M = (N==32)?23:52;
localparam E = (N==32)?8:11;
 
 
 ////////////////////////////////////////////////////////////////////////////
 //					assembly values for output Result                        //
 
 reg sign ; // the output sign 
 
 reg [M-1:0] norm_mul ; // the output mantissa 
 
 reg [E:0] exp_out ; // the output exponent extended to (e+1)-bits for overflow 
 
 /////////////////////////////////////////////////////////////////////////////
 //      					        Special Numbers                             //
 
 
 localparam zero ={1'b0,{E{1'b0}},{M{1'b0}}};

 localparam NaN = {1'b1,{E{1'b1}},{M{1'b1}}};

 localparam p_inf = {1'b0,{E{1'b1}},{M{1'b0}}};

 localparam n_inf = {1'b1,{E{1'b1}},{M{1'b0}}};
 
 /////////////////////////////////////////////////////////////////////////////
 //										Divding Operands									//
 
 wire s1, s2; // the two input signs 
 
 wire [(M-1):0] m1, m2 ; // the two input mantissas 
 
 wire [E:0] e1, e2, sum_e1_e2 ; // extend exp to track overflow 
 
 wire [(2*M+1):0] non_norm_mul ; // raw multiplier output 47 = 2(M+1)-1 , 105 = 2(M+1)-1 , 2M+1
 ////////////////////////////////////////////////////////////////////////////////
 //										Assignmenet Stage										//
 
 assign s1 = A[N-1]; // sign 
 assign e1 = {1'b0, A[N-2:M]}; // exponent extended one bit 30:23 N-E-1 = M
 assign m1 = A[M-1:0] ; // mantissa // parse A N-E-2 = M-1
 
 assign s2 = B[N-1]; 
 assign e2 = {1'b0, B[N-2:M]}; //extended exponent to track overflow
 assign m2 = B[M-1:0] ; 
 
 
assign sum_e1_e2 = e1 + e2 ; // first step in mult is to add extended exponents 

// extend mantissa by 1 for each and multiply

assign non_norm_mul={1'b1,m1}*{1'b1,m2}; 

 // assemble output bits 
 
assign Result = {sign, exp_out[E-1:0], norm_mul} ; 
 
 always @(*)
 begin
 if (((A==zero)&&((B==p_inf)||(B==n_inf)))||((B==zero)&&((A==p_inf)||(A==n_inf))))
 begin
  sign = NaN[N-1];
 exp_out[E-1:0] = NaN[N-2:M];
 norm_mul[M-1:0] = NaN[M-1:0];
 end
 else if ((A==p_inf && B==p_inf) || (A==n_inf && B==n_inf))
 begin
 sign = 1'b0;
 exp_out[E-1:0] = {E{1'b1}};
 norm_mul[M-1:0] = {M{1'b0}};
 end
 else if (((A==p_inf) && (B==n_inf)) || ((A==n_inf) && (B==p_inf)))
 begin
 sign = 1'b1;
 exp_out[E-1:0] = {E{1'b1}};
 norm_mul[M-1:0] = {M{1'b0}};
 end
 else if((A==zero) || (B==zero))
 begin
 sign = 1'b0;
 exp_out[E-1:0] = {E{1'b0}};
 norm_mul[M-1:0] = {M{1'b0}};
 end
 else if((A==NaN) || (B==NaN))
 begin 
 sign = NaN[N-1];
 exp_out[E-1:0] = NaN[N-2:M];
 norm_mul[M-1:0] = NaN[M-1:0];
 end
 else if (sum_e1_e2[E]==1'b1)
 begin
 sign = s1 ^ s2;
 exp_out[E-1:0] = p_inf[N-2:M];
 norm_mul[M-1:0] = p_inf[M-1:0];
 end
 else
 //None of the special cases above ? then work normally 
 begin
 sign = s1 ^ s2 ; // output sign 
 if (non_norm_mul[(2*M)+1]==1) //Normalizaion with rounding \
 begin 
 exp_out = (N==32)?sum_e1_e2 - 9'd126:sum_e1_e2 - 11'd1022; 
 norm_mul = non_norm_mul[2*M:M+1]; 
 end 
else 
 begin 
 exp_out = (N==32)?sum_e1_e2 - 9'd127:sum_e1_e2 - 11'd1023; 
 norm_mul = non_norm_mul[(2*M)-1:M]; 
 end
 end 
 end
endmodule