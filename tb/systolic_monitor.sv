class systolic_monitor extends uvm_monitor;

  `uvm_component_utils(systolic_monitor)

  virtual systolic_if vif;

  uvm_analysis_port #(systolic_transaction) input_ap;

  function new(string name="systolic_monitor",
               uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    input_ap = new("input_ap", this);

    if (!uvm_config_db#(virtual systolic_if)::get(
          this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    systolic_transaction tr;

    forever begin
      @(posedge vif.clk);

      tr = systolic_transaction::type_id::create("tr");

      tr.load_weight = vif.load_weight;

      foreach (tr.a_in[i]) begin
        tr.a_in[i] = vif.a_in[i];
        tr.psum_in[i] = vif.psum_in[i];
      end

      foreach (tr.weight_in[i,j])
        tr.weight_in[i][j] = vif.weight_in[i][j];

      input_ap.write(tr);
    end
  endtask

endclass
