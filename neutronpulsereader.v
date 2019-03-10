`ifndef __neutronpulsereader_include
`define __neutronpulsereader_include

module neutronpulsereader (
    input CLK,
    input PULSE,
    input [15:0] COUNT,
    input [2:0] GLOBAL_STATE,
    output HASDATA,
    output reg [15:0] STARTBIN,
    output reg [15:0] ENDBIN
);


localparam sSOFTRESET = 3'b000;
localparam sWAITING = 3'b001;
localparam sTRIGGERED = 3'b010;
localparam sFLAGGED = 3'b100;
localparam sREADOUT = 3'b101;
localparam sHOLDOFF = 3'b110;
localparam sCUSTOMSTATE = 3'b111;
localparam sLITSTATE = 3'b111;



reg [2:0] lstate;
reg ltrigger;

reg pulsehigh;
reg pulselow;
reg pulseedge;

// same thing for SSEL
reg [2:0] PULSEr;  always @(posedge CLK) PULSEr <= {PULSEr[1:0], PULSE};
wire PULSE_active = PULSEr[1];  // PULSE is active low
wire PULSE_endmessage = (PULSEr[2:1]==2'b10);  // message starts at falling edge
wire PULSE_startmessage = (PULSEr[2:1]==2'b01);  // message stops at rising edge


always @(posedge CLK)
begin

  if (GLOBAL_STATE == sSOFTRESET) begin
    lstate = sWAITING;
    ltrigger = 0;
    pulsehigh = 0;
  end
  else
  begin
      if (lstate == sWAITING & PULSE) begin
        lstate <= sTRIGGERED;
        ltrigger <= 1;
        STARTBIN <= COUNT;
      end else if (lstate == sTRIGGERED & !PULSE) begin
       lstate <= sFLAGGED;
       ENDBIN <= COUNT;
      end
  end
end

assign HASDATA = ltrigger;

endmodule
`endif
