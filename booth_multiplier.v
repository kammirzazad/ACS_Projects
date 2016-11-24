// 1st Project of Advanced Computer Architecture
// Author : Kamyar Mirzazad
// ID : 89101089
// Created On : 26/9/2013

module multiplier ( input  wire clk, start, is_signed,
                    input  wire [31:0] a, b, 
                    output wire [63:0] s
                   );

reg  is_signed_reg;
reg  [31:0] a_reg;

reg  enable;					
reg  [ 4:0] count ;
reg  [66:0] accumulator ; //(32 + 34) + 1 = 67

wire IsZero, IsDouble, IsNegative ;
wire [33:0] a_0, a_1, a_2 ; // 2(sign extend) + 32
wire [33:0] Sum ;
 
always@(posedge clk)
   if( start )
	 begin
	  a_reg         <=  a;
	  enable        <=  1;
	  is_signed_reg <= is_signed;
	  if( is_signed )
	   count <= 15; // repeat step-by-step addition for 16 clock cycles 
	  else
	   count <= 16; // repeat step-by-step addition for 17 clock cycles 
	 end 
	else if ( count != 5'b0 )
	 begin
	  count  <= (count  - 1); // decrement counter
	  enable <= (count != 0); 
	 end
	else
	  enable <= 0;
	 
always@(posedge clk)
   if( start )       // Initialize acc.
    accumulator <= { 32'b0, 2'b0,  b, 1'b0};
   else if ( enable )//continue only if enabled ( Tcycle != 0 )
    accumulator <= { Sum[33:0], accumulator[34:2]}; // discard two right most bit's of accumulator	
 
 // first shift a one unit to left
 assign a_0[33:0] = (IsDouble)? {{(is_signed_reg)? a_reg[31] : 1'b0}, a_reg[31:0], 1'b0} : { {2{(is_signed_reg)? a_reg[31] : 1'b0}}, a_reg[31:0]};
 // second complement if necessary
 assign a_1[33:0] = a_0 ^ {34{IsNegative}};
 // third check whether it should be zero
 assign a_2[33:0] = a_1 & {34{~IsZero   }};
 // assign correct part of acc. as result  
 assign   s[63:0] = is_signed_reg? accumulator[66:3] : accumulator[64:1] ;
 
 FullAdder    module0( a_2[33:0], { {2{accumulator[66]} }, accumulator[66:35]}, (IsNegative)&(~IsZero), Sum);
 BoothEncoder module1( accumulator[2:0], IsZero, IsDouble, IsNegative);
endmodule 
//-----------------------------------------------------------------
module BoothEncoder( input wire [2:0] in, output wire IsZero, IsDouble, IsNegative);
  assign IsZero     = (in == 3'b000)|(in == 3'b111);
  assign IsDouble   = (in == 3'b011)|(in == 3'b100);  
  assign IsNegative =  in[2]; 
endmodule
//-----------------------------------------------------------------
module FullAdder   ( input wire [33:0] In1,In2, input wire Cin, output wire [33:0] Sum); // 34 bit full-adder						
  assign Sum[33:0] = In1[33:0] + In2[33:0] + { 33'b0 , Cin } ;						
endmodule

// Booth Table
// 0 - 0 - 0 :   x
// 0 - 0 - 1 :   A
// 0 - 1 - 0 :   A
// 0 - 1 - 1 :  2A
// 1 - 0 - 0 : -2A
// 1 - 0 - 1 : - A
// 1 - 1 - 0 : - A
// 1 - 1 - 1 :   x 