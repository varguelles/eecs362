`include "constants.vh"

module hazard_detect(
    input clk, rst,
    input [31:0] id_instr, // current instruction
    input [31:0] ex_instr, // previous instruction
    input [31:0] mem_instr,
    input [4:0] id_rs1,
    input [4:0] id_rs2,
    input [4:0] ex_rd,
    input [4:0] mem_rd,
    input [4:0] wb_rd,
    input id_regDst,
    input ex_valid,
    input mem_valid,
    input wb_valid,
    input mem_memRd,
    input ex_memWr,
    input takeLeap,
    input [3:0] aluCtrl1, aluCtrl2,
    
    output reg [1:0] multCtrl,
    output reg [1:0] busA_sel, // (00 -> busA (ID), 01 -> aluRes (EX), 10 -> memWrData (MEM))
    output reg [1:0] busB_sel, //(00 -> busB (ID), 01 -> aluRes (EX), 10 -> memWrData (MEM))
    output reg [1:0] memWrData_sel, // (00 -> memWrData (MEM), 01 -> aluRes (EX), 11 -> memRdData(WB))
    output reg [1:0] if_id_ctrl, id_ex_ctrl, ex_mem_ctrl, mem_wb_ctrl,
    output reg pc_enable
); 
    
    wire pc_mult_ctrl;
    wire [1:0] if_id_mult_ctrl, id_ex_mult_ctrl, ex_mem_mult_ctrl, mem_wb_mult_ctrl, mult_multCtrl;

    
    multiplier_fsm multiplier_fsm(
        .clk(clk), .rst(rst),
        .aluCtrl(aluCtrl1),
        .cur_state(mult_multCtrl),
        .pc_mult_ctrl(pc_mult_ctrl),
        .if_id_mult_ctrl(if_id_mult_ctrl),
        .id_ex_mult_ctrl(id_ex_mult_ctrl),
        .ex_mem_mult_ctrl(ex_mem_mult_ctrl),
        .mem_wb_mult_ctrl(mem_wb_mult_ctrl)
    );

always @* begin 
    
     busA_sel = `FROM_ID;
     busB_sel = `FROM_ID;
     memWrData_sel = `FROM_MEM;
     if_id_ctrl = `GO;  id_ex_ctrl = `GO;  ex_mem_ctrl = `GO;  mem_wb_ctrl = `GO;
     pc_enable = 1'b1;
     multCtrl = `IDLE;
    
    ///////// JUMP DETECT
    
    if (takeLeap)
    begin
        //if_id_ctrl = `FLUSH;
        id_ex_ctrl = `FLUSH;
        ex_mem_ctrl = `FLUSH;
    end
    
    ///////// MULTIPLIER DETECT
    
    else if (aluCtrl2 == 4'b1111)
    begin
        pc_enable = pc_mult_ctrl;
        if_id_ctrl = if_id_mult_ctrl;
        id_ex_ctrl = id_ex_mult_ctrl;
        ex_mem_ctrl = ex_mem_mult_ctrl;
        mem_wb_ctrl = mem_wb_mult_ctrl;
        multCtrl = mult_multCtrl;
        
    end
    
    ///////// HAZARD DETECT
    
    else
    begin
    
        // BUS A HAZARD DETECTION
        if (ex_valid && (ex_rd != `R0) && (id_rs1 == ex_rd))
        begin
            // EX LOAD STALL DETECTION - RS1
            if (ex_instr[31:29] == `LD_INST)
            begin
                if_id_ctrl = `HOLD;
                id_ex_ctrl = `FLUSH;
                pc_enable = 1'b0;
            end
            // EX FORWARD DETECTION - RS1
            else
            begin
                busA_sel = `FROM_EX;
            end
        end
        
        else if ((mem_valid && mem_rd != `R0 && id_rs1 == mem_rd)) // || ex_instr == `NOP)
        begin 
            // MEM FORWARD DETECTION - RS1
            busA_sel = `FROM_MEM;
        end
       
        else
        begin
            // NO FORWARD - RS1
            busA_sel = `FROM_ID;
        end
       
       
        // BUS B HAZARD DETECTION 
        if (ex_valid && (ex_rd != `R0) && id_rs2 == ex_rd)
        begin
            // EX LOAD STALL DETECTION - RS1
            if (ex_instr[31:29] == `LD_INST)
            begin
                if_id_ctrl = `HOLD;
                id_ex_ctrl = `FLUSH;
                pc_enable = 1'b0;
            end
            // EX FORWARD DETECTION - RS1
            else
            begin
                busB_sel = `FROM_EX;
            end
        end
        
        else if ((mem_valid && mem_rd != `R0 && id_rs2 == mem_rd)) // || ex_instr == `NOP)
        begin 
            // MEM FORWARD DETECTION - RS1
            busB_sel = `FROM_MEM;
        end
        
        else
        begin
            // NO FORWARD - RS1
            busB_sel = `FROM_ID;
        end
        
        
        
        // MEMWRDATA HAZARD DETECTION
        if (mem_valid && mem_rd != `R0 && ex_instr == `NOP && ex_memWr && mem_rd == ex_rd)
        begin
            if (mem_memRd) 
            begin
                memWrData_sel = `FROM_WB;
            end
            else 
            begin
                memWrData_sel = `FROM_EX;
            end
        end
        else
        begin
            memWrData_sel = `FROM_MEM;
        end
    
    end

end // always

endmodule

///////////////////////////////
  
//     else if (ex_valid && (ex_rd != `R0)) // hazard with 1 instruction ahead
//         begin
//             if (id_rs1 == ex_rd) 
//             begin
//                 // $write("RS1 == EX_RD\n");
//                 if (ex_instr[31:29] == `LD_INST)
//                 begin // if opcode = 100, if instruction is load
//                      // $write("!!!!!! LOAD INSTRUCTION !!!!!!!\n");
//                      if_id_ctrl = `HOLD;
//                      id_ex_ctrl = `FLUSH;
//                      pc_enable = 1'b0;
                     
//                 end
//                 else
//                 begin
//                      // $write("busA_sel = 'From ex (rs1 = rd and not load)\n");
//                      busA_sel = `FROM_EX;
//                 end
//             end
//             if (id_rs2 == ex_rd) 
//             begin
//                 // $write("RS2 == EX_RD\n");
//                 if (ex_instr[31:29] == `LD_INST)
//                 begin// if opcode = 100, if instruction is load
//                      // $write("!!!!!! LOAD INSTRUCTION !!!!!!!\n");
//                      if_id_ctrl = `HOLD;
//                      id_ex_ctrl = `FLUSH;
//                      pc_enable = 1'b0;
//                 end
//                 else
//                 begin
//                      busB_sel = `FROM_EX;
//                 end
//             end
//         end 
    
    
    
//     else if (mem_valid && mem_rd != `R0 && ex_instr == `NOP) // hazard with 2 instructions ahead & a stall inbetween
//         begin 
//             if(id_rs1 == mem_rd)                            
//             begin
//                 // $write("RS1 == MEM_RD\n");
//                 busA_sel = `FROM_MEM;
//             end
//             if(id_rs2 == mem_rd) 
//             begin
//                 // $write("RS2 == MEM_RD\n");
//                 busB_sel = `FROM_MEM;
//             end
//             if(ex_memWr && mem_rd == ex_rd)
//             begin
//                 if (mem_memRd) 
//                 begin
//                     memWrData_sel = `FROM_WB;
//                 end
//                 else 
//                 begin
//                     memWrData_sel = `FROM_EX;
//                 end
//             end
            
                
//         end


    
//     // FORWARDING FOR LOAD TO NON-STORES
//     else
//     begin
//          busA_sel = `FROM_ID;
//          busB_sel = `FROM_ID;
//          memWrData_sel = `FROM_MEM;
//     end
        
// //    end
// //else
// //    id_opa_sel_out = id_opa_sel_in;

// end // always

// endmodule