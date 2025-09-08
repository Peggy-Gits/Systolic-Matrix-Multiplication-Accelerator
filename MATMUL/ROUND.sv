module round
#(parameter MANT_WIDTH=4,
  parameter EXP_WIDTH=3)
(input logic [EXP_WIDTH-1:0]NormExp,
 input logic [MANT_WIDTH-1:0] NormMant,
 input logic sign_result,
 input logic EOF,
 output logic [(MANT_WIDTH+EXP_WIDTH):0]result,
 output logic Round);
  logic [EXP_WIDTH:0] RoundExp;
  logic [MANT_WIDTH:0] RoundMant;
  logic RoundOF;
  always_comb begin
     RoundMant=EOF?NormMant:NormMant+1;
     RoundOF=RoundMant[MANT_WIDTH];
     RoundExp=NormExp+RoundOF;
     Round=~(EOF|&(RoundExp[EXP_WIDTH-1:0]));
     result={sign_result,RoundExp[EXP_WIDTH-1:0],RoundMant[MANT_WIDTH-1:0]};
  end
endmodule

