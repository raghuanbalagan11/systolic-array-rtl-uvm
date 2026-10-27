class systolic_transaction extends uvm_sequence_item;
  rand bit signed [7:0] a_in[4];
  rand bit signed [7:0] weight_in[4][4];
  rand bit signed [31:0] psum_in[4];
  rand bit load_weight;
  `uvm_object_utils(systolic_transaction)
  function new(string name="systolic_transaction");
    super.new(name);
  endfunction
endclass
