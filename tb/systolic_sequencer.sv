class systolic_sequencer extends uvm_sequencer #(systolic_transaction);
  `uvm_component_utils(systolic_sequencer)
  function new(string name="systolic_sequencer", uvm_component parent=null);
    super.new(name, parent);
  endfunction
endclass
