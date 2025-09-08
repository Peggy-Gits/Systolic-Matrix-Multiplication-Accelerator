`define REG_START_ADDR 1
`define REG_DONE_ADDR 2
`define REG_FP 3
`define REG_ADDR_A 4
`define REG_ADDR_B 5
`define REG_ADDR_C 6
`define REG_STRIDE_A 7
`define REG_STRIDE_B 8
`define REG_STRIDE_C 9
//`timescale 1ns/1ns
module matmul_tb 
#(parameter HALF_CLK_CYCLE = 5,
  parameter APB_REG_WIDTH =16,
  parameter ADDR_STRIDE_WIDTH = 8,
  parameter REG_DATAWIDTH = 5,
  parameter REG_ADDRWIDTH = 10,
  parameter AWIDTH =10)
();

    logic clk;
    logic resetn;
    logic pe_resetn;
    logic start_mat_mul;
    logic done_mat_mul, FP,done;
    logic start, exceptions, PRESETn;
    logic[APB_REG_WIDTH-1:0] PADDR;
    logic PWRITE, PSEL, PENABLE, PREADY;
    logic[APB_REG_WIDTH-1:0] PWDATA,rdata;
    logic[APB_REG_WIDTH-1:0] PRDATA,wdata;
    logic[APB_REG_WIDTH-1:0] mem[7:0];
    logic [AWIDTH-1:0] address_mat_a;
    logic [AWIDTH-1:0] address_mat_b;
    logic [AWIDTH-1:0] address_mat_c;
    logic [ADDR_STRIDE_WIDTH-1:0] address_stride_a;
    logic [ADDR_STRIDE_WIDTH-1:0] address_stride_b;
    logic [ADDR_STRIDE_WIDTH-1:0] address_stride_c;
    //DUT
    matrix_multiplication2 u_matmul(
        .clk(clk), 
        .resetn(resetn), 
        .pe_resetn(pe_resetn), 
        .address_mat_a(address_mat_a),
        .address_mat_b(address_mat_b),
        .address_mat_c(address_mat_c),
        .address_stride_a(address_stride_a),
        .address_stride_b(address_stride_b),
        .address_stride_c(address_stride_c),
        .start(start_mat_mul),
	.done(done_mat_mul),
  	.flag(exceptions),
	.FP(FP)
        );
    apb_slave #(.REG_WIDTH(APB_REG_WIDTH),.AWIDTH(AWIDTH), .ADDR_STRIDE_WIDTH(ADDR_STRIDE_WIDTH)) 
    apb_bus(.PCLK(clk),.done(done_mat_mul), .FP(FP), .exceptions(exceptions),.PRESETn(resetn),.PADDR(PADDR),.PWRITE(PWRITE), 
    .PSEL(PSEL), .PENABLE(PENABLE), .PWDATA(PWDATA), .PRDATA(PRDATA),.PREADY(PREADY),.start(start_mat_mul),
    .address_mat_a(address_mat_a), .address_mat_b(address_mat_b),.address_mat_c(address_mat_c),
    .address_stride_a(address_stride_a),.address_stride_b(address_stride_b),.address_stride_c(address_stride_c));
///////////////////////////////////////////
//Task to write into the configuration block of the DUT
////////////////////////////////////////////
task write(input [REG_ADDRWIDTH-1:0] addr, input [REG_DATAWIDTH-1:0] data);
 begin
  @(negedge clk);
  PSEL = 1;
  PENABLE = 0;
  PWRITE = 1;
  PADDR = addr;
  PWDATA = data;
	@(negedge clk);
  PENABLE = 1;
	@(negedge clk);
  PSEL = 0;
  PENABLE = 0;
  PWRITE = 0;
  PADDR = 0;
  PWDATA = 0;
  $display("%t: PADDR %h, PWDATA %h", $time, addr, data);
 end  
endtask


////////////////////////////////////////////
//Task to read from the configuration block of the DUT
////////////////////////////////////////////
task read(input [REG_ADDRWIDTH-1:0] addr, output [REG_DATAWIDTH-1:0] data);
begin 
  @(negedge clk);
  PSEL = 1;
  PENABLE = 0;
  PWRITE = 0;
  PADDR = addr;
  @(negedge clk);
  PENABLE = 1;
  @(negedge clk);
  PSEL = 0;
  PENABLE = 0;
  data = PRDATA;
  PADDR = 0;
	$display("%t: PADDR %h, PRDATA %h",$time, addr,data);
end
endtask
    //Write APB
    initial begin
     mem[0]= 1;
     mem[1]= 16'b0;
     mem[2]= 16'b0;
     mem[3]= 16'b0;
     mem[4]= 16'd1;
     mem[5]= 16'd1;
     mem[6]= 16'd1;
     mem[7]= 16'b0;
    end
    //Clock Generation  
    initial 
    begin
        clk = 0;
        forever 
        begin
            #(HALF_CLK_CYCLE) clk = ~clk;
        end
    end
    
    //Perform test    
    initial 
    begin  
         //Reset 
  	resetn = 0;
  	pe_resetn = 0;
  	$display("Starting simulation");

  	//Bring the design out of reset
  	#(HALF_CLK_CYCLE*2);
  	resetn = 1;
	pe_resetn = 1;
  	#(HALF_CLK_CYCLE*2);
  	write(`REG_ADDR_A, mem[1]);
  	write(`REG_ADDR_B, mem[2]);
  	write(`REG_ADDR_C, mem[3]);
  	write(`REG_STRIDE_A, mem[4]);
  	write(`REG_STRIDE_B, mem[5]);
  	write(`REG_STRIDE_C, mem[6]);
        write(`REG_FP, mem[7]);
  	write(`REG_START_ADDR, mem[0]);
  	$display("Start the matmul");
  	$display("Wait until done");
	do begin
	  read(`REG_DONE_ADDR, rdata);
  	  done = rdata[1];  
	end
	while (done==1'b0);
	wait(done==1'b1);
	#(HALF_CLK_CYCLE*10); 
        $finish;
    end
    

// Sample test case
//  A           B       Output   Output in hex
// 1 1 1 1   1 1 1 1   4 4 4 4    4 4 4 4
// 1 1 1 1   1 1 1 1   4 4 4 4    4 4 4 4
// 1 1 1 1   1 1 1 1   4 4 4 4    4 4 4 4
// 1 1 1 1   1 1 1 1   4 4 4 4    4 4 4 4

//    integer i;
//    
//    initial 
//    begin
//        for (i=0; i<4; i = i + 1) 
//        begin
//            u_matmul.matrix_A.ram[i] = {8'h01, 8'h01, 8'h01, 8'h01};
//            u_matmul.matrix_B.ram[i] = {8'h01, 8'h01, 8'h01, 8'h01};
//        end
//    end
    

//Actual test case
//  A           B        Output       Output in hex
// 8 4 6 8   1 1 3 0   98 90 82 34    62 5A 52 22
// 3 3 3 7   0 1 4 3   75 63 51 26    4B 3F 33 1A
// 5 2 1 6   3 5 3 1   62 48 44 19    3E 30 2C 13
// 9 1 0 5   9 6 3 2   54 40 46 13    36 28 2E 0D


initial begin
   //A is stored in ROW MAJOR format
   //A[0][0] (8'h08) should be the least significant byte of ram[0]
   //The first column of A should be read together. So, it needs to be 
   //placed in the first matrix_A ram location.
   //This is due to Verilog conventions declaring {MSB, ..., LSB}
        u_matmul.matrix_A.ram[3]  = {8'b00110100, 8'b00110100, 8'b00110100, 8'b00110100}; 
        u_matmul.matrix_A.ram[2]  = {8'b00110100, 8'b00110100, 8'b00110100, 8'b00110100};
        u_matmul.matrix_A.ram[1]  = {8'b00110100, 8'b00110100, 8'b00110100, 8'b00110100};
        u_matmul.matrix_A.ram[0]  = {8'b00110100, 8'b00110100, 8'b00110100, 8'b00110100};

  //B is stored in COL MAJOR format
   //B[0][0] (8'h01) should be the least significant of ram[0]
   //The first row of B should be read together. So, it needs to be 
   //placed in the first matrix_B ram location. 
        u_matmul.matrix_B.ram[3]  = {8'b00110000, 8'b00110000, 8'b00110000, 8'b00110000};
        u_matmul.matrix_B.ram[2]  = {8'b00110000, 8'b00110000, 8'b00110000, 8'b00110000};
        u_matmul.matrix_B.ram[1]  = {8'b00110000, 8'b00110000, 8'b00110000, 8'b00110000};
        u_matmul.matrix_B.ram[0]  = {8'b00110000, 8'b00110000, 8'b00110000, 8'b00110000};
end

initial begin
  #(HALF_CLK_CYCLE*200);
  $display("exit simulation");
  $finish;
end

initial begin
	$fsdbDumpvars;
end

endmodule
