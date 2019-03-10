`ifndef __neutronpulsegenerator_include
`define __neutronpulsegenerator_include

module neutronpulsegenerator (
    input CLK,    // 15MHz clock
    input RESET,
    output reg PULSE
);

parameter [15:0] DELAY = 32;
parameter [15:0] WIDTH = 86;
parameter [15:0] WINDOW = 512;

parameter [15:0] NAFTERPULSES = 8;
parameter [15:0] AFTERWIDTH = 2;
parameter [15:0] PULSESPACING = 3;


reg [15:0] tickcount;
reg pulseval;
reg mainpulse;
reg afterpulse;
reg [15:0] aftercounter;

integer i;
// Pulse needs to count upto DELAY, then make a new pulse of WIDTH
always @(posedge CLK) begin

  if (RESET) begin
    tickcount = 15'b0;
    aftercounter = 0;
    PULSE = 0;
  end

  if (tickcount < WINDOW) tickcount <= tickcount + 1;
  else tickcount = 15'b0;

  PULSE = mainpulse || afterpulse;

  // Main Pulse Width
  if (tickcount > DELAY-1 & tickcount < DELAY+WIDTH) mainpulse = 1;
  else mainpulse = 0;

  // After pulsing
  if (tickcount > DELAY+WIDTH &
      tickcount < DELAY+WIDTH+NAFTERPULSES*AFTERWIDTH+NAFTERPULSES*PULSESPACING)
  begin

    aftercounter = aftercounter + 1;

    if (afterpulse & aftercounter >= PULSESPACING) begin
      afterpulse = !afterpulse;
      aftercounter = 0;
    end else if (!afterpulse & aftercounter >= AFTERWIDTH) begin
      afterpulse = !afterpulse;
      aftercounter = 0;
    end

  end else begin
    afterpulse = 0;
  end
end

endmodule
`endif
