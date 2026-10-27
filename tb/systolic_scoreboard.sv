class systolic_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(systolic_scoreboard)

  virtual systolic_if vif;
  uvm_analysis_imp #(systolic_transaction, systolic_scoreboard) input_export;

  logic signed [7:0] weights[4][4];
  logic signed [7:0] activations[4][4];
  logic signed [31:0] sums[4][4];

  int unsigned checks = 0;
  int unsigned errors = 0;

  function new(string name="systolic_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    input_export = new("input_export", this);

    if (!uvm_config_db#(virtual systolic_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Scoreboard virtual interface not found")
  endfunction

  function void write(systolic_transaction tr);
    logic signed [7:0] next_activations[4][4];
    logic signed [31:0] next_sums[4][4];
    logic signed [31:0] incoming_sum;
    logic signed [15:0] product;
    logic signed [7:0] incoming_activation;

    if (!vif.rst_n) begin
      foreach (weights[r,c]) begin
        weights[r][c] = '0;
        activations[r][c] = '0;
        sums[r][c] = '0;
      end
    end else begin
      foreach (weights[r,c]) begin
        incoming_activation = (c == 0) ? tr.a_in[r] :
                              activations[r][c-1];

        incoming_sum = (r == 0) ? tr.psum_in[c] :
                       sums[r-1][c];

        product = incoming_activation * weights[r][c];

        next_activations[r][c] = incoming_activation;
        next_sums[r][c] = incoming_sum + {{16{product[15]}}, product};
      end

      foreach (weights[r,c]) begin
        activations[r][c] = next_activations[r][c];
        sums[r][c] = next_sums[r][c];

        if (tr.load_weight)
          weights[r][c] = tr.weight_in[r][c];
      end
    end

  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      #1ps;
      foreach (vif.psum_out[c]) begin
        checks++;
        if (vif.psum_out[c] !== sums[3][c]) begin
          errors++;
          `uvm_error("SCOREBOARD",
            $sformatf("Column %0d: expected %0d, got %0d",
                      c, sums[3][c], vif.psum_out[c]))
        end
      end
    end
  endtask

  function void report_phase(uvm_phase phase);
    `uvm_info("SCOREBOARD",
      $sformatf("Checks=%0d Errors=%0d", checks, errors), UVM_LOW)
  endfunction
endclass
