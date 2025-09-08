module FP_TB 
#(parameter WIDTH=8,
  parameter EXP_WIDTH=3,
  parameter MANT_WIDTH=4,
  parameter HALF_CLK_CYCLE=5)
();
 int N=4;
 logic clk, reset, ctrl,Round;
 logic [WIDTH-1:0] a,b,y,y_sum;
 logic [WIDTH-1:0] num [2:0][1:0];
 logic [5:0]flags_mul, flags_add;
 logic [1:0]cnt;
 FP_MUL #(.WIDTH(WIDTH),.EXP_WIDTH(EXP_WIDTH), .MANT_WIDTH(MANT_WIDTH)) mul
(.a(a),.b(b),.RoundU(Round),.flags(flags_mul),.y(y));
 FP_ADD #(.WIDTH(WIDTH),.EXP_WIDTH(EXP_WIDTH), .MANT_WIDTH(MANT_WIDTH)) add
(.a(a),.b(b),.control(ctrl),.flags(flags_add),.y(y_sum),.RoundU(Round));
 initial begin
   clk=0;
   forever begin 
     clk=~clk; #(HALF_CLK_CYCLE);
   end
 end
 initial begin
   num[0][0]=8'b11101111;//-2^3*(1+15/16)
   num[0][1]=8'b01101111;//2^3*(1+15/16)
   num[1][0]=8'b00010010;//2*(1+2/16)
   num[1][1]=8'b00100010;//2^2*(1+2/16)
   num[2][0]=8'b10100101;//-2^2*(1+5/16)
   num[2][1]=8'b00000000;//-2^2*(1+4/16)
 end
 always_ff@(posedge clk) begin
   if(reset==1'b1)begin
     cnt<='0;
     ctrl<='0;
   end
   else begin
     if(cnt==2'b10)cnt<=2'b0;
     else cnt<=cnt+1;
     a<=num[cnt][0];
     b<=num[cnt][1];
     ctrl<=~ctrl;
   end
 end
 initial begin
        // Initialize reset
        reset = 1'b1;
        @(posedge clk);
        @(posedge clk);
        reset = 1'b0;
        Round=1'b1;
        for(int i = 1; i<=N; i=i+1) begin
            @(negedge clk);
   	    $display("a: %b, b: %b, y: %b", a, b, y);
        end
        $display("TEST COMPLETE");
        $finish;
  end
initial begin
	$fsdbDumpvars;
end
endmodule
