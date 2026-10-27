class systolic_coverage extends uvm_subscriber #(systolic_transaction);
  `uvm_component_utils(systolic_coverage)

  virtual systolic_if vif;
  int activation_value;
  int weight_value;
  int pe_row;
  int pe_col;
  bit weight_load;
  bit signed [7:0] loaded_weights[4][4];

  covergroup systolic_cg;
    option.per_instance = 1;

    activation_cp: coverpoint activation_value {
      bins negative = {[-128:-1]};
      bins zero = {0};
      bins positive = {[1:127]};
    }

    weight_cp: coverpoint weight_value {
      bins negative = {[-128:-1]};
      bins zero = {0};
      bins positive = {[1:127]};
    }

    load_cp: coverpoint weight_load {
      bins disabled = {0};
      bins enabled = {1};
    }

    activation_boundary_cp: coverpoint activation_value {
      bins min_value = {-128};
      bins negative_one = {-1};
      bins zero_value = {0};
      bins positive_one = {1};
      bins max_value = {127};
      bins other_negative = {[-127:-2]};
      bins other_positive = {[2:126]};
    }

    weight_boundary_cp: coverpoint weight_value {
      bins min_value = {-128};
      bins negative_one = {-1};
      bins zero_value = {0};
      bins positive_one = {1};
      bins max_value = {127};
      bins other_negative = {[-127:-2]};
      bins other_positive = {[2:126]};
    }

    pe_row_cp: coverpoint pe_row {
      bins rows[] = {[0:3]};
    }

    pe_col_cp: coverpoint pe_col {
      bins columns[] = {[0:3]};
    }

    pe_position_cross: cross pe_row_cp, pe_col_cp;

    sign_cross: cross activation_cp, weight_cp;
  endgroup

  function new(string name="systolic_coverage", uvm_component parent=null);
    super.new(name, parent);
    systolic_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual systolic_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Coverage virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(negedge vif.rst_n);
      foreach (loaded_weights[r,c])
        loaded_weights[r][c] = '0;
      `uvm_info("COVERAGE_RESET",
                "Coverage weight model cleared on asynchronous reset",
                UVM_LOW)
    end
  endtask

  function void write(systolic_transaction t);
    if (!vif.rst_n) begin
      foreach (loaded_weights[r,c])
        loaded_weights[r][c] = '0;
      return;
    end

    weight_load = t.load_weight;

    for (int r = 0; r < 4; r++) begin
      for (int c = 0; c < 4; c++) begin
        activation_value = int'(t.a_in[r]);
        weight_value = int'(loaded_weights[r][c]);
        pe_row = r;
        pe_col = c;
        systolic_cg.sample();
      end
    end

    if (t.load_weight) begin
      foreach (loaded_weights[r,c])
        loaded_weights[r][c] = t.weight_in[r][c];
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COVERAGE",
      $sformatf("Functional coverage = %0.2f%%",
                systolic_cg.get_coverage()), UVM_LOW)
  endfunction
endclass
