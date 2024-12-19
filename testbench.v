module testbench();
    reg clk, reset;
    CPU cpu (
        .clk(clk),
        .reset(reset)
    );

    initial begin
        clk = 0;
        reset = 1;
        #5 reset = 0;  // 复位信号

        // 生成时钟信号
        forever #5 clk = ~clk;
    end
endmodule
