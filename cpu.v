module ALU(
    input [31:0] A, B,        
    input [3:0] ALUControl,    
    output reg [31:0] ALUResult, 
    output reg Zero           
);
    always @(*) begin
        case(ALUControl)
            4'b0000: ALUResult = A + B;            
            4'b0001: ALUResult = A - B;            
            4'b0010: ALUResult = (A < B) ? 32'b1 : 32'b0;  
            4'b0011: ALUResult = (A < B) ? 32'b1 : 32'b0;  
            4'b0100: ALUResult = A | B;            
            4'b0101: ALUResult = A + B;            
            default: ALUResult = 32'b0;
        endcase
        Zero = (ALUResult == 32'b0);  
    end
endmodule

module Control(
    input [5:0] opcode,
    output reg reg_dst,        
    output reg alu_src,        
    output reg mem_to_reg,     
    output reg reg_write,      
    output reg mem_read,       
    output reg mem_write,      
    output reg branch,         
    output reg jump,           
    output reg [3:0] alu_op    
);
    always @(*) begin
        case (opcode)
            6'b000000: begin  
                reg_dst = 1;
                alu_src = 0;
                mem_to_reg = 0;
                reg_write = 1;
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                jump = 0;
                alu_op = 4'b0000;  
            end
            6'b100011: begin  
                reg_dst = 0;
                alu_src = 1;
                mem_to_reg = 1;
                reg_write = 1;
                mem_read = 1;
                mem_write = 0;
                branch = 0;
                jump = 0;
                alu_op = 4'b0000;  
            end
            6'b101011: begin  
                reg_dst = 0;
                alu_src = 1;
                mem_to_reg = 0;
                reg_write = 0;
                mem_read = 0;
                mem_write = 1;
                branch = 0;
                jump = 0;
                alu_op = 4'b0000;  
            end
            6'b000100: begin  
                reg_dst = 0;
                alu_src = 0;
                mem_to_reg = 0;
                reg_write = 0;
                mem_read = 0;
                mem_write = 0;
                branch = 1;
                jump = 0;
                alu_op = 4'b0001;  
            end
            6'b000010: begin  
                reg_dst = 0;
                alu_src = 0;
                mem_to_reg = 0;
                reg_write = 0;
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                jump = 1;
                alu_op = 4'bxxxx;  
            end
            6'b001000: begin  
                reg_dst = 0;
                alu_src = 1;       
                mem_to_reg = 0;    
                reg_write = 1;     
                mem_read = 0;      
                mem_write = 0;     
                branch = 0;        
                jump = 0;          
                alu_op = 4'b0000;  
            end
            6'b001001: begin  
                reg_dst = 0;
                alu_src = 1;       
                mem_to_reg = 0;    
                reg_write = 1;     
                mem_read = 0;      
                mem_write = 0;     
                branch = 0;        
                jump = 0;          
                alu_op = 4'b0000;  
            end
            default: begin
                reg_dst = 0;
                alu_src = 0;
                mem_to_reg = 0;
                reg_write = 0;
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                jump = 0;
                alu_op = 4'b0000;
            end
        endcase
    end
endmodule

module RegisterFile(
    input clk,
    input reg_write,           
    input [4:0] read_reg1, read_reg2, write_reg,  
    input [31:0] write_data,  
    output [31:0] read_data1, read_data2
);
    reg [31:0] reg_file [31:0];  

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            reg_file[i] = 32'b0;
        end
    end

    always @(posedge clk) begin
        if (reg_write) begin
            reg_file[write_reg] <= write_data;
        end
    end

    assign read_data1 = reg_file[read_reg1];
    assign read_data2 = reg_file[read_reg2];
endmodule

module DataMemory(
    input clk,
    input mem_read, mem_write,
    input [31:0] address, write_data,
    output reg [31:0] read_data
);
    reg [31:0] memory [0:1023];  

    always @(posedge clk) begin
        if (mem_write) begin
            memory[address[31:2]] <= write_data;  
        end
    end

    always @(posedge clk) begin
        if (mem_read) begin
            read_data <= memory[address[31:2]];  
        end
    end
endmodule

module PC(
    input clk,
    input reset,
    input [31:0] pc_in,
    output reg [31:0] pc_out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_out <= 32'b0; 
        else
            pc_out <= pc_in; 
    end
endmodule

module InstructionMemory(
    input [31:0] address,
    output [31:0] instruction
);
    reg [31:0] memory [0:1023];  

    initial begin
        $readmemh("C:/Users/35358/Desktop/cpu/program.mem", memory);  
    end

    assign instruction = memory[address[31:2]]; 
endmodule

module cpu(
    input clk,                    
    input reset                  
);
    wire [31:0] instruction, read_data1, read_data2, read_data3, alu_result, mem_data;
    wire [3:0] alu_op;
    wire zero, reg_write, mem_read, mem_write, branch, jump, alu_src, reg_dst, mem_to_reg;
    wire [31:0] write_data;
    wire [31:0] pc, next_pc, pc_plus_4, branch_addr, jump_addr;

    PC pc_module(
        .clk(clk),
        .reset(reset),
        .pc_in(next_pc),
        .pc_out(pc)
    );

    InstructionMemory imem(
        .address(pc),
        .instruction(instruction)
    );

    Control control(
        .opcode(instruction[31:26]),
        .reg_dst(reg_dst),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op)
    );

    RegisterFile rf(
        .clk(clk),
        .reg_write(reg_write),
        .read_reg1(instruction[25:21]),
        .read_reg2(instruction[20:16]),
        .write_reg(instruction[15:11]),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    ALU alu(
        .A(read_data1),
        .B(alu_src ? instruction[15:0] : read_data2),
        .ALUControl(alu_op),
        .ALUResult(alu_result),
        .Zero(zero)
    );

    DataMemory dmem(
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(alu_result),
        .write_data(read_data2),
        .read_data(mem_data)
    );

    assign write_data = mem_to_reg ? mem_data : alu_result;

    assign pc_plus_4 = pc + 4;
    assign branch_addr = pc + (instruction[15:0] << 2); 
    assign jump_addr = {pc[31:28], instruction[25:0], 2'b00};  

    assign next_pc = (branch && zero) ? branch_addr :
                     (jump) ? jump_addr : pc_plus_4;

endmodule

module testbench();
    reg clk, reset;
    cpu cpu0 (
        .clk(clk),
        .reset(reset)
    );

    initial begin
        clk = 0;
        reset = 1;
        #5 reset = 0;

        forever #5 clk = ~clk;
    end
endmodule
