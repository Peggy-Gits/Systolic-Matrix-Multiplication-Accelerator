`define REG_START_ADDR 1
`define REG_DONE_ADDR 2
`define REG_FP 3
`define REG_ADDR_A 4
`define REG_ADDR_B 5
`define REG_ADDR_C 6
`define REG_STRIDE_A 7
`define REG_STRIDE_B 8
`define REG_STRIDE_C 9

`ifndef _APB_MASTER_SEQ_
`define _APB_MASTER_SEQ_

class apb_master_seq extends uvm_sequence#(apb_master_seq_item);

	`uvm_object_utils(apb_master_seq)
	apb_master_seq_item m_apb_master_seq_item;
	bit done;
	//--------------------------------------------------------------------
	//	Methods
	//--------------------------------------------------------------------
	extern function new (string name = "apb_master_seq");
	extern task body();
endclass

// Function: new
// Definition: class constructor	
function apb_master_seq::new(string name ="apb_master_seq");
	super.new(name);
endfunction

// Function: body
// Definition: body method that gets executed once sequence is started 
function write(input [REG_ADDRWIDTH-1:0] address, input [REG_DATAWIDTH-1:0] data);
 begin
  m_apb_master_seq_item = apb_master_seq_item::type_id::create("m_apb_master_seq_item");
  start_item(m_apb_master_seq_item);
  m_apb_master_seq_item.randomize() with {
	apb_tr=WRITE;
        addr = address;
        data = data;
  };
  finish_item(m_apb_master_seq_item);
  $display("%t: PADDR %h, PWDATA %h", $time, addr, data);
 end  
endfunction

function read(input [REG_ADDRWIDTH-1:0] addr,output [REG_DATAWIDTH-1:0] data);
  m_apb_master_seq_item = apb_master_seq_item::type_id::create("m_apb_master_seq_item");
  start_item(m_apb_master_seq_item);
  m_apb_master_seq_item.randomize() with{
  	apb_tr=READ;
	addr=addr;
  };
  finish_item(m_apb_master_seq_item);
  $display("%t: PADDR %h, PRDATA %h",$time, addr,data);
endfunction


task apb_master_seq::body();
	logic [REG_DATAWIDTH-1:0]rdata;	
	repeat(1) begin		
	        write(`REG_ADDR_A, 0);		
  		write(`REG_ADDR_B, 0);
  		write(`REG_ADDR_C, 0);
  		write(`REG_STRIDE_A, 1);
  		write(`REG_STRIDE_B, 1);
  		write(`REG_STRIDE_C, 1);
        	write(`REG_FP, 0);
  		write(`REG_START_ADDR, 1); 
	end
	do begin
		read(`REG_DONE_ADDR);
		
		done=rdata[1];
	end
	while (done==1'b0);
endtask

`endif

