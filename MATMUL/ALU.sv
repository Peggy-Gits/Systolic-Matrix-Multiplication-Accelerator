module ADD 
#(parameter MANT_WIDTH=4)
(input logic [MANT_WIDTH:0]a,b,
 input logic signA, signB,
 input logic control,
 output logic sub,sign_result,
 output logic [MANT_WIDTH+1:0] y);
 always_comb begin
  if (control)begin
	if(signA==signB)begin
	  y=a+b;
	  sign_result=signA;
	  sub='0;
	end
	else if(signA) begin
	  if(b>a) y=b-a;
	  else y=a-b;
	  sign_result=a>b;
 	  sub='1;
	end
	else begin
	  if(a>b)y=a-b;
	  else y=b-a;
	  sign_result=b>a;
	  sub='1;
	end
  end
  else begin 
	y=a-b;
	if (signA==signB)begin
	  if(signA==1'b1)begin 
	     if(b>a)y=b-a;
	     else y=a-b;
	     sign_result=a>b;
	     sub=1'b1;
	  end
	  else begin
	     if(a>b)y=a-b;
	     else y=b-a;
	     sign_result=b>a;
	     sub=1'b1;
	  end
	end
	else begin
	  y=a+b;
	  sign_result=signA;
	  sub=1'b0;
	end
       end
  end
endmodule

module MUL 
#(parameter MANT_WIDTH=4,
  parameter EXP_WIDTH=3)
(input logic [MANT_WIDTH:0] a,b,
 input logic signA, signB,
 output logic sign_result,
 output logic [MANT_WIDTH*2+1:0] result
);
 always_comb begin
   result=a*b;
   sign_result=signA^signB;  
 end
endmodule



module incr #(parameter WIDTH = 3)
(input logic [WIDTH-1:0] a,
 output logic [WIDTH-1:0] y
);
 assign y=a+1;
endmodule