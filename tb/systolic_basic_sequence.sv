class systolic_basic_sequence extends uvm_sequence #(systolic_transaction);
  `uvm_object_utils(systolic_basic_sequence)
  function new(string name="systolic_basic_sequence");
    super.new(name);
  endfunction
  task body();
    systolic_transaction tr;
    for (int cycle = 0; cycle < 12; cycle++) begin
      tr = systolic_transaction::type_id::create("tr");
      start_item(tr);
      tr.load_weight = (cycle == 0);
      foreach (tr.weight_in[r,c]) tr.weight_in[r][c] = 8'sd2;
      foreach (tr.a_in[r]) begin
        tr.a_in[r] = (cycle >= r+1 && cycle < r+5) ? 8'sd3 : 0;
        tr.psum_in[r] = 0;
      end
      finish_item(tr);
    end
  endtask
endclass
