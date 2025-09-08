
`define REG_ADDRWIDTH 16
`define REG_DATAWIDTH 5
`define REG_START_ADDR 1
`define REG_DONE_ADDR 2
`define REG_FP 3
`define REG_ADDR_A 4
`define REG_ADDR_B 5
`define REG_ADDR_C 6
`define REG_STRIDE_A 7
`define REG_STRIDE_B 8
`define REG_STRIDE_C 9

module apb_slave 
#(parameter  REG_WIDTH=10,
  parameter  AWIDTH=10,
  parameter  ADDR_STRIDE_WIDTH=8)
(
    input logic                PCLK,done,
    input logic   	       exceptions,
    input logic                PRESETn,
    input logic[`REG_ADDRWIDTH-1:0] PADDR,
    input logic                PWRITE,
    input logic                PSEL,
    input logic                PENABLE,
    input logic[`REG_DATAWIDTH-1:0] PWDATA,
    output logic[`REG_DATAWIDTH-1:0] PRDATA,
    output logic               PREADY,
//interface with matmul
    output logic start, FP,
    output logic [AWIDTH-1:0] address_mat_a,
    output logic [AWIDTH-1:0] address_mat_b,
    output logic [AWIDTH-1:0] address_mat_c,
    output logic [ADDR_STRIDE_WIDTH-1:0] address_stride_a,
    output logic [ADDR_STRIDE_WIDTH-1:0] address_stride_b,
    output logic [ADDR_STRIDE_WIDTH-1:0] address_stride_c
);

//Recommend using ENUMs
typedef enum {
 IDLE,
 SETUP,
 RACCESS,
 WACCESS
}state_t;
state_t curr_state, next_state;
//States will be IDLE, SETUP, READ_ACCESS and WRITE_ACCESS
logic [`REG_ADDRWIDTH-1:0]status;
logic [`REG_ADDRWIDTH-1:0]mem[5:0];



always_ff @(posedge PCLK) begin
    if (PRESETn == 0) begin
      curr_state <= IDLE;      
    end
    else begin
      status[2]<=exceptions;
      status[1]<=done;
      if(next_state==WACCESS)begin
        case (PADDR)
          `REG_START_ADDR : status[0] <= PWDATA[0]; 
	  `REG_FP : status[3] <= PWDATA[0];
	  `REG_ADDR_A : mem[0]<=PWDATA;
	  `REG_ADDR_B : mem[1]<=PWDATA;
	  `REG_ADDR_C : mem[2]<=PWDATA;
	  `REG_STRIDE_A : mem[3]<=PWDATA;
	  `REG_STRIDE_B : mem[4]<=PWDATA;
          `REG_STRIDE_C : mem[5]<=PWDATA;
         endcase    
      end
      curr_state <= next_state;      
    end
end

always_comb begin
  PREADY=~(curr_state==IDLE);
  case(curr_state)
    IDLE: begin
      if(PSEL&~PENABLE) next_state = SETUP;
      else next_state = IDLE;
    end
    SETUP: begin
      if(PWRITE)next_state = WACCESS;
      else next_state = RACCESS;
    end
    RACCESS: begin
      if (PSEL & PENABLE) next_state = RACCESS;
      else if (PSEL & ~PENABLE) next_state = SETUP;
      else next_state = IDLE;
      PRDATA=status;
    end
    WACCESS: begin
      if (PSEL & PENABLE & PWRITE)next_state = WACCESS;
      else if(PSEL & ~PENABLE) next_state = SETUP;
      else next_state = IDLE;
    end
  endcase
  start = status[0];
  FP=status[3];
  address_mat_a = mem[0][AWIDTH-1:0];
  address_mat_b = mem[1][AWIDTH-1:0];
  address_mat_c = mem[2][AWIDTH-1:0];
  address_stride_a = mem[3][ADDR_STRIDE_WIDTH-1:0];
  address_stride_b = mem[4][ADDR_STRIDE_WIDTH-1:0];
  address_stride_c = mem[5][ADDR_STRIDE_WIDTH-1:0];
end
endmodule
