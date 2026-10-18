// ============================================================================
// Class: pcie_env
// Description: Integrates Agent and Scoreboard; binds analysis ports.
// ============================================================================

`ifndef PCIE_ENV_SV
`define PCIE_ENV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class pcie_env extends uvm_env;
    `uvm_component_utils(pcie_env)

    pcie_agent      agent;
    pcie_scoreboard scoreboard;

    function new(string name = "pcie_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = pcie_agent::type_id::create("agent", this);
        scoreboard = pcie_scoreboard::type_id::create("scoreboard", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.mon_ap.connect(scoreboard.mon_export);
    endfunction

endclass

`endif