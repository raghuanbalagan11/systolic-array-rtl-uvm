class systolic_random_sequence extends uvm_sequence #(systolic_transaction);
  `uvm_object_utils(systolic_random_sequence)

  function new(string name="systolic_random_sequence");
    super.new(name);
  endfunction

  task body();
    systolic_transaction tr;

    for (int cycle = 0; cycle < 956; cycle++) begin
      tr = systolic_transaction::type_id::create("tr");
      start_item(tr);

      tr.load_weight = (cycle == 0 || cycle % 20 == 0);

      foreach (tr.weight_in[r,c])
        begin
          case ((cycle + r + c) % 8)
            0: tr.weight_in[r][c] = -128;
            1: tr.weight_in[r][c] = 127;
            2: tr.weight_in[r][c] = -1;
            3: tr.weight_in[r][c] = 0;
            4: tr.weight_in[r][c] = 1;
            default: tr.weight_in[r][c] = 8'($urandom_range(0,255));
          endcase
        end

      foreach (tr.a_in[r]) begin
        case ((cycle + r) % 8)
          0: tr.a_in[r] = -128;
          1: tr.a_in[r] = 127;
          2: tr.a_in[r] = -1;
          3: tr.a_in[r] = 0;
          4: tr.a_in[r] = 1;
          default: tr.a_in[r] = 8'($urandom_range(0,255));
        endcase
        tr.psum_in[r] = 32'($urandom);
      end

      finish_item(tr);
    end
  endtask
endclass
