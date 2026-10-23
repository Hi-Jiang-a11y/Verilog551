# Synchronous FIFO Guide

## What is this?

This project implements a **synchronous FIFO** (First-In, First-Out) buffer in SystemVerilog.
A FIFO stores data in the order it arrives: the first item written is the first item read.
It is commonly used to transfer data between parts of a digital system that operate at the same clock rate.

The FIFO has a configurable data width and depth. By default, it stores 16 entries, with each entry 8 bits wide.

## Files

- `sync_fifo.sv` — The synthesizable FIFO design.
- `tb_sync_fifo.sv` — A simulation testbench that checks the design.

## Interface

| Signal | Direction | Description |
|---|---|---|
| `clk` | input | Clock. All reads and writes happen on its rising edge. |
| `rst_n` | input | Asynchronous active-low reset. Set to `0` to clear the FIFO. |
| `wr_en` | input | Requests a write of `wr_data`. |
| `wr_data` | input | Data to write. |
| `rd_en` | input | Requests a read. |
| `rd_data` | output | Most recently read data. |
| `full` | output | High when the FIFO contains `DEPTH` entries. |
| `empty` | output | High when the FIFO contains no entries. |
| `count` | output | Number of entries currently stored. |
| `overflow` | output | One-clock pulse when a write is rejected because the FIFO is full. |
| `underflow` | output | One-clock pulse when a read is requested while the FIFO is empty. |

## How it behaves

### Write

A write is accepted on a rising clock edge when `wr_en` is high and the FIFO has space.
The data is placed at the write pointer, and the entry count increases by one.

### Read

A read is accepted on a rising clock edge when `rd_en` is high and the FIFO is not empty.
The oldest entry is placed on `rd_data`, and the entry count decreases by one.

### Full and empty cases

- A write while full is rejected and produces a one-clock `overflow` pulse.
- A read while empty is rejected and produces a one-clock `underflow` pulse.
- A simultaneous read and write while full is allowed. The read frees a slot, so the new write is accepted.
- A simultaneous read and write while empty performs the write, but the read is rejected because there was no old entry to read.

The FIFO uses circular pointers. When a pointer reaches the last storage entry, it wraps back to entry zero.

## Reset behavior

When `rst_n` is driven low:

- The read and write pointers are cleared.
- `count` becomes zero.
- `empty` becomes high and `full` becomes low.
- `rd_data`, `overflow`, and `underflow` are cleared.

## Parameters

The module can be customized when instantiated:

```systemverilog
sync_fifo #(
    .WIDTH(8),
    .DEPTH(16)
) fifo_inst (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .rd_en(rd_en),
    .rd_data(rd_data),
    .full(full),
    .empty(empty),
    .count(count),
    .overflow(overflow),
    .underflow(underflow)
);
```

`DEPTH` should be a power of two and at least 2. `WIDTH` controls the number of bits in each stored data item.

## Running the testbench

Using Icarus Verilog:

```bash
iverilog -g2012 -gno-assertions -s tb_sync_fifo \
  -o /tmp/tb_fifo tb_sync_fifo.sv sync_fifo.sv
vvp /tmp/tb_fifo
```

The testbench checks reset, normal writes and reads, full and empty operation, overflow and underflow, simultaneous operations, and randomized traffic. A successful run ends with:

```text
RESULT: PASS
```
