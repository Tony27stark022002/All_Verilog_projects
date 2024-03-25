//Design
module sram(
input clk, rst, wr_en,
  input [4:0] data_input, address,
  output reg [4:0] data_out

);

  reg [4:0] memory [32];

integer i;

  always @(posedge clk or posedge rst) begin

if(rst) begin

  for(i = 0; i <32; i++) begin

memory[i] = 0;

end

end

  else if(wr_en) begin

    memory[address] = data_input;
  #10;

end


  else begin

    data_out = memory[address];
    #10;

end

end

endmodule
/////////// testBench//////////////
`include "transaction.sv"
`include "interface.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "environment.sv"
module tb;

  environment env;
  counter_intf vif();
  mailbox gen2driv, mon2sco;

  sram dut (vif.clk, vif.rst, vif.wr_en, vif.data_input, vif.address, vif.data_out);

  always #5 vif.clk = ~vif.clk;

  initial begin
    vif.clk = 0;
    vif.rst = 1;
//      vif.wr_en=0;
    #3;
    vif.rst=0;
//     vif.wr_en=1;
//     #100 vif.wr_en=0;
//     #100 vif.wr_en=1;
//     #100 vif.wr_en=0;
  end

  initial begin
    gen2driv = new();
    mon2sco = new();

    env = new(gen2driv,mon2sco);
    env.vif = vif;
    env.run();
    #600;
    $finish();
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule
class transaction;
  rand bit [4:0] data_input;
  rand bit [4:0] address;
   rand bit wr_en;
  bit [4:0] data_out;
  
 constraint t1 {
   wr_en inside{0,1};
}

  
  
  function void display(string name);
    $display("%s display statements:",name); $display("address=%h,wr_en=%h,data_input=%h,data_output=%h",address,wr_en,data_input,data_out);
  endfunction
  
endclass

class generator;
  mailbox gen2driv;
  transaction t;
  covergroup cg_generator;
    coverpoint t.wr_en {
      bins b0 = {1'b1};
      bins b1 = {1'b0};
    }
  endgroup
  
  function new(mailbox gen2driv);
    this.gen2driv = gen2driv;
    cg_generator = new();
  endfunction

  task run();
    repeat(32) begin
      t = new();
      t.t1.constraint_mode(1);
      assert(t.randomize());
      cg_generator.sample(); 
      gen2driv.put(t);
      $display("Coverage Percentage: %.2f%%", cg_generator.get_inst_coverage());
    end
  endtask
endclass

interface counter_intf();
logic clk,rst, wr_en;
  logic [4:0] data_input, address;
  logic [4:0] data_out;
  
  clocking drv_cb@(posedge clk);
    output data_input;
    output address;
    input data_out;
  endclocking
  
  clocking mon_cb@(posedge clk);
    input data_input;
    input address;
    input data_out;
  endclocking
endinterface
class driver;
mailbox gen2driv;
transaction t;
virtual counter_intf vif;

  function new(mailbox gen2driv);
this.gen2driv = gen2driv;
endfunction

task run();
t = new();
forever begin
@(vif.drv_cb);
gen2driv.get(t);
vif.data_input = t.data_input;
  vif.wr_en=t.wr_en;
vif.address = t.address;
  $display("-----------------------------------------------");
  t.display("driver");
@(vif.drv_cb);
end
endtask
endclass

class monitor;
mailbox mon2sco;
virtual counter_intf vif;
transaction t;

  function new(mailbox mon2sco);
this.mon2sco = mon2sco;
endfunction

task run();
t = new();
forever begin
  @(vif.mon_cb);
  @(vif.mon_cb);
t.data_input = vif.data_input;
t.address = vif.address;
t.data_out = vif.data_out;
t.wr_en = vif.wr_en;
mon2sco.put(t);
t.display("monitor");
end
endtask
endclass

class scoreboard;
  mailbox mon2sco;
  transaction tarr[32];
  transaction t;

  function new(mailbox mon2sco);
    this.mon2sco = mon2sco;
  endfunction

  task run();
    repeat(32) begin
      mon2sco.get(t);

      if (t.wr_en == 1'b1) begin
        if (tarr[t.address] == null) begin
          tarr[t.address] = new();
          tarr[t.address].data_input = t.data_input;
          $display("[SCO] : Data stored");
          t.display("scoreboard");
          $display("-----------------------------------------------");
        end
      end else begin
        if (tarr[t.address] == null) begin
          if (t.data_out == 8'h00) begin
            $display("[SCO] : Data read Test Passed");
            t.display("scoreboard");
            $display("-----------------------------------------------");
          end else begin
            $display("[SCO] : Data read Test Failed");
            t.display("scoreboard");
            $display("-----------------------------------------------");
          end
        end else begin
          if (t.data_out == tarr[t.address].data_input) begin
            $display("[SCO] : Data read Test Passed");
            t.display("scoreboard");
            $display("-----------------------------------------------");
          end else begin
            $display("[SCO] : Data read Test Failed");
            t.display("scoreboard");
            $display("-----------------------------------------------");
          end
        end
      end
    end
  endtask
endclass

class environment;
generator gen;
driver drv;
monitor mon;
scoreboard sco;

virtual counter_intf vif;

mailbox gen2driv;
mailbox mon2sco;

function new(mailbox gen2driv, mailbox mon2sco);
this.gen2driv = gen2driv;
this.mon2sco = mon2sco;
    gen = new(gen2driv);
    drv = new(gen2driv);
    mon = new(mon2sco);
    sco = new(mon2sco);
endfunction

task run();
drv.vif = vif;
mon.vif = vif;

fork
gen.run();
drv.run();
mon.run();
sco.run();
join_any

endtask

endclass
