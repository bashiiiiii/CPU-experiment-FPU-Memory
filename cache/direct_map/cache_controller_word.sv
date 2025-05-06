module dm_cache_data#(
    parameter Indexwidth = 12,
    parameter Lines = 4096
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
    parameter Indexwidth = 12,
    parameter Lines = 4096,
    parameter Tagwidth = 11
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
    parameter Tagwidth = 11, // Addresswidth - Indexwidth - Offsetwidth
    parameter Indexwidth = 12,
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
    localparam idle        = 2'd0;
    localparam compare_tag = 2'd1;
    localparam allocate    = 2'd2;
    localparam write_back  = 2'd3;

    logic [1:0] vstate;
    logic [1:0] rstate = idle;

    logic [Addresswidth-1:0] save_addr;
    logic [31:0] save_data;
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
    logic [Tagwidth-1:0] req_tag;
    logic [Indexwidth-1:0] req_index;
    logic [Offsetwidth-1:0] req_offset;
    logic [31:0] req_data;
    logic req_wr;

    assign req_addr = (rstate == idle && req_valid) ? addr : save_addr;
    assign req_tag = req_addr[Addresswidth-1:Indexwidth+Offsetwidth];
    assign req_index = req_addr[Indexwidth+Offsetwidth-1:Offsetwidth];
    assign req_offset = req_addr[Offsetwidth-1:0];
    assign req_data = (rstate == idle && req_valid) ? data : save_data;
    assign req_wr = (rstate == idle && req_valid) ? wr : save_wr;
    
    assign req_ready = (rstate == idle);

    logic [Tagwidth+2:0] tag_read;
    logic [Tagwidth+2:0] tag_write;
    logic [Indexwidth-1:0] tag_req_index;
    logic tag_req_we;
    logic tag_valid;
    logic tag_dirty;
    logic tag_accessed;
    logic [Tagwidth-1:0] tag;

    assign {tag_valid, tag_dirty, tag_accessed, tag} = tag_read;

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
        tag_req_index = req_index;

        data_req_we = '0;
        data_req_index = req_index;

        data_write = data_read;
        case(req_offset)
            2'b00: data_write[31:0] = req_data;
            2'b01: data_write[63:32] = req_data;
            2'b10: data_write[95:64] = req_data;
            2'b11: data_write[127:96] = req_data;
        endcase

        case(req_addr[Offsetwidth-1:0])
            2'b00: rsp_data = data_read[31:0];
            2'b01: rsp_data = data_read[63:32];
            2'b10: rsp_data = data_read[95:64];
            2'b11: rsp_data = data_read[127:96];
        endcase

        fifo.clk = clk;
        fifo.req.addr = {1'b0, req_tag, req_index, 3'b0};
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
                if(req_tag == tag && tag_valid) begin
                    if(~req_wr) begin
                        tag_req_we = 1'b1;
                        data_req_we = 1'b1;
                        tag_write = {3'b111, tag};
                    end else begin
                        rsp_valid = 1'b1;
                    end
                    vstate = idle;
                end else begin
                    fifo.req_en = 1'b1;
                    if(~tag_valid || ~tag_dirty) begin
                        if(fifo.req_rdy) begin
                            tag_req_we = 1'b1;
                            tag_write = {1'b1, ~req_wr, 1'b1, req_tag};
                            vstate = allocate;
                        end
                    end else begin
                        fifo.req.addr = {1'b0, tag, req_index, 3'b0};
                        fifo.req.cmd = 1'b0;
                        if(fifo.req_rdy) begin
                            tag_req_we = 1'b1;
                            tag_write = {1'b1, ~req_wr, 1'b1, req_tag};
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