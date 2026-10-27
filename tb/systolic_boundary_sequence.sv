class systolic_boundary_sequence extends uvm_sequence #(systolic_transaction);
  `uvm_object_utils(systolic_boundary_sequence)

  function new(string name="systolic_boundary_sequence");
    super.new(name);
  endfunction

  task body();
    systolic_transaction tr;

    for (int cycle = 0; cycle < 32; cycle++) begin
      tr = systolic_transaction::type_id::create("boundary_tr");
      start_item(tr);

      // Back-to-back loads, followed by steady-state execution.
      tr.load_weight = (cycle < 4 || cycle == 16 || cycle == 17);

      foreach (tr.weight_in[r,c]) begin
        case ((cycle + r + c) % 5)
          0: tr.weight_in[r][c] = -128;
          1: tr.weight_in[r][c] = 127;
          2: tr.weight_in[r][c] = -1;
          3: tr.weight_in[r][c] = 1;
          default: tr.weight_in[r][c] = 0;
        endcase
      end

      foreach (tr.a_in[r]) begin
        case ((cycle + r) % 5)
          0: tr.a_in[r] = -128;
          1: tr.a_in[r] = 127;
          2: tr.a_in[r] = -1;
          3: tr.a_in[r] = 1;
          default: tr.a_in[r] = 0;
        endcase
      end

      // Exercise both signed 32-bit wraparound directions.
      foreach (tr.psum_in[c]) begin
        case (cycle % 4)
          0: tr.psum_in[c] = 32'sh7fffffff;
          1: tr.psum_in[c] = 32'sh80000000;
          2: tr.psum_in[c] = 32'sh7ffffffe;
          default: tr.psum_in[c] = 32'sh80000001;
        endcase
      end

      finish_item(tr);
    end
  endtask
endclass
