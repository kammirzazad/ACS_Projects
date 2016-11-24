module fp_adder ( input  wire [31:0] a ,
                  input  wire [31:0] b ,
                  output wire [31:0] s 
                );

wire        b_sticky;                   
//          we need sticky bit just for smaller operand
wire        a_sign  , b_sign, s_sign;
wire [ 7:0] a_exp   , b_exp , d_exp;
wire [ 7:0] s_exp_norm1, s_exp_norm2 ;
wire [22:0] a_mantis, b_mantis;
wire [27:0] oprnd_a, oprnd_norm1, oprnd_norm2, oprnd_round, oprnd_unsigned;
//          1(overflow) + [1(1/0.) + 23 ] + [1(R) + 1(G) + 1(S)]
wire [50:0] oprnd_tmp, oprnd_b;
//          1(overflow) + [1(1/0.) + 23 ] + [1(R) + 1(G) + 24(Reserved for shift)]                         
wire [ 4:0] shift_val;
//          maximum amount of shift is limited to 28
                                  
// 2#Order numbers ------------------------------------------------------------------------------------------
assign  {a_sign  , b_sign  } = (a[30:23] >= b[30:23])? {a[31]   , b[31]   } : {b[31]   , a[31]   }; 
assign  {a_exp   , b_exp   } = (a[30:23] >= b[30:23])? {a[30:23], b[30:23]} : {b[30:23], a[30:23]};
assign  {a_mantis, b_mantis} = (a[30:23] >= b[30:23])? {a[22: 0], b[22: 0]} : {b[22: 0], a[22: 0]};
//      so my a is always bigger than my b

// 1#Calculate amount of shift required----------------------------------------------------------------------
assign  d_exp     = (a_exp==1 && b_exp==0)? 8'b0 : a_exp - b_exp;

// 3#Shift smaller operand to right--------------------------------------------------------------------------
assign  oprnd_tmp = { 1'b0 , {(b_exp==0)? 1'b0 : 1'b1} , b_mantis , {26{1'b0}} } ;
//      get temporary second oprnd ( taking care of sign-extension & normalization )
assign  oprnd_b   = ( d_exp >= 50 )? 51'b0 : (oprnd_tmp)>> d_exp ;
//      shift temporary oprnd to right   
assign  b_sticky  = |oprnd_b[23:0];     
//      Reduction Or
assign  oprnd_a   = { 1'b0 , {(a_exp==0)? 1'b0 : 1'b1} , a_mantis , {3{1'b0}} };

// 5#Perform addition on sign-extended numbers & extract unsigned result mantis------------------------------ 
assign  oprnd_unsigned[27:0]  = (a_sign == b_sign ) ? oprnd_a + {oprnd_b[50:24],b_sticky} :
                                (a_exp!= b_exp || a_mantis >=  b_mantis) ? oprnd_a - {oprnd_b[50:24],b_sticky} :
                                {oprnd_b[50:24],b_sticky} - oprnd_a;

assign  s_sign    = (a_exp != b_exp || a_mantis >= b_mantis)? a_sign : b_sign;

// 6#First normalization-------------------------------------------------------------------------------------
//                  calculate shift amount  - very sophisticated hardware alert ;)
assign  shift_val   = (oprnd_unsigned[26])? 5'd0  : (oprnd_unsigned[25])? 5'd1  : (oprnd_unsigned[24])? 5'd2  : (oprnd_unsigned[23])? 5'd3  :
                      (oprnd_unsigned[22])? 5'd4  : (oprnd_unsigned[21])? 5'd5  : (oprnd_unsigned[20])? 5'd6  : (oprnd_unsigned[19])? 5'd7  :
                      (oprnd_unsigned[18])? 5'd8  : (oprnd_unsigned[17])? 5'd9  : (oprnd_unsigned[16])? 5'd10 : (oprnd_unsigned[15])? 5'd11 :
                      (oprnd_unsigned[14])? 5'd12 : (oprnd_unsigned[13])? 5'd13 : (oprnd_unsigned[12])? 5'd14 : (oprnd_unsigned[11])? 5'd15 :
                      (oprnd_unsigned[10])? 5'd16 : (oprnd_unsigned[ 9])? 5'd17 : (oprnd_unsigned[ 8])? 5'd18 : (oprnd_unsigned[ 7])? 5'd19 :
                      (oprnd_unsigned[ 6])? 5'd20 : (oprnd_unsigned[ 5])? 5'd21 : (oprnd_unsigned[ 4])? 5'd22 : (oprnd_unsigned[ 3])? 5'd23 :
                      (oprnd_unsigned[ 2])? 5'd24 : (oprnd_unsigned[ 1])? 5'd25 : (oprnd_unsigned[ 0])? 5'd26 : 5'd27 ;   // all of the bits are zero

assign  oprnd_norm1 = ( a_sign != b_sign )? (a_exp==0)? oprnd_unsigned : {((a_exp-1'b1) >= shift_val)? oprnd_unsigned<<shift_val : oprnd_unsigned<<(a_exp-1'b1) } :
                      (oprnd_unsigned[27])? {1'b0, oprnd_unsigned[27:1]} : oprnd_unsigned; 
//                    if signs are not equal, shift number left, otherwise shift right for normalization

assign  s_exp_norm1 = ( a_sign != b_sign )? {(oprnd_norm1    [26])? {a_exp-shift_val} : 8'b0 }: 
                                            {(oprnd_unsigned [27])? {a_exp+1'b1     } : a_exp};
//                    if signs are not equal, decrement exponent for normalization ( check for denormalized case )

// 7#Perform rounding-----------------------------------------------------------------------------------------
assign  oprnd_round =  (~oprnd_norm1[2]                  )? oprnd_norm1 :                            // R = 0
                       ( oprnd_norm1[1] || oprnd_norm1[0])? oprnd_norm1 + { {25{1'b0}} , 4'b1000 } : // R = 1 && ( G = 1 || S = 1 )
                         oprnd_norm1 + { {25{1'b0}} , oprnd_norm1[3], 3'b0 } ;                       // round to nearest even number

// 8#Second normalization-------------------------------------------------------------------------------------
assign oprnd_norm2  = (oprnd_round[27])? {1'b0, oprnd_round[27:1]} : oprnd_round;
assign s_exp_norm2  = (oprnd_round[27])? s_exp_norm1 + 1'b1        : s_exp_norm1;
//                    if rounding makes 2nd most significant bit one, we need to normalize number again

// 9#Convert to IEEE format-----------------------------------------------------------------------------------
assign s            = {s_sign, s_exp_norm2, oprnd_norm2[25:3]}; 
                   
endmodule
