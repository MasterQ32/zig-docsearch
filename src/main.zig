const std = @import("std");
const states = @import("state.zig");
const build_map = @import("build_map.zig");
const searches = @import("search.zig");
const htmlgen = @import("htmlgen.zig");

const State = states.State;
const OutError = std.fs.File.ReadError;
const InError = std.fs.File.WriteError;

fn loadState(state_path: []const u8, state: *State) !void {
    var path = try std.fs.path.resolve(
        state.allocator,
        &[_][]const u8{state_path},
    );

    var state_file = try std.fs.File.openRead(path);
    defer state_file.close();
    var in = state_file.inStream();
    var stream = &in.stream;
    var deserial = std.io.Deserializer(.Big, .Bit, OutError).init(stream);

    try deserial.deserializeInto(state);
}

fn doSearch(state: *State, search_term: []u8) !void {
    try searches.doSearch(state, search_term);
}

fn doBuild(state_path: []const u8, state: *State, zig_std_path: []u8) !void {
    try build_map.build(state, "std", zig_std_path);
    std.debug.warn("build finished, {} total defs\n", .{state.map.size});

    var state_file = try std.fs.File.openWrite(try std.fs.path.resolve(
        state.allocator,
        &[_][]const u8{state_path},
    ));
    defer state_file.close();

    var out = state_file.outStream();
    var stream = &out.stream;
    var serial = std.io.Serializer(.Big, .Bit, InError).init(stream);

    try state.serialize(&serial);
    std.debug.warn("serialization OK\n", .{});
}

pub fn main() anyerror!void {
    var allocator = std.heap.direct_allocator;
    var state = State.init(allocator);
    defer state.deinit();

    var args_it = std.process.args();
    if (!args_it.skip()) @panic("expected self arg");

    const state_path = try (args_it.next(allocator) orelse @panic("expected state.bin file path"));
    const action = try (args_it.next(allocator) orelse @panic("expected action arg"));

    if (std.mem.eql(u8, action, "build")) {
        const zig_std_path = try (args_it.next(allocator) orelse @panic("expected zig stdlib path arg"));

        try doBuild(state_path, &state, zig_std_path);
    } else if (std.mem.eql(u8, action, "search")) {
        const search_term = try (args_it.next(allocator) orelse @panic("expected search term arg"));

        try loadState(state_path, &state);
        try doSearch(&state, search_term);
    } else if (std.mem.eql(u8, action, "htmlgen")) {
        const out_path = try (args_it.next(allocator) orelse @panic("expected out path arg"));

        try loadState(state_path, &state);
        try htmlgen.genHtml(&state, out_path);
    } else {
        @panic("invalid action");
    }
}
