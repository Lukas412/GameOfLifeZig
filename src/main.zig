const std = @import("std");
const nc = @import("notcurses.zig");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const dbg = std.debug.print;
const rand = std.rand;
const heap = std.heap;

pub fn main() !void {
    var genneral_purpose_allocator = heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_pur.allocator();

    var nc_opts: nc.notcurses_options = nc.default_notcurses_options;
    var ncs: *nc.notcurses = (nc.notcurses_core_init(&nc_opts, null) orelse @panic("notcurses_core_init() failed"));
    defer _ = nc.notcurses_stop(ncs);

    var dimy: c_uint = undefined;
    var dimx: c_uint = undefined;
    var n: *nc.ncplane = (nc.notcurses_stddim_yx(ncs, &dimy, &dimx) orelse unreachable);
    _ = n;
    dbg("{} x {}", .{dimx, dimy});

    const game = Game.init(gpa, 80, 80);

    const seed: u64 = 0;
    game.randomize(seed);

    const steps: u64 = 1000;
    for (0..steps) |step| {
        _ = step;
        game.advance();
        // std.time.sleep(1000 * 1000 * 500);
        // std.time.sleep(1000 * 1000 * 10);
    }
}

const Game = struct {
    allocator: Allocator,
    width: u64,
    height: u64,
    stateBuffer: [][]bool,
    nextBuffer: [][]bool,

    fn init(allocator: Allocator, width: u64, height: u64) Game {
        var stateBuffer = allocator.alloc(bool, width * height);
        var nextBuffer = allocator.alloc(bool, width * height);
        return .{
            .allocator = allocator,
            .width = width,
            .height = height,
            .stateBuffer = stateBuffer,
            .nextBuffer = nextBuffer,
        };
    }

    fn randomize(self: Game, seed: u64) void {
        var random_instance = rand.DefaultPrng.init(seed);
        const random = random_instance.random();
        for (0..self.width*self.height) |index| {
            var row: u64 = index / self.width;
            var column: u64 = index % self.width;
            self.stateBuffer[row][column] = random.boolean() and random.boolean();
        }
        self.nextBuffer = self.stateBuffer;
    }

    fn advance(self: Game) void {
        for (0..self.width*self.height) |index| {
            var row: u64 = index / self.width;
            var column: u64 = index % self.width;
            var prevRow: u64 = undefined;
            if (row == 0) { 
                prevRow = self.height - 1;
            } else {
                prevRow = row - 1;
            }
            var nextRow: u64 = undefined;
            if (row == self.height - 1) {
                nextRow = 0;
            } else {
                nextRow = row + 1;
            }
            var prevColumn: u64 = undefined;
            if (column == 0) {
                prevColumn = self.width - 1;
            } else {
                prevColumn = column - 1;
            }
            var nextColumn: u64 = undefined;
            if (column == self.width - 1) {
                nextColumn = 0;
            } else {
                nextColumn = column + 1;
            }
            var count: u4 = 0;
            count += boolToInt(self.stateBuffer[prevRow][prevColumn]);
            count += boolToInt(self.stateBuffer[prevRow][column]);
            count += boolToInt(self.stateBuffer[prevRow][nextColumn]);
            count += boolToInt(self.stateBuffer[row][prevColumn]);
            count += boolToInt(self.stateBuffer[row][nextColumn]);
            count += boolToInt(self.stateBuffer[nextRow][prevColumn]);
            count += boolToInt(self.stateBuffer[nextRow][column]);
            count += boolToInt(self.stateBuffer[nextRow][nextColumn]);
            var alive: bool = self.stateBuffer[row][column];
            if (alive) {
                if (count != 2 and count != 3) {
                    self.nextBuffer[row][column] = false;
                }
            } else if (count == 3) {
                self.nextBuffer[row][column] = true;
            }
        }
        self.stateBuffer = self.nextBuffer;
    }
};

inline fn boolToInt(value: bool) u1 {
    if (value) {
        return 1;
    } else {
        return 0;
    }
}
