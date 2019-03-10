`ifndef __SPI_bus_include
`define __SPI_bus_include

module SPI_bus(clk, SCK, MOSI, MISO, SSEL, inbusdata, outbusdata);


input clk;
input [1023:0] inbusdata;
output reg [1023:0] outbusdata;

reg [15:0] byte_data_received;
input SCK, SSEL, MOSI;
output MISO;

// output LED;

// sync SCK to the FPGA clock using a 3-bits shift register
reg [2:0] SCKr;  always @(posedge clk) SCKr <= {SCKr[1:0], SCK};
wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges

// same thing for SSEL
reg [2:0] SSELr;  always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
wire SSEL_active = ~SSELr[1];  // SSEL is active low
wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge

// and for MOSI
reg [1:0] MOSIr;  always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
wire MOSI_data = MOSIr[1];




// we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
reg [3:0] bitcnt;

reg byte_received;  // high when a byte has been received


always @(posedge clk)
begin
  if(~SSEL_active)
    bitcnt <= 4'b0000;
  else
  if(SCK_risingedge)
  begin
    bitcnt <= bitcnt + 4'b0001;
    // implement a shift-left register (since we receive the data MSB first)
    byte_data_received <= {byte_data_received[14:0], MOSI_data};
    bitindex <= {bitindex[14:0], MOSI_data};
  end
end

always @(posedge clk) byte_received <= SSEL_active && SCK_risingedge && (bitcnt==4'b1111);

reg [15:0] bitindex;
reg [15:0] sentdata;
reg [15:0] byte_data_sent;

reg [3:0] iomode;
reg [3:0] nextiomode;
reg [15:0] writeaddress;

always @(posedge clk) begin

    iomode <= nextiomode;

    if (byte_received) begin

    case (iomode)
    0: // IDLE
    begin
      if (bitindex == 699) begin
      nextiomode <= 1; // Read
      sentdata = 0;
      end
      else if (bitindex == 777) begin
      nextiomode <= 2; // Write Address
      sentdata = 11;
      end
      else sentdata = 10;
    end

    1:
    begin
      sentdata = inbusdata[ bitindex * 16 + 15 -: 16 ];
      nextiomode <= 0;
    end

    2:
    begin
      writeaddress = bitindex;
      sentdata <= writeaddress;
      nextiomode <= 3;
    end

    3:
    begin
      outbusdata[ writeaddress * 16 + 15 -: 16 ] = bitindex;
      sentdata = bitindex;
      nextiomode <= 0;
    end

    default:
    begin
      sentdata = inbusdata[ bitindex * 16 + 15 -: 16 ];
      nextiomode <= 0;
    end

    endcase
    end
end


assign MISO = byte_data_sent[15];

always @(posedge clk)
begin
  if(SSEL_active)
  begin

    // first byte sent in a message is the message count
    if(SSEL_startmessage)
    begin
      byte_data_sent <= sentdata;
    end
    else
    begin
      // after that, we send 0s
      if(SCK_fallingedge)
      begin
        if(bitcnt==4'b0000) byte_data_sent <= 16'h00;
        else byte_data_sent <= {byte_data_sent[14:0], 1'b0};
      end
    end
  end
end



endmodule
`endif
