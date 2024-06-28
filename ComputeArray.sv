module Computer #(
    parameter N = 4,
    parameter SIZE_COL = 20,
    parameter H_OUT = 20,
    parameter W_OUT = 10,
    parameter SIZE_in_DATA = 14,
    parameter SIZE_WEI = 10,
    parameter SIZE_IN = 10
)(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire signed [7:0] val_Wei [SIZE_WEI-1:0],
    input wire [7:0] row_Wei [SIZE_WEI-1:0],
    input wire [14:0] col_Wei [SIZE_COL:0],
    input wire signed [7:0] val_In [SIZE_IN-1:0],
    input wire [9:0] row_In [SIZE_IN-1:0],
    input wire [18:0] col_In [SIZE_COL:0],
    output reg finish,
    output reg signed [SIZE_in_DATA-1:0] array_out [N-1:0][N-1:0][3:0],
    output reg out_write
);
    // 内部逻辑在这里实现
    reg [18:0] count_In;
    reg [18:0] count_Wei;
    reg [18:0] count_col;
    reg [N-1:0]write_IN;
    reg [N-1:0]write_Wei;
    reg is_write=0;

    always @(posedge clk) begin
        if (reset) begin
            // Reset logic for array_out if needed
            for (int x = 0; x < N ; x++) begin
                for (int y = 0; y < N ; y++) begin
                    for (int k = 0; k < 3 ; k++) begin
                        array_out[x][y][k] <= 0;  // Reset all elements to zero
                    end
                end
            end
            count_In <= 0;
            count_Wei <= 0;
            count_col <= 0;
            finish <= 0;
            write_IN <= 0;
            write_Wei <= 0;
            out_write=0;
        end else if (enable) begin
            write_IN = -1;
            write_Wei=-1;
            is_write=0;
            if(count_Wei >= col_Wei[count_col+1] || count_In >= col_In[count_col+1]) begin
                write_IN = 0;
                write_Wei= 0;
                if(count_In >= col_In[count_col+1]) begin             
                    count_col = count_col + 1;
                    count_Wei = col_Wei[count_col];
                    count_In = col_In[count_col];
                    if (count_col == SIZE_COL) begin
                        finish = 1;
                    
                    end
                end else begin
                    count_In = count_In + N;
                    count_Wei = col_Wei[count_col];
                end
            end
             for(integer i=0;i<N;i++)begin
                if(count_Wei+i>=col_Wei[count_col+1])begin
                    write_Wei[i]=0;
                end
                if(count_In+i>=col_In[count_col+1])begin
                    write_IN[i]=0;
                end

            end
            for(integer i=0;i<N;i++)begin
            for(integer j=0;j<N;j++)begin
                if( write_Wei[j]*write_IN[i] == 1) begin
                    array_out[i][j][0]=val_In[count_In+i] * val_Wei[count_Wei+j];
                    array_out[i][j][1]=row_Wei[count_Wei+j];
                    array_out[i][j][2]=row_In[count_In+i];
                    is_write=1;
                    array_out[i][j][3]=1;
                end
            end
            end
            if(is_write==1)begin
                count_Wei= count_Wei+N;
            end
        end
    end
endmodule
