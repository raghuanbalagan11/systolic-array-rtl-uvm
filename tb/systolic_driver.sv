class systolic_driver extends uvm_driver #(systolic_transaction);

  `uvm_component_utils(systolic_driver)

  virtual systolic_if vif;

  function new(string name="systolic_driver",
               uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual systolic_if)::get(
          this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    systolic_transaction tr;

    forever begin
      seq_item_port.get_next_item(tr);

      @(negedge vif.clk);

      vif.load_weight = tr.load_weight;

      foreach (vif.a_in[i]) begin
        vif.a_in[i] = tr.a_in[i];
        vif.psum_in[i] = tr.psum_in[i];
      end

      foreach (vif.weight_in[i,j])
        vif.weight_in[i][j] = tr.weight_in[i][j];

      `uvm_info("DRIVER",
        "Applied systolic transaction", UVM_MEDIUM)

      seq_item_port.item_done();
    end
  endtask

endclass
