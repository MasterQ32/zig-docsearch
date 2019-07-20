const std = @import("std");

const states = @import("state.zig");
const State = states.State;

const style = @embedFile("style.css");

fn printToc(state: *State, stream: var) !void {
    var it = state.map.iterator();
    try stream.print("<ul>");

    var buf = try state.allocator.alloc(u8, 1024);
    defer state.allocator.free(buf);

    while (it.next()) |kv| {
        const atag = try std.fmt.bufPrint(
            buf,
            "\t<a id=\"{}\" href=\"#{}\">{}</a>",
            kv.key,
            kv.key,
            kv.key,
        );

        try stream.print("\t<li>{}</li>", atag);
    }

    try stream.print("</ul>");
}

pub fn genHtml(state: *State, out_path: []const u8) !void {
    var file = try std.fs.File.openWrite(out_path);
    defer file.close();

    var out = file.outStream();
    var stream = &out.stream;

    try stream.print("<!doctype html>\n<html>\n");
    try stream.print("<head>\n<meta chatset=\"utf-8\">\n<title>zig docs</title>\n");
    try stream.print("<style type=\"text/css\">\n");
    try stream.print("{}\n", style);
    try stream.print("</style>\n");
    try stream.print("</head>\n");

    try stream.print("<body>\n");
    try stream.print("<div id=\"contents\">\n");

    try printToc(state, stream);

    try stream.print("</div>\n");
    try stream.print("</body>\n");

    try stream.print("</html>\n");

    std.debug.warn("OK\n");
}
