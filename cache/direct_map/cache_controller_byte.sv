module dm_cache_data#(
    parameter Indexwidth = 10,
    parameter Lines = 1024
)(
    input wire clk,
    input wire [Indexwidth-1:0] index,
    input wire we,
    input wire [127:0] data_write,
    output logic [127:0] data_read
);
    (*ram_style = "BLOCK"*) reg [127:0] data_mem [0:2**Indexwidth-1];
    integer i;
    initial begin
        for (i = 0; i < Lines; i = i + 1) begin
            data_mem[i] <= '0;
        end
    end

    always_ff @ (posedge clk) begin
        if (we) begin
            data_mem[index] <= data_write;
            data_read <= data_write;
        end else begin
            data_read <= data_mem[index];
        end
    end
endmodule

module dm_cache_tag#(
    parameter Indexwidth = 10,
    parameter Lines = 1024,
    parameter Tagwidth = 13
)(
    input wire clk,
    input wire [Indexwidth-1:0] index,
    input wire we,
    input wire [Tagwidth+2:0] tag_write,
    output logic [Tagwidth+2:0] tag_read
);
    (*ram_style = "BLOCK"*) reg [Tagwidth+2:0] tag_mem [0:2**Indexwidth-1]; //{Valid, Dirty, Accessed} is included
    integer i;
    initial begin
        for (i = 0; i < Lines; i = i + 1) begin
            tag_mem[i] <= '0;
        end
    end

    always_ff @ (posedge clk) begin
        if (we) begin
            tag_mem[index] <= tag_write;
            tag_read <= tag_write;
        end else begin
            tag_read <= tag_mem[index];
        end
    end
endmodule

module cache_controller#(
    parameter Addresswidth = 27,
    parameter Tagwidth = 13, // Addresswidth - Indexwidth - Offsetwidth
    parameter Indexwidth = 10,
    parameter Offsetwidth = 4,
    parameter Numlines = 1024, // 2 ** Indexwidth
    parameter Cachelinesize = 16 // 2 ** Offsetwidth
)(
    master_fifo.master fifo,
    input wire clk,
    input wire [Addresswidth-1:0] addr,
    input wire [7:0] data,
    input wire wr, //write = 0, read = 1
    input wire req_valid,
    output logic req_ready,
    output logic [7:0] rsp_data,
    output logic rsp_valid
);
    localparam idle        = 2'd0;
    localparam compare_tag = 2'd1;
    localparam allocate    = 2'd2;
    localparam write_back  = 2'd3;

    logic [1:0] vstate;
    logic [1:0] rstate = idle;

    logic [Addresswidth-1:0] save_addr;
    logic [7:0] save_data;
    logic save_wr;

    always_ff @ (posedge clk) begin
        rstate <= vstate;
        if(rstate == idle) begin
            save_addr <= addr;
            save_data <= data;
            save_wr <= wr;
        end
    end

    logic [Addresswidth-1:0] req_addr;
    logic [7:0] req_data;
    logic req_wr;

    assign req_addr = (rstate == idle && req_valid) ? addr : save_addr;
    assign req_data = (rstate == idle && req_valid) ? data : save_data;
    assign req_wr = (rstate == idle && req_valid) ? wr : save_wr;
    
    assign req_ready = (rstate == idle);

    logic [Tagwidth+2:0] tag_read;
    logic [Tagwidth+2:0] tag_write;
    logic [Indexwidth-1:0] tag_req_index;
    logic tag_req_we;

    logic [127:0] data_read;
    logic [127:0] data_write;
    logic [Indexwidth-1:0] data_req_index;
    logic data_req_we;
    
    always_comb begin
        vstate = rstate;
        rsp_data = '0;
        rsp_valid = '0;
        tag_write = '0;
        tag_req_we = '0;
        tag_req_index = req_addr[Indexwidth+Offsetwidth-1:Offsetwidth];

        data_req_we = '0;
        data_req_index = req_addr[Indexwidth+Offsetwidth-1:Offsetwidth];

        data_write = data_read;
        case(req_addr[Offsetwidth-1:0])
            4'd0: data_write[7:0] = req_data;
            4'd1: data_write[15:8] = req_data;
            4'd2: data_write[23:16] = req_data;
            4'd3: data_write[31:24] = req_data;
            4'd4: data_write[39:32] = req_data;
            4'd5: data_write[47:40] = req_data;
            4'd6: data_write[55:48] = req_data;
            4'd7: data_write[63:56] = req_data;
            4'd8: data_write[71:64] = req_data;
            4'd9: data_write[79:72] = req_data;
            4'd10: data_write[87:80] = req_data;
            4'd11: data_write[95:88] = req_data;
            4'd12: data_write[103:96] = req_data;
            4'd13: data_write[111:104] = req_data;
            4'd14: data_write[119:112] = req_data;
            4'd15: data_write[127:120] = req_data;
        endcase

        case(req_addr[Offsetwidth-1:0])
            4'd0: rsp_data = data_read[7:0];
            4'd1: rsp_data = data_read[15:8];
            4'd2: rsp_data = data_read[23:16];
            4'd3: rsp_data = data_read[31:24];
            4'd4: rsp_data = data_read[39:32];
            4'd5: rsp_data = data_read[47:40];
            4'd6: rsp_data = data_read[55:48];
            4'd7: rsp_data = data_read[63:56];
            4'd8: rsp_data = data_read[71:64];
            4'd9: rsp_data = data_read[79:72];
            4'd10: rsp_data =  data_read[87:80];
            4'd11: rsp_data =  data_read[95:88];
            4'd12: rsp_data =  data_read[103:96];
            4'd13: rsp_data =  data_read[111:104];
            4'd14: rsp_data =  data_read[119:112];
            4'd15: rsp_data =  data_read[127:120];
        endcase

        fifo.clk = clk;
        fifo.req.addr = {1'b0, req_addr[Addresswidth-1:Offsetwidth], 3'b0};
        fifo.req.data = data_read;
        fifo.req.cmd = '1;
        fifo.req_en = '0;
        fifo.rsp_rdy = 1'b1;

        case(rstate)
            idle: begin
                if(req_valid) begin
                    vstate = compare_tag;
                end
            end
            compare_tag: begin
                if(req_addr[Addresswidth-1:Indexwidth+Offsetwidth] == tag_read[Tagwidth-1:0] && tag_read[Tagwidth+2]) begin
                    if(~req_wr) begin
                        tag_req_we = 1'b1;
                        data_req_we = 1'b1;
                        tag_write = {3'b111, tag_read[Tagwidth-1:0]};
                    end else begin
                        rsp_valid = 1'b1;
                    end
                    vstate = idle;
                end else begin
                    fifo.req_en = 1'b1;
                    if(~tag_read[Tagwidth+2] || ~tag_read[Tagwidth+1]) begin
                        if(fifo.req_rdy) begin
                            tag_req_we = 1'b1;
                            tag_write = {1'b1, ~req_wr, 1'b1, req_addr[Addresswidth-1:Indexwidth+Offsetwidth]};
                            vstate = allocate;
                        end
                    end else begin
                        fifo.req.addr = {1'b0, tag_read[Tagwidth-1:0], req_addr[Indexwidth+Offsetwidth-1:Offsetwidth], 3'b0};
                        fifo.req.cmd = 1'b0;
                        if(fifo.req_rdy) begin
                            tag_req_we = 1'b1;
                            tag_write = {1'b1, ~req_wr, 1'b1, req_addr[Addresswidth-1:Indexwidth+Offsetwidth]};
                            vstate = write_back;
                        end
                    end
                end
            end
            allocate: begin
                if(fifo.rsp_en) begin
                    vstate = compare_tag;
                    data_write = fifo.rsp.data;
                    data_req_we = 1'b1;
                end
            end
            write_back: begin
                fifo.req_en = 1'b1;
                fifo.req.cmd = 1'b1;
                if(fifo.req_rdy) begin
                    vstate = allocate;
                end
            end
        endcase
    end

    dm_cache_tag ctag(
        .clk(clk),
        .index(tag_req_index),
        .we(tag_req_we),
        .tag_write(tag_write),
        .tag_read(tag_read)
    );

    dm_cache_data cdata(
        .clk(clk),
        .index(data_req_index),
        .we(data_req_we),
        .data_write(data_write),
        .data_read(data_read)
    );
endmodule