`ifndef __simplepulsegenerator_include
`define __simplepulsegenerator_include

module simplepulsegenerator (
    input CLK,    // 15MHz clock
    input RESET,
    output reg PULSE
);

parameter [15:0] DELAY = 32;
parameter [15:0] WIDTH = 86;
parameter [15:0] WINDOW = 512;

reg [15:0] tickcount;
reg pulseval;

// Pulse needs to count upto DELAY, then make a new pulse of WIDTH
always @(posedge CLK) begin

  if (RESET) begin
    tickcount = 15'b0;
    PULSE = 0;
  end

  // Count Upwards
  if (tickcount < WINDOW) begin
    tickcount <= tickcount + 1;
  end else begin
    tickcount = 15'b0;
  end

  if (tickcount > DELAY-1 & tickcount < DELAY + WIDTH)
  begin
    PULSE = 1;
  end
  else
  begin
    PULSE = 0;
  end

end

// assign PULSE = pulseval;


endmodule
`endif
