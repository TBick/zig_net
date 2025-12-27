const std = @import("std");
const net = std.net;


pub fn main() !void {

    //Start program
    //Initiate GPA
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    //Parse arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if(args.len < 3) {
        std.debug.print("Usage: {s} <ip> <port>\n", .{args[0]});
        return;
    }

    const ip = args[1];
    const port = try std.fmt.parseInt(u16, args[2], 10);
    
    std.debug.print("Starting network test...\n", .{});
    std.debug.print("Connecting to {s}:{d}\n", .{ip, port});
    
    const address = try net.Address.parseIp(ip, port);


    const stream = try std.net.tcpConnectToAddress(address);
    defer stream.close();

    std.debug.print("Connected!\n", .{});

    const request = "GET / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n";
    _ = try stream.write(request);

    std.debug.print("Request Sent, reading response... \n\n", .{});

    var buffer: [4096]u8 = undefined;
    const bytes_read = try stream.read(&buffer);

    std.debug.print("Received {d} bytes:\n{s}\n", .{ bytes_read, buffer[0..bytes_read] });




}

