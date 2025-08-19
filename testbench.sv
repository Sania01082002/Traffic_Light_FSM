`include "uvm_macros.svh"
import uvm_pkg::*;

interface traffic_if;
    logic clk;
    logic rst;
    logic ns_green, ns_yellow, ns_red;
    logic ew_green, ew_yellow, ew_red;
endinterface


class traffic_transaction extends uvm_sequence_item;
    `uvm_object_utils(traffic_transaction)
    rand bit rst;  
    logic [1:0] state;  
    logic ns_green, ns_yellow, ns_red, ew_green, ew_yellow, ew_red;  

    function new(string name = "");
        super.new(name);
    endfunction

    function string convert2string();
        string s;
        s = $sformatf("rst=%b, state=%b, ns_g=%b, ns_y=%b, ns_r=%b, ew_g=%b, ew_y=%b, ew_r=%b",
                      rst, state, ns_green, ns_yellow, ns_red, ew_green, ew_yellow, ew_red);
        return s;
    endfunction
endclass



class traffic_sequence extends uvm_sequence #(traffic_transaction);
    `uvm_object_utils(traffic_sequence)

    function new(string name = "");
        super.new(name);
    endfunction

    task body();
        traffic_transaction trans;
        
        trans = traffic_transaction::type_id::create("trans");
        start_item(trans);
        trans.rst = 1;
        finish_item(trans);
        #10;
        trans = traffic_transaction::type_id::create("trans");
        start_item(trans);
        trans.rst = 0;  // Deassert reset
        finish_item(trans);
        repeat (5) begin
            trans = traffic_transaction::type_id::create("trans");
            start_item(trans);
            trans.rst = 0;
            finish_item(trans);
            #50;  
        end
    endtask
endclass



class traffic_driver extends uvm_driver #(traffic_transaction);
    `uvm_component_utils(traffic_driver)
    virtual traffic_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual traffic_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Virtual interface not set")
    endfunction

    task run_phase(uvm_phase phase);
        traffic_transaction req;
        fork
            forever begin
                vif.clk = 0; #5;
                vif.clk = 1; #5;
            end
        join_none

        forever begin
            seq_item_port.get_next_item(req);
            vif.rst = req.rst;
            @(posedge vif.clk);
            seq_item_port.item_done();
        end
    endtask
endclass


      
class traffic_monitor extends uvm_monitor;
    `uvm_component_utils(traffic_monitor)
    virtual traffic_if vif;
    uvm_analysis_port #(traffic_transaction) mon_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_ap = new("mon_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual traffic_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Virtual interface not set")
    endfunction

    task run_phase(uvm_phase phase);
        traffic_transaction trans;
        forever begin
            @(posedge vif.clk);
            trans = traffic_transaction::type_id::create("trans");
            trans.rst = vif.rst;
          
            if (vif.ns_green && !vif.ns_yellow && !vif.ns_red &&
                !vif.ew_green && !vif.ew_yellow && vif.ew_red)
                trans.state = 2'b00;  
            else if (!vif.ns_green && vif.ns_yellow && !vif.ns_red &&
                     !vif.ew_green && !vif.ew_yellow && vif.ew_red)
                trans.state = 2'b01;  
            else if (!vif.ns_green && !vif.ns_yellow && vif.ns_red &&
                     vif.ew_green && !vif.ew_yellow && !vif.ew_red)
                trans.state = 2'b10;  
            else if (!vif.ns_green && !vif.ns_yellow && vif.ns_red &&
                     !vif.ew_green && vif.ew_yellow && !vif.ew_red)
                trans.state = 2'b11;  
            else
                trans.state = 2'bxx;    
            trans.ns_green = vif.ns_green;
            trans.ns_yellow = vif.ns_yellow;
            trans.ns_red = vif.ns_red;
            trans.ew_green = vif.ew_green;
            trans.ew_yellow = vif.ew_yellow;
            trans.ew_red = vif.ew_red;
            mon_ap.write(trans);
            $display("Monitor: %s", trans.convert2string());
        end
    endtask
endclass


      
class traffic_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(traffic_scoreboard)
    uvm_analysis_imp #(traffic_transaction, traffic_scoreboard) sb_ap;
    int cycle_count;
    logic [1:0] expected_state;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        sb_ap = new("sb_ap", this);
        cycle_count = 0;
        expected_state = 2'b00;  
    endfunction

    function void write(traffic_transaction trans);
        cycle_count = cycle_count + 1;
        case (expected_state)
            2'b00: begin  
                if (cycle_count == 10) begin
                    expected_state = 2'b01;  
                    cycle_count = 0;
                end
            end
            2'b01: begin  
                if (cycle_count == 3) begin
                    expected_state = 2'b10;  
                    cycle_count = 0;
                end
            end
            2'b10: begin  
                if (cycle_count == 10) begin
                    expected_state = 2'b11;  
                    cycle_count = 0;
                end
            end
            2'b11: begin  
                if (cycle_count == 3) begin
                    expected_state = 2'b00;  
                    cycle_count = 0;
                end
            end
        endcase

        case (trans.state)
            2'b00: begin  
                if (trans.ns_green && !trans.ns_yellow && !trans.ns_red &&
                    !trans.ew_green && !trans.ew_yellow && trans.ew_red)
                    $display("Scoreboard: PASS - NS_GREEN correct");
                else
                    $display("Scoreboard: FAIL - NS_GREEN, got %s", trans.convert2string());
            end
            2'b01: begin  
                if (!trans.ns_green && trans.ns_yellow && !trans.ns_red &&
                    !trans.ew_green && !trans.ew_yellow && trans.ew_red)
                    $display("Scoreboard: PASS - NS_YELLOW correct");
                else
                    $display("Scoreboard: FAIL - NS_YELLOW, got %s", trans.convert2string());
            end
            2'b10: begin  
                if (!trans.ns_green && !trans.ns_yellow && trans.ns_red &&
                    trans.ew_green && !trans.ew_yellow && !trans.ew_red)
                    $display("Scoreboard: PASS - NS_GREEN correct");
                else
                    $display("Scoreboard: FAIL - EW_GREEN, got %s", trans.convert2string());
            end
            2'b11: begin  
                if (!trans.ns_green && !trans.ns_yellow && trans.ns_red &&
                    !trans.ew_green && trans.ew_yellow && !trans.ew_red)
                    $display("Scoreboard: PASS - EW_YELLOW correct");
                else
                    $display("Scoreboard: FAIL - EW_YELLOW, got %s", trans.convert2string());
            end
            default: $display("Scoreboard: FAIL - Unknown state, got %s", trans.convert2string());
        endcase
    endfunction
endclass


      
class traffic_agent extends uvm_agent;
    `uvm_component_utils(traffic_agent)
    traffic_driver drv;
    traffic_monitor mon;
    uvm_sequencer #(traffic_transaction) seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = traffic_driver::type_id::create("drv", this);
        mon = traffic_monitor::type_id::create("mon", this);
        seqr = uvm_sequencer#(traffic_transaction)::type_id::create("seqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
endclass


      
class traffic_env extends uvm_env;
    `uvm_component_utils(traffic_env)
    traffic_agent agt;
    traffic_scoreboard sb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = traffic_agent::type_id::create("agt", this);
        sb = traffic_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.mon_ap.connect(sb.sb_ap);
    endfunction
endclass


      
class traffic_test extends uvm_test;
    `uvm_component_utils(traffic_test)
    traffic_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = traffic_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        traffic_sequence seq;
        phase.raise_objection(this);
        seq = traffic_sequence::type_id::create("seq");
        seq.start(env.agt.seqr);
        #500;  
        phase.drop_objection(this);
    endtask
endclass


      
module testbench;
    traffic_if vif();
    traffic_light_fsm dut (
        .clk(vif.clk),
        .rst(vif.rst),
        .ns_green(vif.ns_green),
        .ns_yellow(vif.ns_yellow),
        .ns_red(vif.ns_red),
        .ew_green(vif.ew_green),
        .ew_yellow(vif.ew_yellow),
        .ew_red(vif.ew_red)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, testbench);
        // Set interface for UVM
        uvm_config_db#(virtual traffic_if)::set(null, "*", "vif", vif);
        run_test("traffic_test");
    end
endmodule
