class axi_lite_test extends uvm_test;
 
 `uvm_component_utils(axi_lite_test)
  
  axi_lite_env env;
  
  function new(string name = "axi_lite_test",
               uvm_component parent = null);
     
     super.new(name,parent);
     
  endfunction
  
  
  function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    
    env = axi_lite_env::type_id::create(
             "env",this);
             
  endfunction
  
  task run_phase(uvm_phase phase);
  
   axi_lite_base_sequence random_seq;
   axi_lite_negative_sequence negative_seq;
   axi_lite_wstrb_sequence wstrb_seq;
   
    random_seq = axi_lite_base_sequence::type_id::create(
                            "random_seq");
    
    negative_seq = axi_lite_negative_sequence::type_id::create(
                            "negative_seq");
                            
    wstrb_seq = axi_lite_wstrb_sequence::type_id::create(
                            "wstrb_seq");
                            
    phase.raise_objection(this);
    
      random_seq.start(env.agent.sequencer);
      negative_seq.start(env.agent.sequencer);
      wstrb_seq.start(env.agent.sequencer);
    
    phase.drop_objection(this);
    
  endtask  
    
endclass
    
