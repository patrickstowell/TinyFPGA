`ifndef __simplepulsereader_include
`define __simplepulsereader_include

module simplepulsereader (
    input CLK,
    input PULSE,
    input [15:0] COUNT,
    input [2:0] GLOBAL_STATE,
    output PRIMER,
    output TRIGGER,
    output reg [15:0] STARTBIN,
    output reg [15:0] WIDTH
);

// Localparams
// --------------------------
localparam sSOFTRESET = 3'b000;
localparam sWAITING = 3'b001;
localparam sTRIGGERED = 3'b010;
localparam sFLAGGED = 3'b100;
localparam sREADOUT = 3'b101;
localparam sHOLDOFF = 3'b110;
localparam sCUSTOMSTATE = 3'b111;
localparam sPRIMED = 3'b111;

localparam sLITSTATE = 3'b111;

// Pulse Edge/Width Processing
// --------------------------
reg [2:0] PULSEr;
reg [15:0] PULSE_width;
wire PULSE_active = PULSEr[1];
wire PULSE_negedge = (PULSEr[2:1]==2'b10);
wire PULSE_posedge = (PULSEr[2:1]==2'b01);
always @(posedge CLK)
begin
  PULSEr <= {PULSEr[1:0], PULSE};
  if (PULSE_active) PULSE_width <= PULSE_width + 1;
  else PULSE_width <= 0;
end

// Extra Variables, merge these into outputs if needed.
// --------------------------
reg [15:0] AFTERPULSES;


// Local State and Trigger
// --------------------------
reg [2:0] lstate;
reg lprimer;    // Trigger is set high on first PULSE. Primes trigger ready to fire.
reg ltrigger;   // For this reader, trigger goes high when a large pulse width is read.

always @(posedge CLK)
begin

  // Reset Logic
  if (GLOBAL_STATE == sSOFTRESET) begin
    lstate = sSOFTRESET;
    ltrigger = 0;
  end
  else

  // Trigger Logic
  begin

    case(lstate)
    sSOFTRESET:
    begin
      lstate = sWAITING;
      ltrigger = 0;
      lprimer = 0;
      AFTERPULSES = 0;
    end

    sWAITING:
    begin
      if (PULSE_posedge) begin
        lstate <= sPRIMED;
        lprimer <= 1;
        STARTBIN <= COUNT;
      end
    end

    sPRIMED:
    begin
      if (PULSE_width > 5) begin // found long pulse
        lstate <= sTRIGGERED;
        ltrigger <= 1;
      end else if (!PULSE_active) begin // short noise pulse
        lstate <= sSOFTRESET;
      end
    end

    sTRIGGERED:
      if (PULSE_negedge) begin
        lstate <= sFLAGGED;
        WIDTH <= PULSE_width;
      end

    sFLAGGED:
    begin
      // Stay here until reset.
      if (PULSE_posedge) begin
        AFTERPULSES <= AFTERPULSES + 1;
      end
    end

    default:
      lstate <= sSOFTRESET;

    endcase
    end
end

assign PRIMER = lprimer;
assign TRIGGER = ltrigger;

endmodule
`endif
