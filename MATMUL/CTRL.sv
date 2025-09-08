module sum_align
#( parameter MANT_WIDTH =4, 
   parameter EXP_WIDTH =3)
(input logic [MANT_WIDTH-1:0]mantA,mantB,
 input logic [EXP_WIDTH-1:0]expA, expB,
 output logic [EXP_WIDTH-1:0]alignExp,
 output logic [MANT_WIDTH:0]alignMantA, alignMantB);
 logic [MANT_WIDTH:0]numA,numB;
 logic [EXP_WIDTH-1:0] shift;
 logic hiddenA, hiddenB;
 always_comb begin
   hiddenA=|(expA[EXP_WIDTH-1:0]);
   hiddenB=|(expB[EXP_WIDTH-1:0]);
   numA={hiddenA,mantA};
   numB={hiddenB,mantB};
   if(expA>expB)begin
      shift=expA-expB;
      alignMantB=(numB>>shift);
      alignMantA=numA;
      alignExp=expA;
   end
   else begin
      shift=expB-expA;
      alignMantA=(numA>>shift);
      alignMantB=numB;
      alignExp=expB;
   end
 end
endmodule

module mul_align
#(parameter MANT_WIDTH=4,
  parameter EXP_WIDTH=3)
(input logic [MANT_WIDTH-1:0]mantA, mantB, 
 input logic [EXP_WIDTH-1:0]expA, expB,
 output logic [MANT_WIDTH:0]alignMantA, alignMantB,
 output logic [EXP_WIDTH:0]alignExp,
 output logic small_num);
 localparam bias=(1<<(EXP_WIDTH-1))-1;
 logic hiddenA, hiddenB;
 logic [EXP_WIDTH+1:0]exp;
 always_comb begin
   hiddenA=|(expA);
   hiddenB=|(expB);
   alignMantA={hiddenA,mantA};
   alignMantB={hiddenB,mantB};
   exp=expA+expB-bias;
   small_num=(exp[EXP_WIDTH+1]);
   alignExp=exp;
 end
endmodule

module sum_normalize 
#(parameter EXP_WIDTH = 3,
  parameter MANT_WIDTH = 4)
( input logic [MANT_WIDTH+1:0] mant_result, 
  input logic [EXP_WIDTH-1:0]exp_result,
  output logic [MANT_WIDTH-1:0] NormMant, 
  output logic [EXP_WIDTH-1:0]NormExp,
  output logic EOF);
  logic sh1,sh2,sh3,sh4,sh5,sh6;
  logic zero;
  logic [EXP_WIDTH+1:0]exp_cnt;
  assign {sh1,sh2,sh3,sh4,sh5,sh6}=mant_result[MANT_WIDTH+1:0];  
  assign zero=~(|(mant_result[MANT_WIDTH]));
  always_comb begin
    NormMant=sh1?mant_result[MANT_WIDTH:1]:sh2?mant_result[MANT_WIDTH-1:0]:
    sh3?mant_result<<1:sh4?mant_result<<2:sh5?mant_result<<3:4'b0;
    exp_cnt=sh1?exp_result+1:sh2?exp_result:sh3?exp_result-1:sh4?exp_result-2:
    sh5?exp_result-3:sh6?exp_result-4:3'b000;
    EOF=1'b0;
    if((exp_cnt[EXP_WIDTH+1])==1'b1)begin
	NormExp=3'b0;
    end
    else begin
	if(exp_cnt>3'b110) begin 
	  NormExp=3'b111;
	  EOF=1'b1;
        end
	else begin
	  NormExp=exp_cnt;
          EOF=1'b0;
	end
    end
  end
endmodule

module mul_normalize
#(parameter EXP_WIDTH = 3,
  parameter MANT_WIDTH = 4)
(input logic [MANT_WIDTH*2+1:0] mant_result,
 input logic [EXP_WIDTH:0] exp_result,
 output logic [MANT_WIDTH-1:0] NormMant,
 output logic [EXP_WIDTH-1:0] NormExp,
 output logic EOF);
 logic [EXP_WIDTH:0]norm_exp;
 logic normalize_shift;
 assign normalize_shift=mant_result[MANT_WIDTH*2+1];
 always_comb begin
   NormMant=normalize_shift?mant_result[MANT_WIDTH*2:MANT_WIDTH+1]:mant_result[MANT_WIDTH*2-1:MANT_WIDTH];
   norm_exp=normalize_shift?exp_result+1:exp_result;
   NormExp=norm_exp[EXP_WIDTH-1:0];
   EOF=1'b0;
   if(norm_exp>4'b0110)begin
	EOF=1'b1;
   end
 end
endmodule


module exception 
#( parameter WIDTH=8,
   parameter EXP_WIDTH=3,
   parameter MANT_WIDTH=4)
(input logic [WIDTH-1:0]a,b,
output logic [5:0]flags);
logic ANaN,BNaN,AInf,BInf,Azero,Bzero;
 always_comb begin
   ANaN=&(a[WIDTH-2:WIDTH-MANT_WIDTH])&(|(a[MANT_WIDTH-1:0]));
   BNaN=&(b[WIDTH-2:WIDTH-MANT_WIDTH])&(|(b[MANT_WIDTH-1:0]));
   AInf=&(a[WIDTH-2:WIDTH-MANT_WIDTH])&~(|(a[MANT_WIDTH-1:0]));
   BInf=&(b[WIDTH-2:WIDTH-MANT_WIDTH])&~(|(b[MANT_WIDTH-1:0]));
   Azero=~(|(a[WIDTH-2:0]));
   Bzero=~(|(b[WIDTH-2:0]));
   flags={ANaN,BNaN,AInf,BInf,Azero,Bzero};
 end
endmodule

module sum_exception 
(input logic [5:0]flags,
 input logic sub,
 input logic EOF,
 output logic NAN, Inf);
 always_comb begin
   NAN=flags[5]|flags[4]|(sub&flags[3]&flags[2]);
   Inf=flags[3]|flags[2]|EOF;
 end 
endmodule

module mul_exception
(input logic [5:0]flags,
 input logic small_num,EOF,
 output logic NAN, Inf, zero);
 always_comb begin
   NAN=flags[5]|flags[4]|(flags[3]&flags[0])|(flags[2]&flags[1]);
   Inf=flags[3]|flags[2]|EOF;
   zero=flags[1]|flags[0]|small_num;
 end
endmodule

module mux2#(WIDTH=8)
(input logic [WIDTH-1:0]d1,d0,
 input logic s,
 output logic [WIDTH-1:0]y);
 assign y=s?d1:d0;
endmodule
