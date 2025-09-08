module FP_ADD #(parameter WIDTH=8,parameter EXP_WIDTH=3,parameter MANT_WIDTH=4)
(input logic [WIDTH-1:0]a, b,
 input logic control, RoundU,
 output logic [5:0]flags,
 output logic [WIDTH-1:0]y);
 logic EOF,sub,nan,Inf,Round,round1;
 logic signA,signB,sign_result;
 logic [EXP_WIDTH-1:0]alignExp;
 logic [EXP_WIDTH-1:0]NormExp;
 logic [MANT_WIDTH-1:0]NormMant,RoundMant;
 logic [MANT_WIDTH:0]alignMantA,alignMantB;
 logic [MANT_WIDTH+1:0]Mant_result;
 logic [WIDTH-1:0]Round_result;
 logic [WIDTH-1:0]INF,NAN,Norm_result,exp_check1,exp_check2;
 assign Norm_result={sign_result,NormExp[EXP_WIDTH-1:0],NormMant};
 assign INF={sign_result,3'b111,4'b0};
 assign NAN={sign_result,3'b111,4'b0001};
 assign signA=a[WIDTH-1];
 assign signB=b[WIDTH-1];
 assign Round=round1&RoundU;
 exception #(.WIDTH(WIDTH),.MANT_WIDTH(MANT_WIDTH),.EXP_WIDTH(EXP_WIDTH))except(.a(a),.b(b),.flags(flags));

 sum_align #(.MANT_WIDTH(MANT_WIDTH),.EXP_WIDTH(EXP_WIDTH))align(.mantA(a[MANT_WIDTH-1:0]),.mantB(b[MANT_WIDTH-1:0]),
 .expA(a[WIDTH-2:WIDTH-4]), .expB(b[WIDTH-2:WIDTH-4]), .alignExp(alignExp), 
 .alignMantA(alignMantA), .alignMantB(alignMantB));

 ADD#(.MANT_WIDTH(MANT_WIDTH))compute(.a(alignMantA),.b(alignMantB),.signA(signA), .signB(signB),
 .control(control),.sub(sub),.sign_result(sign_result),.y(Mant_result));

 sum_normalize#(.MANT_WIDTH(MANT_WIDTH),.EXP_WIDTH(EXP_WIDTH))normalize(.mant_result(Mant_result), 
  .exp_result(alignExp), .NormMant(NormMant),.NormExp(NormExp),.EOF(EOF));

 round#(.MANT_WIDTH(MANT_WIDTH),.EXP_WIDTH(EXP_WIDTH))round(.NormExp(NormExp[EXP_WIDTH-1:0]),.NormMant(NormMant),
  .sign_result(sign_result),.result(Round_result), .EOF(EOF), .Round(round1));

 sum_exception exception_handling(.flags(flags),.sub(sub), .EOF(EOF),.NAN(nan), .Inf(Inf));

 mux2#(.WIDTH(WIDTH)) RoundMux(.d1(Round_result),.d0(Norm_result),.s(Round),.y(exp_check1));
 mux2#(.WIDTH(WIDTH)) InfMux(.d1(INF),.d0(exp_check1),.s(Inf),.y(exp_check2));
 mux2#(.WIDTH(WIDTH)) NANMux(.d1(NAN),.d0(exp_check2),.s(nan),.y(y));
endmodule

module FP_MUL #(parameter WIDTH=8,parameter EXP_WIDTH=3,parameter MANT_WIDTH=4)
(input logic [WIDTH-1:0]a,b,
 input logic RoundU,
 output logic [WIDTH-1:0]y,
 output logic [5:0]flags);
 logic Round,sub,nan,Inf,zero,EOF,small_num,round1;
 logic signA,signB,sign_result;
 logic [EXP_WIDTH:0]alignExp;
 logic [EXP_WIDTH-1:0]NormExp;
 logic [MANT_WIDTH-1:0]NormMant,RoundMant;
 logic [MANT_WIDTH:0]alignMantA,alignMantB;
 logic [MANT_WIDTH*2+1:0]Mant_result;
 logic [WIDTH-1:0]Round_result;
 logic [WIDTH-1:0]INF,ZERO,NAN,Norm_result,exp_check1,exp_check2,exp_check3;
 assign Round=RoundU&round1;
 assign Norm_result={sign_result,NormExp[EXP_WIDTH-1:0],NormMant};
 assign INF={sign_result,3'b111,4'b0};
 assign NAN={sign_result,3'b111,4'b0001};
 assign ZERO={sign_result,3'b0,4'b0};
 assign signA=a[WIDTH-1];
 assign signB=b[WIDTH-1];
 exception#(.WIDTH(WIDTH),.MANT_WIDTH(MANT_WIDTH),.EXP_WIDTH(EXP_WIDTH))except
 (.a(a),.b(b),.flags(flags));
 
 mul_align#(.MANT_WIDTH(MANT_WIDTH),.EXP_WIDTH(EXP_WIDTH)) align
 (.mantA(a[MANT_WIDTH-1:0]),.mantB(b[MANT_WIDTH-1:0]),
 .expA(a[WIDTH-2:WIDTH-4]), .expB(b[WIDTH-2:WIDTH-4]),.alignExp(alignExp), 
 .alignMantA(alignMantA), .alignMantB(alignMantB),.small_num(small_num));

 MUL#(.MANT_WIDTH(MANT_WIDTH),.EXP_WIDTH(EXP_WIDTH))compute
 (.a(alignMantA),.b(alignMantB),.signA(signA), .signB(signB),
 .sign_result(sign_result),.result(Mant_result));

 mul_normalize#(.MANT_WIDTH(MANT_WIDTH),.EXP_WIDTH(EXP_WIDTH))normalize
(.mant_result(Mant_result),.exp_result(alignExp),.NormMant(NormMant),
 .NormExp(NormExp),.EOF(EOF));

 round#(.MANT_WIDTH(MANT_WIDTH),.EXP_WIDTH(EXP_WIDTH))round
(.NormExp(NormExp),.NormMant(NormMant),
  .sign_result(sign_result),.result(Round_result), .EOF(EOF),.Round(round1));

 mul_exception exception_handling
(.flags(flags),.small_num(small_num),.EOF(EOF),.NAN(nan), .Inf(Inf), .zero(zero));

 mux2#(.WIDTH(WIDTH)) RoundMux(.d1(Round_result),.d0(Norm_result),.s(Round),.y(exp_check1));
 mux2#(.WIDTH(WIDTH)) InfMux(.d1(INF),.d0(exp_check1),.s(Inf),.y(exp_check2));
 mux2#(.WIDTH(WIDTH)) zeroMux(.d1(ZERO),.d0(exp_check2),.s(zero),.y(exp_check3));
 mux2#(.WIDTH(WIDTH)) NANMux(.d1(NAN),.d0(exp_check3),.s(nan),.y(y));
endmodule