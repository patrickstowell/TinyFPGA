`include "top.v"

`timescale 1ns/1ns
module tb ();
  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, t);
  end

  reg clk;
  reg fastclk;
  wire led, usbpu;
  output reg PIN_13;
  wire pulse;

  initial begin
    clk = 1'b0;
    fastclk = 1'b0;
    PIN_13 = 0;
  end

  always begin
    #1 fastclk = !fastclk;
  end



  wire PULSEWIRE;
  reg PULSE;
  assign PULSEWIRE = PULSE;
  initial begin
    PULSE = 0;
    #500
    PULSE = 1;
    #520
    PULSE = 0;
    repeat(160000) @(posedge fastclk);
    $finish;
  end

  top t (.CLK(fastclk), .LED(led), .USBPU(usbpu), .PIN_2(PULSE));

endmodule // tb
