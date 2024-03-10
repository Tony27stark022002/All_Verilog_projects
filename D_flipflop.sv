// d flip flop verilog code
module d_flipflop(
  input wire d,
  input wire clk,
  input wire rst,
  output reg q,
  output reg qb
);
 
  always @(posedge clk or posedge rst) begin
    if (rst) begin    // set  the outputs equal to zero if reset if high
      q <= 0;
      qb <= 0;
    end
    else begin
      q <= d;
      qb <= ~d;
    end
  end

endmodule
//****************************************************************TEST BENCH*********************************************************************************//
// Simple linear test bench for the above design
module d_flipflop_tb;

  // TIMING Parameters
  parameter CLK_PERIOD = 10; // Clock period in time units
  parameter SIM_TIME = 100;  // Simulation time in time units

  // Signals
  reg clk, rst, d;
  wire q, qb;

  // Instantiate D flip-flop module
  d_flipflop DUT (
    .d(d),
    .clk(clk),
    .rst(rst),
    .q(q),
    .qb(qb)
  );

  // Clock generation
  always #((CLK_PERIOD/2)) clk = ~clk;

  // Stimulus generation
  initial begin
    clk = 0;
    rst = 1; // Reset active high initially
    d = 0;   // Input data
  
    #20; // Wait for a while
    
    // Release reset
    rst = 0;
    
    // Provide input data
    #10 d = 1;
    #10 d = 0;
    #10 d = 1;

    // Finish simulation
    #SIM_TIME $finish;
  end

  // Display outputs
  always @(posedge clk) begin
    $display("Time = %0t: d = %b, q = %b, qb = %b", $time, d, q, qb);
  end

endmodule
