`define REG_ADDRWIDTH 16
`define AWIDTH 10
`define ADDR_STRIDE_WIDTH 8
`define REG_DATAWIDTH 5
`define REG_START_ADDR 1
`define REG_DONE_ADDR 2
`define REG_EXCEPTION 3
`define REG_ADDR_A 4
`define REG_ADDR_B 5
`define REG_ADDR_C 6
`define REG_STRIDE_A 7
`define REG_STRIDE_B 8
`define REG_STRIDE_C 9


module APB_tb #(parameter HALF_CLK_CYCLE=5)();
 logic clk,reset,DONE,done;
 logic start, exceptions, PRESETn;
 logic[`REG_ADDRWIDTH-1:0] PADDR;
 logic PWRITE, PSEL, PENABLE, PREADY;
 logic[`REG_ADDRWIDTH-1:0] PWDATA,rdata;
 logic[`REG_ADDRWIDTH-1:0] PRDATA,wdata;
 logic[`REG_ADDRWIDTH-1:0] mem[6:0];
 logic [`AWIDTH-1:0] address_mat_a;
 logic [`AWIDTH-1:0] address_mat_b;
 logic [`AWIDTH-1:0] address_mat_c;
 logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_a;
 logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_b;
 logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_c;
 apb_slave #(.REG_WIDTH(`REG_ADDRWIDTH),.AWIDTH(`AWIDTH), .ADDR_STRIDE_WIDTH(`ADDR_STRIDE_WIDTH)) apb_bus(.PCLK(clk),.done(DONE),
    .exceptions(exceptions),.PRESETn(reset),.PADDR(PADDR),.PWRITE(PWRITE), .PSEL(PSEL), .PENABLE(PENABLE),
    .PWDATA(PWDATA), .PRDATA(PRDATA),.PREADY(PREADY),.start(start),.address_mat_a(address_mat_a),
    .address_mat_b(address_mat_b),.address_mat_c(address_mat_c),.address_stride_a(address_stride_a),
    .address_stride_b(address_stride_b),.address_stride_c(address_stride_c));

////////////////////////////////////////////
//Task to write into the configuration block of the DUT
////////////////////////////////////////////
task write(input [`REG_ADDRWIDTH-1:0] addr, input [`REG_DATAWIDTH-1:0] data);
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
task read(input [`REG_ADDRWIDTH-1:0] addr, output [`REG_DATAWIDTH-1:0] data);
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

initial begin
 clk='0;
 forever begin
  clk=~clk;
  #(HALF_CLK_CYCLE);
 end
end

initial begin
 mem[0]= 16'b0000000001;
 mem[1]= 16'b0000000100;
 mem[2]= 16'b0000001000;
 mem[3]= 16'b0000001100;
 mem[4]= 16'b0000000001;
 mem[5]= 16'b0000000001;
 mem[6]= 16'b0000000001;
end

////////////////////////////////////////////
// Main routine. Calls the appropriate tasks
////////////////////////////////////////////
initial begin
  //Reset 
  reset = 0;
  
  $display("Starting simulation");

  //Bring the design out of reset
  #(HALF_CLK_CYCLE*2);
  reset = 1;
  #(HALF_CLK_CYCLE*2);
  //start=1'b1; 
  DONE=1'b0;
  write(`REG_START_ADDR, mem[0]);
  write(`REG_ADDR_A, mem[1]);
  write(`REG_ADDR_B, mem[2]);
  write(`REG_ADDR_C, mem[3]);
  write(`REG_STRIDE_A, mem[4]);
  write(`REG_STRIDE_B, mem[5]);
  write(`REG_STRIDE_C, mem[6]);
  $display("Start the matmul");
  $display("Wait until done"); 
  #(HALF_CLK_CYCLE*10);
  DONE=1'b1;
  read(`REG_DONE_ADDR, rdata);
  done = rdata[1];
end

initial begin  
  /*do begin
      read(`REG_DONE_ADDR, rdata);
      done = rdata[1];
  end 
  while (done == 0);*/
  wait(done==1'b1);
  $display("Finishing simulation");
  //A little bit of drain time before we finish
  #(HALF_CLK_CYCLE*4);
  $finish;
end

endmodule
