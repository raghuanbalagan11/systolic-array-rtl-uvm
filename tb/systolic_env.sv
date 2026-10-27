class systolic_env extends uvm_env;

  `uvm_component_utils(systolic_env)

  systolic_agent agent;
  systolic_scoreboard scoreboard;
  systolic_coverage coverage;

  function new(string name="systolic_env",
               uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agent = systolic_agent::type_id::create(
      "agent", this
    );

    scoreboard = systolic_scoreboard::type_id::create(
      "scoreboard", this
    );
    coverage = systolic_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    agent.monitor.input_ap.connect(
      scoreboard.input_export
    );

    agent.monitor.input_ap.connect(coverage.analysis_export);

    `uvm_info("ENV",
      "Monitor connected to scoreboard", UVM_LOW)
  endfunction

endclass
