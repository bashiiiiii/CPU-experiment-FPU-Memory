module dm_cache_data#(
    parameter Indexwidth = 13,
    parameter Lines = 8192
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
            data_mem[i] = '0;
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
    parameter Indexwidth = 13,
    parameter Lines = 8192,
    parameter Tagwidth = 10
)(
    input wire clk,
    input wire [Indexwidth-1:0] index,
    input wire we,
    input wire [Tagwidth:0] tag_write,
    output logic [Tagwidth:0] tag_read
);
    (*ram_style = "BLOCK"*) reg [Tagwidth:0] tag_mem [0:2**Indexwidth-1]; //{Dirty} is included
    integer i;
    initial begin
        for (i = 0; i < Lines; i = i + 1) begin
            tag_mem[i] = '0;
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
    parameter Addresswidth = 25,
    parameter Tagwidth = 10, // Addresswidth - Indexwidth - Offsetwidth
    parameter Indexwidth = 13,
    parameter Offsetwidth = 2
)(
    master_fifo.master fifo,
    input wire clk,
    input wire [Addresswidth-1:0] addr,
    input wire [31:0] data,
    input wire wr, //write = 0, read = 1
    input wire req_valid,
    output logic req_ready,
    output logic [31:0] rsp_data,
    output logic rsp_valid
);
    localparam idle        = 2'b00;
    localparam compare_tag = 2'b01;
    localparam allocate    = 2'b10;
    localparam write_back  = 2'b11;

    logic [1:0] vstate;
    logic [1:0] rstate = idle;

    logic vlru;
    logic rlru = '0;

    logic [Addresswidth-1:0] save_addr;
    logic [31:0] save_data;
    logic save_wr;

    always_ff @ (posedge clk) begin
        rstate <= vstate;
        rlru <= vlru;
        if(rstate === idle) begin
            save_addr <= addr;
            save_data <= data;
            save_wr <= wr;
        end
    end

    logic [Addresswidth-1:0] req_addr;
    logic [Tagwidth-1:0] req_tag;
    logic [Indexwidth-1:0] req_index;
    logic [Offsetwidth-1:0] req_offset;
    logic [31:0] req_data;
    logic req_wr;

    assign req_ready = (rstate === idle);
    assign req_addr = (rstate === idle && req_valid) ? addr : save_addr;
    assign req_tag = req_addr[Addresswidth-1:Indexwidth+Offsetwidth];
    assign req_index = req_addr[Indexwidth+Offsetwidth-1:Offsetwidth];
    assign req_offset = req_addr[Offsetwidth-1:0];
    assign req_data = (rstate === idle && req_valid) ? data : save_data;
    assign req_wr = (rstate === idle && req_valid) ? wr : save_wr;
    
    logic [Tagwidth:0] tag0_read, tag1_read;
    logic [Tagwidth:0] tag0_write, tag1_write;
    logic [Indexwidth-1:0] tag_req_index;
    logic tag0_req_we, tag1_req_we;
    logic tag0_dirty, tag1_dirty;
    logic [Tagwidth-1:0] tag0, tag1;

    assign {tag0_dirty, tag0} = tag0_read;
    assign {tag1_dirty, tag1} = tag1_read;

    logic [127:0] data0_read, data1_read;
    logic [127:0] data0_write, data1_write;
    logic [Indexwidth-1:0] data_req_index;
    logic data0_req_we, data1_req_we;

    always_comb begin
        vstate = rstate;
        vlru = rlru;
        rsp_valid = '0;

        rsp_data = '0;
        case(req_offset)
            2'b00: begin
                if(req_tag === tag0) begin
                    rsp_data = data0_read[31:0];
                end else if(req_tag === tag1) begin
                    rsp_data = data1_read[31:0];
                end
            end
            2'b01: begin
                if(req_tag === tag0) begin
                    rsp_data = data0_read[63:32];
                end else if(req_tag === tag1) begin
                    rsp_data = data1_read[63:32];
                end
            end
            2'b10: begin
                if(req_tag === tag0) begin
                    rsp_data = data0_read[95:64];
                end else if(req_tag === tag1) begin
                    rsp_data = data1_read[95:64];
                end
            end
            2'b11: begin
                if(req_tag === tag0) begin
                    rsp_data = data0_read[127:96];
                end else if(req_tag === tag1) begin
                    rsp_data = data1_read[127:96];
                end
            end
        endcase

        tag0_write = tag0_read;
        tag1_write = tag1_read;

        tag0_req_we = '0;
        tag1_req_we = '0;
        tag_req_index = req_index;

        data0_req_we = '0;
        data1_req_we = '0;
        data_req_index = req_index;

        data0_write = data0_read;
        data1_write = data1_read;

        case(req_offset)
            2'b00: begin
                data0_write[31:0] = req_data;
                data1_write[31:0] = req_data;
            end
            2'b01: begin
                data0_write[63:32] = req_data;
                data1_write[63:32] = req_data;
            end
            2'b10: begin
                data0_write[95:64] = req_data;
                data1_write[95:64] = req_data;
            end
            2'b11: begin
                data0_write[127:96] = req_data;
                data1_write[127:96] = req_data;
            end
        endcase

        fifo.clk = clk;
        fifo.req.addr = {1'b0, req_tag, req_index, 3'b0};
        fifo.req.data = '0;
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
                if(req_tag === tag0) begin
                    if(req_wr) begin
                        rsp_valid = 1'b1;
                    end else begin
                        tag0_req_we = 1'b1;
                        data0_req_we = 1'b1;
                        tag0_write = {1'b1, tag0};
                        vlru = 1'b0;
                    end
                    vstate = idle;
                end else if(req_tag === tag1) begin
                    if(req_wr) begin
                        rsp_valid = 1'b1;
                    end else begin
                        tag1_req_we = 1'b1;
                        data1_req_we = 1'b1;
                        tag1_write = {1'b1, tag1};
                        vlru = 1'b1;
                    end
                    vstate = idle;
                end else begin
                    if(rlru) begin
                        fifo.req_en = 1'b1;
                        if(tag0_dirty) begin
                            fifo.req.addr = {1'b0, tag0, req_index, 3'b0};
                            fifo.req.cmd = 1'b0;
                            fifo.req.data = data0_read;
                            if(fifo.req_rdy) begin
                                tag0_req_we = 1'b1;
                                tag0_write = {~req_wr, req_tag};
                                vstate = write_back;
                                vlru = 1'b0;
                            end
                        end else begin
                            if(fifo.req_rdy) begin
                                tag0_req_we = 1'b1;
                                tag0_write = {~req_wr, req_tag};
                                vstate = allocate;
                                vlru = 1'b0;
                            end
                        end
                    end else begin
                        fifo.req_en = 1'b1;
                        if(tag1_dirty) begin
                            fifo.req.addr = {1'b0, tag1, req_index, 3'b0};
                            fifo.req.cmd = 1'b0;
                            fifo.req.data = data1_read;
                            if(fifo.req_rdy) begin
                                tag1_req_we = 1'b1;
                                tag1_write = {~req_wr, req_tag};
                                vstate = write_back;
                                vlru = 1'b1;
                            end
                        end else begin
                            if(fifo.req_rdy) begin
                                tag1_req_we = 1'b1;
                                tag1_write = {~req_wr, req_tag};
                                vstate = allocate;
                                vlru = 1'b1;
                            end
                        end
                    end
                end
            end
            allocate: begin
                if(rlru) begin
                    if(fifo.rsp_en) begin
                        vstate = compare_tag;
                        data1_write = fifo.rsp.data;
                        data1_req_we = 1'b1;
                    end
                end else begin
                    if(fifo.rsp_en) begin
                        vstate = compare_tag;
                        data0_write = fifo.rsp.data;
                        data0_req_we = 1'b1;
                    end
                end
            end
            write_back: begin
                fifo.req_en = 1'b1;
                fifo.req.cmd = 1'b1;
                if(fifo.req_rdy) begin
                    vstate = allocate;
                end
            end
            default: begin
            end
        endcase
    end

    dm_cache_tag ctag0(
        .clk(clk),
        .index(tag_req_index),
        .we(tag0_req_we),
        .tag_write(tag0_write),
        .tag_read(tag0_read)
    );

    dm_cache_tag ctag1(
        .clk(clk),
        .index(tag_req_index),
        .we(tag1_req_we),
        .tag_write(tag1_write),
        .tag_read(tag1_read)
    );

    dm_cache_data cdata0(
        .clk(clk),
        .index(data_req_index),
        .we(data0_req_we),
        .data_write(data0_write),
        .data_read(data0_read)
    );

    dm_cache_data cdata1(
        .clk(clk),
        .index(data_req_index),
        .we(data1_req_we),
        .data_write(data1_write),
        .data_read(data1_read)
    );
endmodule