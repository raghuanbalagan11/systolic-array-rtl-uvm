class systolic_test extends uvm_test;
  `uvm_component_utils(systolic_test)
  systolic_env env;
  virtual systolic_if vif;
  function new(string name="systolic_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = systolic_env::type_id::create("env", this);
    if (!uvm_config_db#(virtual systolic_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Test virtual interface not found")
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    repeat (5) @(negedge vif.clk);
    vif.rst_n = 1;
    `uvm_info("TEST", "Reset released successfully", UVM_LOW)
    begin
      systolic_basic_sequence seq;
      seq = systolic_basic_sequence::type_id::create("seq");
      seq.start(env.agent.sequencer);
      @(negedge vif.clk);
      vif.rst_n = 0;
      vif.load_weight = 0;
      #1ns;
      foreach (vif.psum_out[c]) begin
        if (vif.psum_out[c] !== 32'sd0)
          `uvm_error("ASYNC_RESET", $sformatf("Column %0d did not clear asynchronously: got %0d", c, vif.psum_out[c]))
      end
      `uvm_info("TEST", "Asynchronous reset output check completed", UVM_LOW)
      repeat (3) @(negedge vif.clk);
      vif.rst_n = 1;
      `uvm_info("TEST", "Mid-simulation reset released; starting recovery test", UVM_LOW)
      begin
        systolic_random_sequence random_seq;
        random_seq = systolic_random_sequence::type_id::create("random_seq");
        random_seq.start(env.agent.sequencer);
      end
      begin
        systolic_boundary_sequence boundary_seq;
        boundary_seq = systolic_boundary_sequence::type_id::create("boundary_seq");
        `uvm_info("TEST", "Starting 32-cycle arithmetic-boundary verification", UVM_LOW)
        boundary_seq.start(env.agent.sequencer);
        `uvm_info("TEST", "Arithmetic-boundary sequence completed", UVM_LOW)
      end
    end
    repeat (10) @(negedge vif.clk);
    phase.drop_objection(this);
  endtask
endclass
