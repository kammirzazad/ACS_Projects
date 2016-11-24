`timescale 1ns/1ns

module WallaceTree_tb;

  reg  [11:0] A;
  reg  [11:0] B;
  wire [23:0] S;

  WallaceTree m0 ( .A(A) , .B(B) , .M(S) );  

  always@( S )
   $display( "%x" , S );

  initial #10  A <= 12'h456;
  initial #10  B <= 12'h678;


  initial #100 A <= 12'hA12;
  initial #100 B <= 12'hB23;


  initial #200 A <= 12'hDAE;
  initial #200 B <= 12'h102;
  
  initial #300 $finish;

endmodule

