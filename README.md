# Systolic-Matrix-Multiplication-Accelerator
This project is a systolic matrix multiplier with FP8 arithmetic units. This accelerator communicates with the CPU through APB control interface. In the UVM test, the CPU is replaced by the APB master agent, and memory slave agents are designed to imitate the memory buffers. 
[APB master Reference](https://github.com/asveske/apb_vip/tree/master)
