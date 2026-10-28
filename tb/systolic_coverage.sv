class systolic_coverage extends uvm_subscriber #(systolic_transaction);
  `uvm_component_utils(systolic_coverage)

  virtual systolic_if vif;
  int activation_value;
  int weight_value;
  int pe_row;
  int pe_col;
  int internal_activation_value;
  int internal_pe_row;
  int internal_pe_col;
  logic signed [31:0] internal_psum_value;
  int overflow_category;
  longint unsigned overflow_event_count[3];
  bit weight_load;
  bit previous_weight_load;
  bit consecutive_weight_load;
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

    consecutive_load_cp: coverpoint consecutive_weight_load {
      bins non_consecutive = {0};
      bins back_to_back = {1};
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

  // Coverage of actual registered activation values at all 16 PEs.
  covergroup pe_activation_cg;
    option.per_instance = 1;

    internal_activation_cp: coverpoint internal_activation_value {
      bins min_value = {-128};
      bins negative = {[-127:-1]};
      bins zero_value = {0};
      bins positive = {[1:126]};
      bins max_value = {127};
    }

    internal_row_cp: coverpoint internal_pe_row {
      bins rows[] = {[0:3]};
    }

    internal_col_cp: coverpoint internal_pe_col {
      bins columns[] = {[0:3]};
    }

    internal_position_cross: cross internal_row_cp, internal_col_cp;

    // Verify each activation category reaches each PE position.
    internal_activation_position_cross:
      cross internal_activation_cp, internal_row_cp, internal_col_cp;
  endgroup

  // Coverage of actual registered 32-bit partial sums.
  covergroup pe_psum_cg;
    option.per_instance = 1;

    internal_psum_cp: coverpoint internal_psum_value {
      bins min_value = {32'sh80000000};
      bins negative = {[32'sh80000001:32'shFFFFFFFF]};
      bins zero_value = {32'sd0};
      bins positive = {[32'sd1:32'sh7FFFFFFE]};
      bins max_value = {32'sh7FFFFFFF};
    }
  endgroup

  // Signed INT32 accumulation overflow classification.
  // 0 = no overflow, 1 = positive overflow, 2 = negative overflow.
  covergroup pe_overflow_cg;
    option.per_instance = 1;

    overflow_cp: coverpoint overflow_category {
      bins no_overflow = {0};
      bins positive_overflow = {1};
      bins negative_overflow = {2};
    }
  endgroup

  function new(string name="systolic_coverage", uvm_component parent=null);
    super.new(name, parent);
    systolic_cg = new();
    pe_activation_cg = new();
    pe_psum_cg = new();
    pe_overflow_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual systolic_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Coverage virtual interface not found")
  endfunction

  // Sample registered PE outputs after nonblocking assignments settle.
  task sample_internal_pe_coverage();
    forever begin
      @(posedge vif.clk);
      #1ps;
      if (vif.rst_n) begin
        for (int r = 0; r < 4; r++) begin
          for (int c = 0; c < 4; c++) begin
            internal_activation_value = int'(vif.pe_activation[r][c]);
            internal_pe_row = r;
            internal_pe_col = c;
            pe_activation_cg.sample();

            // Sample the registered partial sum of this PE.
            internal_psum_value = vif.pe_psum[r][c];
            pe_psum_cg.sample();
          end
        end
      end
    end
  endtask

  task run_phase(uvm_phase phase);
    fork
      sample_internal_pe_coverage();
    join_none
    forever begin
      @(negedge vif.rst_n);
      foreach (loaded_weights[r,c])
        loaded_weights[r][c] = '0;
      previous_weight_load = 0;
      `uvm_info("COVERAGE_RESET",
                "Coverage weight model cleared on asynchronous reset",
                UVM_LOW)
    end
  endtask

  function void write(systolic_transaction t);
    if (!vif.rst_n) begin
      foreach (loaded_weights[r,c])
        loaded_weights[r][c] = '0;
      previous_weight_load = 0;
      consecutive_weight_load = 0;
      return;
    end

    weight_load = t.load_weight;
    consecutive_weight_load = previous_weight_load && weight_load;
    previous_weight_load = weight_load;

    for (int r = 0; r < 4; r++) begin
      for (int c = 0; c < 4; c++) begin
        activation_value = int'(t.a_in[r]);
        weight_value = int'(loaded_weights[r][c]);
        pe_row = r;
        pe_col = c;
        systolic_cg.sample();
      end
    end

    // Classify each MAC using pre-edge operands and old weights.
    for (int r = 0; r < 4; r++) begin
      for (int c = 0; c < 4; c++) begin
        longint signed activation_operand;
        longint signed psum_operand;
        longint signed weight_operand;
        longint signed wide_sum;

        if (c == 0)
          activation_operand = longint'(t.a_in[r]);
        else
          activation_operand = longint'(vif.pe_activation[r][c-1]);

        if (r == 0)
          psum_operand = longint'(t.psum_in[c]);
        else
          psum_operand = longint'(vif.pe_psum[r-1][c]);

        weight_operand = longint'(loaded_weights[r][c]);
        wide_sum = psum_operand + activation_operand * weight_operand;

        if (wide_sum > 64'sd2147483647)
          overflow_category = 1;
        else if (wide_sum < -64'sd2147483648)
          overflow_category = 2;
        else
          overflow_category = 0;

        overflow_event_count[overflow_category]++;
        pe_overflow_cg.sample();
      end
    end

    if (t.load_weight) begin
      foreach (loaded_weights[r,c])
        loaded_weights[r][c] = t.weight_in[r][c];
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("OVERFLOW_COUNTS",
      $sformatf("No overflow=%0d Positive overflow=%0d Negative overflow=%0d",
                overflow_event_count[0],
                overflow_event_count[1],
                overflow_event_count[2]), UVM_LOW)
    `uvm_info("COVERAGE",
      $sformatf("Transaction functional coverage = %0.2f%%",
                systolic_cg.get_coverage()), UVM_LOW)

    `uvm_info("PE_COVERAGE",
      $sformatf("Internal PE activation coverage = %0.2f%%",
                pe_activation_cg.get_coverage()), UVM_LOW)

    `uvm_info("PSUM_COVERAGE",
      $sformatf("Internal PE partial-sum coverage = %0.2f%%",
                pe_psum_cg.get_coverage()), UVM_LOW)

    `uvm_info("OVERFLOW_COVERAGE",
      $sformatf("Signed INT32 MAC overflow coverage = %0.2f%%",
                pe_overflow_cg.get_coverage()), UVM_LOW)
  endfunction
endclass
