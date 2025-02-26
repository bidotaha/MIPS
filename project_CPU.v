//////////////////// register_file //////////////////////////////////////////////////////////

module register_file ( output [31:0] rd1,    // Read data 1
                       output [31:0] rd2,    // Read data 2
                       input clk,rst,            // clock signal rst signal  
                       input WE3,            // write enable signal
                       input [4:0] A1,A2,A3, // address
                       input [31:0] WD3);    // write data

reg [31:0] reg_file [0:31];  // 32 registers, each 32 bits wide
integer i;
  // asynchronous 
assign rd1 = reg_file [A1];
assign rd2 = reg_file [A2];
  // synchronous
always@(posedge clk,negedge rst)
begin
if (!rst)
begin
for (i=0;i<32;i=i+1)
reg_file [i] = 32'b0;
end
else
begin
if (WE3)
reg_file [A3] <= WD3;   // Write data to the register
end 
end
endmodule 

module register_file_ts ();
wire [31:0] rd1,rd2;
reg clk,WE3;
reg [4:0] A1,A2,A3;
reg [31:0] WD3;
register_file t (rd1,rd2,clk,WE3,A1,A2,A3,WD3);
initial 
begin
clk = 0;
repeat (800) #5 clk = ~clk;
end
initial
begin
WE3 = 0;
A1 = 0;
A2 = 0;
A3 =0;
WD3 =0;
// Test Case 1: Write 32'b11111111111111110000000000000000 to register 5
#10
A3 = 5;
WD3 = 32'b11111111111111110000000000000000;
WE3 = 1;
#10
WE3 = 0;
 // Test Case 2: Read from register 5 and register 10
A1 = 5;
A2 = 10;
// Test Case 3: Write 32'b11111111000000001111111100000000 to register 5
#10
A3 = 10;
WD3 = 32'b11111111000000001111111100000000;
WE3 = 1;
#10
WE3 = 0;
 // Test Case 4: Read from register 5 and register 10
A1 = 5;
A2 = 10;
end 
endmodule 

/////////////////////////// control_unit ///////////////////////////////////////////////////////////////////////

module alu_decoder ( output reg  [2:0] alucontrol,
                     input [1:0] aluop,
                     input [5:0] funct);
always@(*)
begin
case (aluop)
2'b00 : alucontrol = 3'b010;
2'b01 : alucontrol = 3'b100;
2'b10 : begin
        case (funct)
        6'b100000 : alucontrol = 3'b010;
        6'b100010 : alucontrol = 3'b100;
        6'b101010 : alucontrol = 3'b110;
        6'b011100 : alucontrol = 3'b101;
        default   : alucontrol = 3'b010;
        endcase
        end
default : alucontrol = 3'b010;
endcase
end
endmodule 

module main_decoder ( output reg jump,
                      output reg memtoreg,
                      output reg memwrite,
                      output reg branch,
                      output reg alusrc,
                      output reg regdst,
                      output reg regwrite,
                      output reg [1:0] aluop,
                      input [5:0] opcode);
always@(*)
begin
case (opcode)
6'b100011 : begin
            jump = 0;
            aluop = 2'b00;
            memwrite = 0;
            regwrite = 1;
            regdst = 0;
            alusrc = 1;
            memtoreg = 1;
            branch = 0;
            end
6'b101011 : begin
            jump = 0;
            aluop = 2'b00;
            memwrite = 1;
            regwrite = 0;
            regdst = 0;
            alusrc = 1;
            memtoreg = 1;
            branch = 0;
            end
6'b000000 : begin
            jump = 0;
            aluop = 2'b10;
            memwrite = 0;
            regwrite = 1;
            regdst = 1;
            alusrc = 0;
            memtoreg = 0;
            branch = 0;
            end
6'b001000 : begin
            jump = 0;
            aluop = 2'b00;
            memwrite = 0;
            regwrite = 1;
            regdst = 0;
            alusrc = 1;
            memtoreg = 0;
            branch = 0;
            end
6'b000100 : begin
            jump = 0;
            aluop = 2'b01;
            memwrite = 0;
            regwrite = 0;
            regdst = 0;
            alusrc = 0;
            memtoreg = 0;
            branch = 1;
            end
6'b000010 : begin
            jump = 1;
            aluop = 2'b00;
            memwrite = 0;
            regwrite = 0;
            regdst = 0;
            alusrc = 0;
            memtoreg = 0;
            branch = 0;
            end
default   : begin
            jump = 0;
            aluop = 2'b00;
            memwrite = 0;
            regwrite = 0;
            regdst = 0;
            alusrc = 0;
            memtoreg = 0;
            branch = 0;
            end
endcase
end
endmodule

module control_unit ( output jump,
                      output memtoreg,
                      output memwrite,
                      output branch,
                      output alusrc,
                      output regdst,
                      output regwrite,
                      output [2:0] alucontrol,
                      input [5:0] opcode,
                      input [5:0] funct);
wire [1:0] aluop;
main_decoder p (jump,memtoreg,memwrite,branch,alusrc,regdst,regwrite,aluop,opcode);
alu_decoder l (alucontrol,aluop,funct);

endmodule

/////////////////////////// data memory //////////////////////////////////////////////////////////////////////////

module data_memory ( output reg [31:0] readdata,
                     output reg [15:0] test_value,
                     input clk,memwrite,rst,
                     input [31:0] aluout,writedata);
reg [31:0] ram [0:255];
integer i;
always@(posedge clk,negedge rst)
begin
if (!rst)
begin
for (i=0;i<256;i=i+1)
ram [i] = 32'h0;
end
else
begin
if (memwrite)
ram[aluout[9:2]]=writedata;
end
end
always@(*)
begin
readdata = ram [aluout[9:2]];
test_value = ram [0][15:0];
end
endmodule 

module data_memory_ts ();
wire [31:0] readdata;
wire [15:0] test_value;
reg clk,memwrite,rst;
reg [31:0] aluout,writedata;
data_memory t (readdata,test_value,clk,memwrite,rst,aluout,writedata);
initial
begin
clk = 0;
repeat (200) 
#2 clk = ~clk;
end
initial
begin
rst = 0;
#10 rst =1;
end
initial
begin
aluout = 32'h000000;
memwrite = 1;
writedata = 0;
#5 memwrite = 0;
#5 writedata = 32'd15;
#5 memwrite = 1;
end
endmodule 

///////////////////////// sign extend /////////////////////////////////////////////////////////////////////

module sign_extend ( output [31:0] out,
                     input [15:0] in);
    assign out = {{16{in[15]}}, in};
endmodule

//////////////////////////////////////////////// shift_left_twice //////////////////////////////////////////////

module shift_left_twice ( output [31:0] out,
                          input [31:0] in);
    assign out = in << 2;
endmodule
/*
module shift_left_twice_25 ( output [27:0] out,
                             input [25:0] in);
    assign out = in << 2;
endmodule
*/
//////////////////////// adder /////////////////////////////////////////////////////////////////////
             
module adder ( output [31:0] sum,
               input [31:0] in1,
               input [31:0] in2);
    assign sum = in1 + in2;
endmodule

module adder_4 ( output [31:0] sum,
                 input [31:0] in1);
    assign sum = in1 + 4;
endmodule

///////////////////////// mux//////////////////////////////////////////////////////////////////////////

module mux2x1_32_bit ( output [31:0] out,
                       input [31:0] in1,
                       input [31:0] in2,
                       input sel );
    assign out = sel ? in1 : in2;
endmodule

module mux2x1_5_bit ( output [4:0] out,
                      input [4:0] in1,
                      input [4:0] in2,
                      input sel );
    assign out = sel ? in1 : in2;
endmodule

////////////////////////////////////////////////////alu //////////////////////////////////////////

module alu_mips ( output reg [31:0] aluresult,
                  output Zero,
                  input [31:0] SrcA,SrcB,
                  input [2:0]  alucontrol);
 always@(*)
  begin 
    case (alucontrol)
    3'b000 : aluresult = SrcA&SrcB;  
    3'b001 : aluresult = SrcA|SrcB;  
    3'b010 : aluresult = SrcA+SrcB;
    3'b011 : aluresult = 32'b0;   
    3'b100 : aluresult = SrcA-SrcB;  
    3'b101 : aluresult = SrcA*SrcB;     
    3'b110 : begin 
             if(SrcA < SrcB) 
               aluresult = 1;
             end 
    3'b111 : aluresult = 32'b0; 
    default: aluresult = 32'b0;        
 endcase    
end 
assign Zero = (aluresult == 32'd0) ? 1'b1 : 1'b0;
endmodule

///////////////////////////////////////////////////pc///////////////////////////////////////////////

module program_Counter ( output reg [31:0] PC_out,
                         input  [31:0]  PC_in ,
                         input clk,rst);
  always@(posedge clk,negedge rst) 
  begin
    if (!rst)
    PC_out = 32'b0;
    else
    PC_out<=PC_in ;  
  end   
endmodule

//////////////////////////////////////////////////////////// instruction data ///////////////////////////////////////////

module instruction_rom ( output [31:0] instruction,
                         input [31:0] address); 
reg [31:0] rom [0:255];
initial
begin
rom [0] = 32'h00008020;
rom [1] = 32'h20100007;
rom [2] = 32'h00008820;
rom [3] = 32'h20110001;
rom [4] = 32'h12000003;
rom [5] = 32'h0230881C;
rom [6] = 32'h2210FFFF;
rom [7] = 32'h08000004;
rom [8] = 32'hAC110000;
end
assign instruction = rom [address[9:2]];
endmodule

////////////////////////////////////////////// top module ///////////////////////////////////////////////

module top_module ( input clk,rst,
                    output [15:0] test_value);

wire [31:0] rd1,rd2;
wire regwrite,regdst,memtoreg,jump,memwrite,branch,alusrc;
wire [2:0] alucontrol;
wire [31:0] instr;
wire [4:0] mux1;
wire [31:0] mux2;
wire [31:0] readdata;
wire [31:0] aluresult;
wire [31:0] signlmm;
wire [31:0] shift_out1;
wire [31:0] pcbranch;
wire [31:0] pcplus4;
wire [31:0] pcjump;
wire [31:0] mux3;
wire [31:0] mux4;
wire pcsrc;
wire zero;
wire [31:0] pc_out;
wire [31:0] srca;
wire [31:0] srcb;

register_file q1(rd1,rd2,clk,rst,regwrite,instr [25:21],instr [20:16],mux1,mux2);
mux2x1_5_bit q2 (mux1,instr [15:11],instr [20:16],regdst);
mux2x1_32_bit q3 (mux2,readdata,aluresult,memtoreg);
sign_extend q4 (signlmm,instr [15:0]);
shift_left_twice q5 (shift_out1,signlmm);
adder q6 (pcbranch,shift_out1,pcplus4);
shift_left_twice q7(pcjump,instr);
mux2x1_32_bit q8 (mux3,{pcplus4 [31:28] ,pcjump [27:0]},mux4,jump);
mux2x1_32_bit q9 (mux4,pcbranch,pcplus4,pcsrc);
and (pcsrc,branch,zero);
program_Counter q10 (pc_out,mux3,clk,rst);
instruction_rom q11 (instr,pc_out);
adder_4 q12 (pcplus4,pc_out);
mux2x1_32_bit q13 (srcb,signlmm,rd2,alusrc);
assign srca = rd1;
alu_mips q14 (aluresult,zero,srca,srcb,alucontrol);
data_memory q15 (readdata,test_value,clk,memwrite,rst,aluresult,rd2);
control_unit q16(jump,memtoreg,memwrite,branch,alusrc,regdst,regwrite,alucontrol,instr [31:26],instr [5:0]);

endmodule

`timescale 100ns/1ps

module top_module_ts ();

wire [15:0] test_value;
reg clk,rst;

top_module i (clk,rst,test_value);

initial
begin
clk = 0;
repeat (5000)
#10 clk = ~clk;
end 
initial
begin
rst = 0;
#100 rst = 1;
end
endmodule
