`ifndef __triggermask_include
`define __triggermask_include

// -----------------------------------
// TRIGGER MASK MODULE
// - Module to take in 16 trigger flags and return a trigger condition.
// -----------------------------------
module triggermask (
  input [15:0] triggers, // Single Channel Triggers
  output triggered      // Trigger result
);

  // Input Params from top
  parameter mintriggers = 1;

  // Local Variables
  // -----------------------------------
  integer fired;
  integer i;

  // Initial Evaluation
  // -----------------------------------
  always@(triggers)
  begin
    fired = 0;
    for (i=0; i<16;i=i+1)
      fired = fired + triggers[i];
  end

  // Trigger Condition
  // -----------------------------------
  // Return coincidence.
  assign triggered = (fired >= mintriggers);

endmodule
`endif
