//! Spinning ASCII donut in Zig.
//!
//! Port of Andy Sloane's classic donut.c. The idea:
//!   1. Take a circle (the tube's cross-section).
//!   2. Sweep it around the y-axis to make a torus (donut).
//!   3. Spin the whole donut around the x-axis (angle a) and z-axis (angle b).
//!   4. Project each point to the 2D terminal, keeping the nearest point per
//!      cell with a depth buffer, and shade it by how much it faces the light.
//!
//! Run with:  zig run donut.zig   (press Ctrl-C to stop)

const std = @import("std");

pub fn main() void {
    const width = 90;
    const height = 40;
    const fwidth: f32 = width;
    const fheight: f32 = height;

    // How finely we walk around the two circles. Smaller = denser/slower.
    const theta_spacing: f32 = 0.07; // around the tube
    const phi_spacing: f32 = 0.02; // around the torus

    const R1: f32 = 1.0; // radius of the tube
    const R2: f32 = 2.0; // distance from donut center to tube center
    const K2: f32 = 5.0; // distance from the viewer to the donut
    // Projection scale, picked so the donut fills a good chunk of the screen.
    const K1: f32 = fwidth * K2 * 3.0 / (8.0 * (R1 + R2));

    const two_pi: f32 = 2.0 * std.math.pi;
    const lum = ".,-~:;=!*#$@"; // 12 brightness levels, dim -> bright

    var a: f32 = 0.0; // rotation about the x-axis
    var b: f32 = 0.0; // rotation about the z-axis

    std.debug.print("\x1b[2J\x1b[H", .{});
    while (true) {
        var chars: [height * width]u8 = undefined;
        var zbuf: [height * width]f32 = undefined;
        @memset(chars[0..], ' ');
        @memset(zbuf[0..], 0.0);

        const cosA = std.math.cos(a);
        const sinA = std.math.sin(a);
        const cosB = std.math.cos(b);
        const sinB = std.math.sin(b);

        var theta: f32 = 0.0;
        while (theta < two_pi) : (theta += theta_spacing) {
            const costheta = std.math.cos(theta);
            const sintheta = std.math.sin(theta);

            var phi: f32 = 0.0;
            while (phi < two_pi) : (phi += phi_spacing) {
                const cosphi = std.math.cos(phi);
                const sinphi = std.math.sin(phi);

                // A point on the tube's circle.
                const circlex = R2 + R1 * costheta;
                const circley = R1 * sintheta;

                // Its 3D position after the two rotations.
                const x = circlex * (cosB * cosphi + sinA * sinB * sinphi) - circley * cosA * sinB;
                const y = circlex * (sinB * cosphi - sinA * cosB * sinphi) + circley * cosA * cosB;
                const z = K2 + cosA * circlex * sinphi + circley * sinA;
                const ooz = 1.0 / z; // one-over-z: bigger = closer to viewer

                // Project to screen cell coordinates.
                const xpf = fwidth / 2.0 + K1 * ooz * x;
                const ypf = fheight / 2.0 - K1 * ooz * y * 0.5;
                const xp: i32 = @intFromFloat(xpf);
                const yp: i32 = @intFromFloat(ypf);

                // Luminance: surface normal dotted with the light direction.
                const L = cosphi * costheta * sinB - cosA * costheta * sinphi - sinA * sintheta + cosB * (cosA * sintheta - costheta * sinA * sinphi);

                if (xp >= 0 and xp < width and yp >= 0 and yp < height) {
                    const idx: usize = @as(usize, @intCast(yp)) * width + @as(usize, @intCast(xp));
                    // Only draw if this point is nearer than what's already there.
                    if (ooz > zbuf[idx]) {
                        zbuf[idx] = ooz;
                        var li: i32 = 0;
                        if (L > 0) li = @intFromFloat(L * 8.0);
                        if (li < 0) li = 0;
                        if (li > 11) li = 11;
                        chars[idx] = lum[@as(usize, @intCast(li))];
                    }
                }
            }
        }

        // Build one frame string (each row followed by a newline).
        var frame: [height * (width + 1)]u8 = undefined;
        var fi: usize = 0;
        var row: usize = 0;
        while (row < height) : (row += 1) {
            var col: usize = 0;
            while (col < width) : (col += 1) {
                frame[fi] = chars[row * width + col];
                fi += 1;
            }
            frame[fi] = '\n';
            fi += 1;
        }

        // "\x1b[H" moves the cursor home so each frame overwrites the previous.
        std.debug.print("\x1b[H{s}", .{frame[0..]});

        a += 0.04;
        b += 0.02;

        // ~60 fps. If your Zig build rejects this line, swap it for:
        //   std.time.sleep(16 * std.time.ns_per_ms);
        var ts: std.posix.timespec = .{ .sec = 0, .nsec = 16_000_000 };
        _ = std.posix.system.nanosleep(&ts, &ts);
    }
}
