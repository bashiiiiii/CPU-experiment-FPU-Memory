module dm_cache_data#(
    parameter Indexwidth = 12,
    parameter Lines = 4096
)(
    input wire clk,
    input wire [Indexwidth-1:0] write_index,
    input wire [Indexwidth-1:0] read_index,
    input wire we,
    input wire all,
    input wire [1:0] offset,
    input wire [31:0] data_write0,
    input wire [31:0] data_write1,
    input wire [31:0] data_write2,
    input wire [31:0] data_write3,
    output logic [31:0] data_read0,
    output logic [31:0] data_read1,
    output logic [31:0] data_read2,
    output logic [31:0] data_read3
);
    (*ram_style = "BLOCK"*) reg [31:0] data_mem0 [0:2**Indexwidth-1];
    (*ram_style = "BLOCK"*) reg [31:0] data_mem1 [0:2**Indexwidth-1];
    (*ram_style = "BLOCK"*) reg [31:0] data_mem2 [0:2**Indexwidth-1];
    (*ram_style = "BLOCK"*) reg [31:0] data_mem3 [0:2**Indexwidth-1];

    integer i;
    initial begin
        for (i = 0; i < Lines; i = i + 1) begin
            data_mem0[i] = '0;
            data_mem1[i] = '0;
            data_mem2[i] = '0;
            data_mem3[i] = '0;
        end
    end
    reg [31:0] write0, write1, write2, write3;
    reg [31:0] read0, read1, read2, read3;
    reg same0, same1, same2, same3;

    assign data_read0 = same0 ? write0 : read0;
    assign data_read1 = same1 ? write1 : read1;
    assign data_read2 = same2 ? write2 : read2;
    assign data_read3 = same3 ? write3 : read3;

    always_ff @ (posedge clk) begin
        write0 <= data_write0;
        write1 <= data_write1;
        write2 <= data_write2;
        write3 <= data_write3;
        same0 <= we && (all || (offset === 2'b00)) && (write_index === read_index);
        same1 <= we && (all || (offset === 2'b01)) && (write_index === read_index);
        same2 <= we && (all || (offset === 2'b10)) && (write_index === read_index);
        same3 <= we && (all || (offset === 2'b11)) && (write_index === read_index);

        if (we && (all || (offset === 2'b00))) begin
            data_mem0[write_index] <= data_write0;
        end
        if (we && (all || (offset === 2'b01))) begin
            data_mem1[write_index] <= data_write1;
        end
        if (we && (all || (offset === 2'b10))) begin
            data_mem2[write_index] <= data_write2;
        end
        if (we && (all || (offset === 2'b11))) begin
            data_mem3[write_index] <= data_write3;
        end
        
        read0 <= data_mem0[read_index];
        read1 <= data_mem1[read_index];
        read2 <= data_mem2[read_index];
        read3 <= data_mem3[read_index];
    end
endmodule

module dm_cache_tag#(
    parameter Indexwidth = 12,
    parameter Lines = 4096,
    parameter Tagwidth = 6
)(
    input wire clk,
    input wire [Indexwidth-1:0] write_index,
    input wire [Indexwidth-1:0] read_index,
    input wire we,
    input wire [Tagwidth+1:0] tag_write,
    output logic [Tagwidth+1:0] tag_read
);
    (*ram_style = "BLOCK"*) reg [Tagwidth+1:0] tag_mem [0:2**Indexwidth-1];
    integer i;
    initial begin
        for (i = 0; i < Lines; i = i + 1) begin
            tag_mem[i] = '0;
        end
    end

    reg [Tagwidth+1:0] write;
    reg [Tagwidth+1:0] read;
    reg same;

    assign tag_read = same ? write : read;

    always_ff @ (posedge clk) begin
        write <= tag_write;
        same <= we && (write_index === read_index);
        if (we) begin
            tag_mem[write_index] <= tag_write;
        end
        read <= tag_mem[read_index];
    end
endmodule

module cache_controller#(
    parameter Addresswidth = 25,
    parameter Tagwidth = 6, // Addresswidth - Indexwidth - Offsetwidth
    parameter Indexwidth = 12,
    parameter Offsetwidth = 2,
    parameter Lines = 4096
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

    logic [Addresswidth-1:0] snd_addr;
    logic [31:0] snd_data;
    logic snd_wr;

    logic [1:0] rcount = '0;

    logic [Addresswidth-1:0] save_addr;
    logic [31:0] save_data;
    logic save_wr;

    assign snd_addr = req_valid ? addr : save_addr;
    assign snd_data = req_valid ? data : save_data;
    assign snd_wr = req_valid ? wr : save_wr;

    assign req_ready = (rcount != 2'd2);

    localparam idle        = 2'b00;
    localparam compare_tag = 2'b01;
    localparam allocate    = 2'b10;
    localparam write_back  = 2'b11;

    logic [1:0] rstate = idle;

    logic [1:0] rlru = '0;

    logic [Addresswidth-1:0] req_addr;
    logic [Tagwidth-1:0] req_tag;
    logic [Indexwidth-1:0] req_index;
    logic [Offsetwidth-1:0] req_offset;
    logic [31:0] req_data;
    logic req_wr;

    logic [Tagwidth+1:0] tag0_read, tag1_read, tag2_read, tag3_read;
    logic [Tagwidth+1:0] tag0_write, tag1_write, tag2_write, tag3_write;
    logic [Tagwidth-1:0] tag0, tag1, tag2, tag3;
    logic tag0_dirty, tag1_dirty, tag2_dirty, tag3_dirty;
    logic tag0_accessed, tag1_accessed, tag2_accessed, tag3_accessed;
    logic [Indexwidth-1:0] next_index;
    logic tag0_req_we, tag1_req_we, tag2_req_we, tag3_req_we;

    assign {tag0_dirty, tag0_accessed, tag0} = tag0_read;
    assign {tag1_dirty, tag1_accessed, tag1} = tag1_read;
    assign {tag2_dirty, tag2_accessed, tag2} = tag2_read;
    assign {tag3_dirty, tag3_accessed, tag3} = tag3_read;

    logic hit;
    assign hit = (req_tag == tag0 || req_tag == tag1 || req_tag == tag2 || req_tag == tag3);

    always_ff @ (posedge clk) begin
        if(req_valid) begin
            save_addr <= addr;
            save_data <= data;
            save_wr <= wr;
        end

        if(rstate == idle) begin
            if(req_valid) begin
                rcount <= rcount+2'b1;
                rstate <= compare_tag;
                req_addr <= addr;
                req_data <= data;
                req_wr <= wr;
            end
        end else if (rstate == compare_tag) begin
            if(hit) begin
                req_addr <= snd_addr;
                req_data <= snd_data;
                req_wr <= snd_wr;
                if(~req_valid) begin
                    rcount <= rcount - 2'b1;
                    if(rcount == 2'b1) begin
                        rstate <= idle;
                    end
                end
            end else begin
                if(req_valid) begin
                    rcount <= rcount + 2'b1;
                end
                if(~tag0_accessed) begin
                    if(tag0_dirty) begin
                        rstate <= write_back;
                        rlru <= 2'd0;
                    end else begin
                        rstate <= allocate;
                        rlru <= 2'b00;
                    end
                end else if(~tag1_accessed) begin
                    if(tag1_dirty) begin
                        rstate <= write_back;
                        rlru <= 2'd1;
                    end else begin
                        rstate <= allocate;
                        rlru <= 2'd1;
                    end
                end else if(~tag2_accessed) begin
                    if(tag2_dirty) begin
                        rstate <= write_back;
                        rlru <= 2'd2;
                    end else begin
                        rstate <= allocate;
                        rlru <= 2'd2;
                    end
                end else begin
                    if(tag3_dirty) begin
                        rstate <= write_back;
                        rlru <= 2'd3;
                    end else begin
                        rstate <= allocate;
                        rlru <= 2'd3;
                    end
                end
            end
        end else if(rstate == allocate) begin
            if(req_valid) begin
                rcount <= rcount + 2'b1;
            end
            if(fifo.rsp_en) begin
                rstate <= compare_tag;
            end
        end else if(rstate == write_back) begin 
            if(req_valid) begin
                rcount <= rcount + 2'b1;
            end
            if(fifo.req_rdy) begin
                rstate <= allocate;
            end
        end
    end

    assign req_tag = req_addr[Addresswidth-6:Indexwidth+Offsetwidth];
    assign req_index = req_addr[Indexwidth+Offsetwidth-1:Offsetwidth];
    assign req_offset = req_addr[Offsetwidth-1:0];

    logic [31:0] data0_read0, data0_read1, data0_read2, data0_read3;
    logic [31:0] data1_read0, data1_read1, data1_read2, data1_read3;
    logic [31:0] data2_read0, data2_read1, data2_read2, data2_read3;
    logic [31:0] data3_read0, data3_read1, data3_read2, data3_read3;

    logic [31:0] data0_write0, data0_write1, data0_write2, data0_write3;
    logic [31:0] data1_write0, data1_write1, data1_write2, data1_write3;
    logic [31:0] data2_write0, data2_write1, data2_write2, data2_write3;
    logic [31:0] data3_write0, data3_write1, data3_write2, data3_write3;
    
    logic data0_req_we, data1_req_we, data2_req_we, data3_req_we;
    logic all0, all1, all2, all3;

    assign fifo.clk = clk;
    assign fifo.rsp_rdy = 1'b1;

    assign tag0_req_we = (rstate == compare_tag) && 
                         ((req_tag == tag0) ? ~req_wr :
                         (req_tag == tag1) ? ~req_wr && tag0_accessed && tag2_accessed && tag3_accessed :
                         (req_tag == tag2) ? ~req_wr && tag0_accessed && tag1_accessed && tag3_accessed :
                         (req_tag == tag3) ? ~req_wr && tag0_accessed && tag1_accessed && tag2_accessed :
                          ~tag0_accessed && fifo.req_rdy);
    assign tag1_req_we = (rstate == compare_tag) && 
                         ((req_tag == tag0) ? ~req_wr && tag1_accessed && tag2_accessed && tag3_accessed :
                         (req_tag == tag1) ? ~req_wr :
                         (req_tag == tag2) ? ~req_wr && tag0_accessed && tag1_accessed && tag3_accessed :
                         (req_tag == tag3) ? ~req_wr && tag0_accessed && tag1_accessed && tag2_accessed :
                          tag0_accessed && ~tag1_accessed && fifo.req_rdy);
    assign tag2_req_we = (rstate == compare_tag) && 
                         ((req_tag == tag0) ? ~req_wr && tag1_accessed && tag2_accessed && tag3_accessed :
                         (req_tag == tag1) ? ~req_wr && tag0_accessed && tag2_accessed && tag3_accessed:
                         (req_tag == tag2) ? ~req_wr :
                         (req_tag == tag3) ? ~req_wr && tag0_accessed && tag1_accessed && tag2_accessed :
                          tag0_accessed && tag1_accessed && ~tag2_accessed && fifo.req_rdy);
    assign tag3_req_we = (rstate == compare_tag) && 
                         ((req_tag == tag0) ? ~req_wr && tag1_accessed && tag2_accessed && tag3_accessed :
                         (req_tag == tag1) ? ~req_wr && tag0_accessed && tag2_accessed && tag3_accessed:
                         (req_tag == tag2) ? ~req_wr && tag0_accessed && tag1_accessed && tag3_accessed :
                         (req_tag == tag3) ? ~req_wr :
                          tag0_accessed && tag1_accessed && tag2_accessed && fifo.req_rdy);

    assign tag0_write = req_tag == tag0 ? {2'b11, tag0} :
                        (req_tag == tag1 || req_tag == tag2 || req_tag == tag3) ? {tag0_dirty, 1'b0, tag0} :
                        {~req_wr, 1'b1, req_tag};
    assign tag1_write = req_tag == tag0 ? {tag1_dirty, 1'b0, tag1} :
                        req_tag == tag1 ? {2'b11, tag1} :
                        (req_tag == tag2 || req_tag == tag3) ? {tag1_dirty, 1'b0, tag1} :
                        {~req_wr, 1'b1, req_tag};
    assign tag2_write = (req_tag == tag0 || req_tag == tag1) ? {tag2_dirty, 1'b0, tag2} :
                        req_tag == tag2 ? {2'b11, tag2} :
                        req_tag == tag3 ? {tag2_dirty, 1'b0, tag2} :
                        {~req_wr, 1'b1, req_tag};
    assign tag3_write = (req_tag == tag0 || req_tag == tag1 || req_tag == tag2) ? {tag3_dirty, 1'b0, tag3} :
                        req_tag == tag3 ? {2'b11, tag3} :
                        {~req_wr, 1'b1, req_tag};

    assign rsp_valid = (rstate == compare_tag) && (req_wr) && hit;

    assign next_index = (rstate == idle || (rstate == compare_tag && hit)) ? snd_addr[Indexwidth+Offsetwidth-1:Offsetwidth] : req_index;

    always_comb begin
        rsp_data = '0;

        case(req_offset)
            2'b00: begin
                if(req_tag === tag0) begin
                    rsp_data = data0_read0;
                end else if(req_tag === tag1) begin
                    rsp_data = data1_read0;
                end else if(req_tag === tag2) begin
                    rsp_data = data2_read0;
                end else if(req_tag === tag3) begin
                    rsp_data = data3_read0;
                end
            end
            2'b01: begin
                if(req_tag === tag0) begin
                    rsp_data = data0_read1;
                end else if(req_tag === tag1) begin
                    rsp_data = data1_read1;
                end else if(req_tag === tag2) begin
                    rsp_data = data2_read1;
                end else if(req_tag === tag3) begin
                    rsp_data = data3_read1;
                end
            end
            2'b10: begin
                if(req_tag === tag0) begin
                    rsp_data = data0_read2;
                end else if(req_tag === tag1) begin
                    rsp_data = data1_read2;
                end else if(req_tag === tag2) begin
                    rsp_data = data2_read2;
                end else if(req_tag === tag3) begin
                    rsp_data = data3_read2;
                end
            end
            2'b11: begin
                if(req_tag === tag0) begin
                    rsp_data = data0_read3;
                end else if(req_tag === tag1) begin
                    rsp_data = data1_read3;
                end else if(req_tag === tag2) begin
                    rsp_data = data2_read3;
                end else if(req_tag === tag3) begin
                    rsp_data = data3_read3;
                end
            end
        endcase

        data0_req_we = '0;
        data1_req_we = '0;
        data2_req_we = '0;
        data3_req_we = '0;

        all0 = '0;
        all1 = '0;
        all2 = '0;
        all3 = '0;

        data0_write0 = req_data;
        data0_write1 = req_data;
        data0_write2 = req_data;
        data0_write3 = req_data;

        data1_write0 = req_data;
        data1_write1 = req_data;
        data1_write2 = req_data;
        data1_write3 = req_data;

        data2_write0 = req_data;
        data2_write1 = req_data;
        data2_write2 = req_data;
        data2_write3 = req_data;

        data3_write0 = req_data;
        data3_write1 = req_data;
        data3_write2 = req_data;
        data3_write3 = req_data;

        fifo.req.addr = {6'b0, req_tag, req_index, 3'b0};
        fifo.req.data = '0;
        fifo.req.cmd = '1;
        fifo.req_en = '0;

        case(rstate)
            idle: begin
            end
            compare_tag: begin
                if(req_tag === tag0) begin
                    if(~req_wr) begin
                        data0_req_we = 1'b1;
                    end
                end else if(req_tag === tag1) begin
                    if(~req_wr) begin
                        data1_req_we = 1'b1;
                    end
                end else if(req_tag === tag2) begin
                    if(~req_wr) begin
                        data2_req_we = 1'b1;
                    end
                end else if(req_tag === tag3) begin
                    if(~req_wr) begin
                        data3_req_we = 1'b1;
                    end
                end else begin
                    if(~tag0_accessed) begin
                        fifo.req_en = 1'b1;
                        if(tag0_dirty) begin
                            fifo.req.addr = {6'b0, tag0, req_index, 3'b0};
                            fifo.req.cmd = 1'b0;
                            fifo.req.data = {data0_read3, data0_read2, data0_read1, data0_read0};
                        end
                    end else if(~tag1_accessed) begin
                        fifo.req_en = 1'b1;
                        if(tag1_dirty) begin
                            fifo.req.addr = {6'b0, tag1, req_index, 3'b0};
                            fifo.req.cmd = 1'b0;
                            fifo.req.data = {data1_read3, data1_read2, data1_read1, data1_read0};
                        end
                    end else if(~tag2_accessed) begin
                        fifo.req_en = 1'b1;
                        if(tag2_dirty) begin
                            fifo.req.addr = {6'b0, tag2, req_index, 3'b0};
                            fifo.req.cmd = 1'b0;
                            fifo.req.data = {data2_read3, data2_read2, data2_read1, data2_read0};
                        end
                    end else begin
                        fifo.req_en = 1'b1;
                        if(tag3_dirty) begin
                            fifo.req.addr = {6'b0, tag3, req_index, 3'b0};
                            fifo.req.cmd = 1'b0;
                            fifo.req.data = {data3_read3, data3_read2, data3_read1, data3_read0};
                        end
                    end
                end
            end
            allocate: begin
                case(rlru)
                    2'b00: begin
                        if(fifo.rsp_en) begin
                            data0_write0 = fifo.rsp.data[31:0];
                            data0_write1 = fifo.rsp.data[63:32];
                            data0_write2 = fifo.rsp.data[95:64];
                            data0_write3 = fifo.rsp.data[127:96];
                            data0_req_we = 1'b1;
                            all0 = 1'b1;
                        end
                    end
                    2'b01: begin
                        if(fifo.rsp_en) begin
                            data1_write0 = fifo.rsp.data[31:0];
                            data1_write1 = fifo.rsp.data[63:32];
                            data1_write2 = fifo.rsp.data[95:64];
                            data1_write3 = fifo.rsp.data[127:96];
                            data1_req_we = 1'b1;
                            all1 = 1'b1;
                        end
                    end
                    2'b10: begin
                        if(fifo.rsp_en) begin
                            data2_write0 = fifo.rsp.data[31:0];
                            data2_write1 = fifo.rsp.data[63:32];
                            data2_write2 = fifo.rsp.data[95:64];
                            data2_write3 = fifo.rsp.data[127:96];
                            data2_req_we = 1'b1;
                            all2 = 1'b1;
                        end
                    end
                    2'b11: begin
                        if(fifo.rsp_en) begin
                            data3_write0 = fifo.rsp.data[31:0];
                            data3_write1 = fifo.rsp.data[63:32];
                            data3_write2 = fifo.rsp.data[95:64];
                            data3_write3 = fifo.rsp.data[127:96];
                            data3_req_we = 1'b1;
                            all3 = 1'b1;
                        end
                    end
                endcase
            end
            write_back: begin
                fifo.req_en = 1'b1;
            end
            default: begin
            end
        endcase
    end

    dm_cache_tag ctag0(
        .clk(clk),
        .write_index(req_index),
        .read_index(next_index),
        .we(tag0_req_we),
        .tag_write(tag0_write),
        .tag_read(tag0_read)
    );

    dm_cache_tag ctag1(
        .clk(clk),
        .write_index(req_index),
        .read_index(next_index),
        .we(tag1_req_we),
        .tag_write(tag1_write),
        .tag_read(tag1_read)
    );

    dm_cache_tag ctag2(
        .clk(clk),
        .write_index(req_index),
        .read_index(next_index),
        .we(tag2_req_we),
        .tag_write(tag2_write),
        .tag_read(tag2_read)
    );

    dm_cache_tag ctag3(
        .clk(clk),
        .write_index(req_index),
        .read_index(next_index),
        .we(tag3_req_we),
        .tag_write(tag3_write),
        .tag_read(tag3_read)
    );

    dm_cache_data cdata0(
        .clk(clk),
        .write_index(req_index),
        .read_index(next_index),
        .we(data0_req_we),
        .all(all0),
        .offset(req_offset),
        .data_write0(data0_write0),
        .data_write1(data0_write1),
        .data_write2(data0_write2),
        .data_write3(data0_write3),
        .data_read0(data0_read0),
        .data_read1(data0_read1),
        .data_read2(data0_read2),
        .data_read3(data0_read3)
    );

    dm_cache_data cdata1(
        .clk(clk),
        .write_index(req_index),
        .read_index(next_index),
        .we(data1_req_we),
        .all(all1),
        .offset(req_offset),
        .data_write0(data1_write0),
        .data_write1(data1_write1),
        .data_write2(data1_write2),
        .data_write3(data1_write3),
        .data_read0(data1_read0),
        .data_read1(data1_read1),
        .data_read2(data1_read2),
        .data_read3(data1_read3)
    );

    dm_cache_data cdata2(
        .clk(clk),
        .write_index(req_index),
        .read_index(next_index),
        .we(data2_req_we),
        .all(all2),
        .offset(req_offset),
        .data_write0(data2_write0),
        .data_write1(data2_write1),
        .data_write2(data2_write2),
        .data_write3(data2_write3),
        .data_read0(data2_read0),
        .data_read1(data2_read1),
        .data_read2(data2_read2),
        .data_read3(data2_read3)
    );

    dm_cache_data cdata3(
        .clk(clk),
        .write_index(req_index),
        .read_index(next_index),
        .we(data3_req_we),
        .all(all3),
        .offset(req_offset),
        .data_write0(data3_write0),
        .data_write1(data3_write1),
        .data_write2(data3_write2),
        .data_write3(data3_write3),
        .data_read0(data3_read0),
        .data_read1(data3_read1),
        .data_read2(data3_read2),
        .data_read3(data3_read3)
    );
endmodule