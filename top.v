`ifndef __top_include
`define __top_include
`include "SPI_bus.v"
`include "simplepulsegenerator.v"
`include "neutronpulsegenerator.v"
`include "simplepulsereader.v"
`include "neutronpulsereader.v"
`include "triggermask.v"


// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,
    output LED,
    input PIN_10,
    input PIN_11,
    input PIN_13,
    input PIN_2,
    input PIN_3,

    output PIN_12,
    output PIN_9,
    input PIN_8,
    output USBPU  // USB pull-up resistor
);


  // Need to change this to a simple and complex trigger.

  // Simple trigger is formed from raw pulses.
  // Waits until multiple chambers fire at once, and starts a counter.
  // Complex trigger then runs on each channel. If it gets to the end of the
  // readout window it then checks what each channel has done.
  // Simple trigger is simply an AND of any two channels.

  // -----------------------------
  // PARAMETER DEFINITIONS
  // -----------------------------
  parameter clock_period = 1.0/16E6;
  parameter s = 1.0/clock_period;
  parameter us = 0.000001/clock_period;
  parameter ms = 0.001/clock_period;
  parameter [15:0] cSTART = 16'b0000000000111000;
  parameter [15:0] cCUSTOMSTATE = 16'b0000000011111111;
  parameter [15:0] cRESET = 16'b0000000011111110;
  parameter [15:0] cHOLDOFF = 16'b0000000011111101;
  parameter [15:0] cOK    = 459;
  parameter [2:0] LIT_STATE = sTRIGGERED;


  localparam sSOFTRESET = 3'b000;
  localparam sWAITING = 3'b001;
  localparam sTRIGGERED = 3'b010;
  localparam sFLAGGED = 3'b100;
  localparam sREADOUT = 3'b101;
  localparam sHOLDOFF = 3'b110;
  localparam sPRIMED = 3'b111;
  localparam sLITSTATE = 3'b111;



  // -----------------------------
  // Simple Input/Output Circuits
  // -----------------------------
  // drive USB pull-up resistor to '0' to disable USB
  assign USBPU = 0;

  // LED FLAG CIRCUIT
  reg ledvalue;
  assign LED = ledvalue;

  // SPIOUT CIRCUIT
  reg SPIOUT;
  assign PIN_9 = SPIOUT;

  // POWER ON RESET and Reset BUTTON debounce
  reg [5:0] reset_cnt = 0;
  reg [2:0] PIN_8r;  always @(posedge CLK) PIN_8r <= {PIN_8r[1:0], PIN_8};
  wire RESET_BTN = PIN_8r[1];
  wire RESET_ON = &reset_cnt;
  wire RESET = !RESET_ON | RESET_BTN;
  always @(posedge CLK) begin
    reset_cnt <= reset_cnt + !RESET_ON;
  end


  // -----------------------------
  // SPI MODULE
  // -----------------------------
  assign SCK  = PIN_10;
  assign MOSI = PIN_11;
  assign MISO = PIN_12;
  assign SSEL = PIN_13;
  wire [1023:0] SPIBUSIN;
  wire [1023:0] SPIBUSOUT;
  SPI_bus spimodule(CLK, SCK, MOSI, MISO, SSEL, SPIBUSIN, SPIBUSOUT);

  // -----------------------------
  // BUS ADDRESS SETUP
  // -----------------------------
  wire [15:0] STATE_CHANGE = SPIBUSOUT[15:0];
  localparam buswidth = 16;

  // SPI BUS is a 128 byte (or 64 16uint or 1024 bit) memory stack.
  // First 32 are 16 STARTBIN and ENDBIN datasets.
  // Remaining are left free for extra user information.
  for (i = 0; i < 16; i=i+1)
  begin
    assign SPIBUSIN[buswidth*(2*i+1)-1 -: buswidth] = STARTBINDATA[i];
    assign SPIBUSIN[buswidth*(2*i+2)-1 -: buswidth] = ENDBINDATA[i];
  end
  assign SPIBUSIN[ 33 * buswidth-1 -: buswidth] = TRIGGERDATA;


  // -----------------------------
  // MAIN CLOCK STATE MACHINE
  // -----------------------------
  reg [2:0] present_state, next_state;
  reg [15:0] readout_cutoff;
  reg [15:0] primed_cutoff;
  reg [15:0] primed_count;
  reg [15:0] CURRENT_STATECHANGE;

  always @ (posedge CLK)
  begin

    // // Manual State changer
    // if (STATE_CHANGE != CURRENT_STATECHANGE) begin
    //   CURRENT_STATECHANGE = STATE_CHANGE;
    //   if (STATE_CHANGE == 1) next_state <= sREADOUT;
    //   // else if (STATE_CHANGE == 2) next_state <= sSOFTRESET;
    // end

    // Present State Machine
    if (RESET) present_state <= sSOFTRESET;
    else present_state <= next_state;

    // STATE MACHINE CASE
    case (present_state)

      // RESET
      sSOFTRESET:
      begin
          readout_cutoff = 10000;
          primed_cutoff  = 1000;
          primed_count = 0;
          next_state = sWAITING;
          SPIOUT <= 0;
          ledvalue = !ledvalue;
      end

      // WAITING
      sWAITING:
      if (PRIMED)
      begin
      next_state <= sPRIMED;
      primed_count <= primed_count + 1;
      end

      // PRIMED
      sPRIMED:
      begin
        primed_count <= primed_count + 1;
        if (TRIGGERED) begin next_state <= sTRIGGERED;
        end else if (primed_count > primed_cutoff) next_state <= sSOFTRESET;
      end

      // TRIGGERED
      sTRIGGERED:
      begin
        primed_count <= primed_count + 1;
        if (primed_count > readout_cutoff) next_state <= sFLAGGED;
      end

      // FLAGGED STATE WAIT FOR PC
      sFLAGGED:
      SPIOUT <= 1;

      // IDLE POST READOUT STATE WAIT FOR PC
      sREADOUT:
      SPIOUT <= 0;

      // DEFAULT
      default:
      next_state = sSOFTRESET;

      endcase
  end


  // -----------------------------
  // CHANNEL DATA VARIABLES
  // -----------------------------
  wire [15:0] INPUTSIGNAL;
  wire [15:0] STARTBINDATA [15:0];
  wire [15:0] ENDBINDATA [15:0];


  // -----------------------------
  // TRIGGER MASK
  // -----------------------------
  wire TRIGGERED;
  wire [15:0] TRIGGERDATA;
  triggermask #(1) trigger(TRIGGERDATA, TRIGGERED);  // Require 2

  wire PRIMED;
  wire [15:0] PRIMERDATA;
  triggermask #(1) primer(PRIMERDATA, PRIMED);

  // -----------------------------
  // PULSE READER MODULES
  // - Generate all 16 channels using a for loop.
  // -----------------------------
  genvar i;
  generate
      for (i=0; i<16; i=i+1) begin : channel_array_block
      simplepulsereader channel(
        .CLK(CLK),
        .PULSE(INPUTSIGNAL[i]),
        .COUNT(primed_count),
        .GLOBAL_STATE(present_state),
        .PRIMER( PRIMERDATA[i] ),
        .TRIGGER( TRIGGERDATA[i] ),
        .STARTBIN( STARTBINDATA[i] ),
        .WIDTH( ENDBINDATA[i] )
        );
  end
  endgenerate

  // -----------------------------
  // PULSE Generator MODULES
  // - Used to test sets of channels, comment out if running on pulses
  // -----------------------------
  generate
      for (i=0; i<16; i=i+1) begin : pulse_array_block
      neutronpulsegenerator #(500, 20, 5000, 10, i, 1) pulse(
        .CLK(CLK),
        .RESET(RESET),
        .PULSE(INPUTSIGNAL[i])
        );
  end
  endgenerate





endmodule
`endif
