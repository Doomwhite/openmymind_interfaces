const std = @import("std");
const os = std.os;

const Writer = struct {
    ptr: *anyopaque,
    writeAllFn: *const fn (ptr: *anyopaque, data: []const u8) anyerror!void,

    fn init(ptr: anytype) Writer {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);
        if (ptr_info != .Pointer) @compileError("ptr must be a pointer");
        if (ptr_info.Pointer.size != .One) @compileError("ptr must be a single item pointer");

        const gen = struct {
            pub fn writeAll(pointer: *anyopaque, data: []const u8) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return @call(.always_inline, ptr_info.Pointer.child.writeAll, .{ self, data });
            }
        };

        return .{
            .ptr = ptr,
            .writeAllFn = gen.writeAll,
        };
    }

    pub fn writeAll(self: Writer, data: []const u8) !void {
        return self.writeAllFn(self.ptr, data);
    }
};

const File = struct {
    fd: os.fd_t,

    fn writeAll(ptr: *anyopaque, data: []const u8) !void {
        const self: *File = @ptrCast(@alignCast(ptr));
        _ = try std.os.write(self.fd, data);
    }

    fn writer(self: *File) Writer {
        return Writer.init(self);
    }
};

// const Writer = union(enum) {
//     file: File,
//
//     fn writeAll(self: Writer, data: []const u8) !void {
//         switch (self) {
//             .file => |file| return file.writeAll(data),
//         }
//     }
// };
//
// const File = struct {
//     fd: os.fd_t,
//
//     fn writeAll(self: File, data: []const u8) !void {
//         _ = try std.os.write(self.fd, data);
//     }
// };

pub fn main() !void {
    var file = File{ .fd = std.io.getStdOut().handle };
    const writer = Writer.init(&file);
    try writer.writeAll("hi");
}
