const rl = @import("raylib");
const std = @import("std");
const Config = @import("config.zig");
const print = std.debug.print;

const Buttons = enum {
    Move,
    Draw,
};

var ActiveButton: Buttons = .Draw;
var currentColor: [4]u8 = [_]u8{ 255, 255, 255, 255 };
var brushSize: f32 = 10;

const Button = struct {
    x: f32,
    y: f32,
    width: f32 = 40,
    height: f32 = 40,
    image_path: [:0]const u8,
};

const OptionBox = struct {
    const Self = @This();
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    MoveButton: Button,
    DrawButton: Button,
};

pub fn GetOptionBox(screenWidth: i32) OptionBox {
    const OptionBoxLeftPadding = 500;
    const OptionBoxHeight = 60;
    const START_Y = 40;

    const move = MoveButton(OptionBoxLeftPadding, START_Y, 20);
    const draw = DrawButton(OptionBoxLeftPadding + move.width + 20, START_Y, 20);

    const options = OptionBox{
        .x = OptionBoxLeftPadding,
        .y = START_Y,
        .width = screenWidth - (OptionBoxLeftPadding * 2),
        .height = OptionBoxHeight,
        .MoveButton = move,
        .DrawButton = draw,
    };

    LoadTextures(options) catch {
        print("Error loading textures\n", .{});
    };

    return options;
}

fn MoveButton(last_x: f32, last_y: f32, padding_left: f32) Button {
    const x = last_x + padding_left;
    const y = last_y + 10;
    const position = Button{
        .x = x,
        .y = y,
        .image_path = "assets/move30x30.png",
    };
    return position;
}

fn DrawButton(last_x: f32, last_y: f32, padding_left: f32) Button {
    const x = last_x + padding_left;
    const y = last_y + 10;
    const position = Button{
        .x = x,
        .y = y,
        .image_path = "assets/draw30x30.png",
    };
    return position;
}

fn HandleMovement(options: OptionBox, camera: *rl.Camera2D, mouse: rl.Vector2) void {
    if (IsClickingButton(options.MoveButton)) {
        ActiveButton = .Move;
    }

    if (IsClickingButton(options.DrawButton)) {
        ActiveButton = .Draw;
    }
    if (ActiveButton == .Move) {
        if (rl.isMouseButtonDown(.left)) {
            var delta = rl.getMouseDelta();
            delta = rl.math.vector2Scale(delta, -1.0 / camera.zoom);
            camera.target = rl.math.vector2Add(camera.target, delta);
        }

        const wheel = rl.getMouseWheelMove();
        if (wheel != 0) {
            const mouseWorldPos = rl.getScreenToWorld2D(mouse, camera);
            camera.offset = mouse;
            camera.target = mouseWorldPos;
            var scaleFactor = 1.0 + (0.25 * @abs(wheel));
            if (wheel < 0) {
                scaleFactor = 1.0 / scaleFactor;
            }
            camera.zoom = rl.math.clamp(camera.zoom * scaleFactor, 0.125, 64.0);
        }
    }
}

fn HandleDrawing(target: rl.RenderTexture, mouse: rl.Vector2) void {
    if (ActiveButton == .Draw) {
        // Handle Color Options Box
        const ColorOptionsBox = rl.Rectangle.init(20, 200, 200, 400);
        rl.drawRectangleRounded(ColorOptionsBox, 0.2, 100, Config.OPTION_BOX_COLOR);

        // Handle Coloring
        const color = rl.Color.init(currentColor[Config.R], currentColor[Config.G], currentColor[Config.B], currentColor[Config.A]);

        if (rl.isMouseButtonDown(.left)) {
            rl.beginTextureMode(target);
            if (mouse.y > 50) {
                rl.drawCircle(@intFromFloat(mouse.x), @intFromFloat(mouse.y), brushSize, color);
            }
            rl.endTextureMode();
        }
    }
}

fn LoadTextures(options: OptionBox) !void {
    const MoveButtonImage = try rl.loadImage(options.MoveButton.image_path);
    const MoveButtonTexture = try rl.loadTextureFromImage(MoveButtonImage);
    rl.setTextureFilter(MoveButtonTexture, rl.TextureFilter.bilinear);
    rl.unloadImage(MoveButtonImage);

    const DrawButtonImage = try rl.loadImage(options.DrawButton.image_path);
    const DrawButtonTexture = try rl.loadTextureFromImage(DrawButtonImage);
    rl.setTextureFilter(DrawButtonTexture, rl.TextureFilter.bilinear);
    rl.unloadImage(DrawButtonImage);

    BuildButtons(options, MoveButtonTexture, DrawButtonTexture);

    defer rl.unloadTexture(DrawButtonTexture);
    defer rl.unloadTexture(MoveButtonTexture);
}

fn BuildButtons(options: OptionBox, MoveButtonTexture: rl.Texture2D, DrawButtonTexture: rl.Texture2D) void {
    const OptionsRect = rl.Rectangle.init(options.x, options.y, options.width, options.height);
    rl.drawRectangleRounded(OptionsRect, 0.2, 100, Config.OPTION_BOX_COLOR);
    // Draw Move Button
    const MoveButtonRect = rl.Rectangle.init(options.MoveButton.x, options.MoveButton.y, options.MoveButton.width, options.MoveButton.height);
    rl.drawRectangleRounded(MoveButtonRect, 0.2, 100, if (ActiveButton == .Move) Config.ACTIVE_COLOR else Config.INACTIVE_COLOR);
    rl.drawTexture(MoveButtonTexture, @intFromFloat(options.MoveButton.x + 5), @intFromFloat(options.MoveButton.y + 5), Config.FOREGROUND_COLOR);

    // Draw 'Draw' Button
    const DrawButtonRect = rl.Rectangle.init(options.DrawButton.x, options.DrawButton.y, options.DrawButton.width, options.DrawButton.height);
    rl.drawRectangleRounded(DrawButtonRect, 0.2, 100, if (ActiveButton == .Draw) Config.ACTIVE_COLOR else Config.INACTIVE_COLOR);
    rl.drawTexture(DrawButtonTexture, @intFromFloat(options.DrawButton.x + 5), @intFromFloat(options.DrawButton.y + 5), Config.FOREGROUND_COLOR);
}

pub fn IsClickingButton(rectangle: Button) bool {
    if (rl.isMouseButtonPressed(.left) and IsMouseInButton(rl.getMousePosition(), rectangle)) {
        return true;
    }
    return false;
}

pub fn IsMouseInButton(mouse: rl.Vector2, rectangle: Button) bool {
    if (mouse.x < rectangle.x or mouse.x > rectangle.x + rectangle.width) {
        return false;
    }

    if (mouse.y < rectangle.y or mouse.y > rectangle.y + rectangle.height) {
        return false;
    }

    return true;
}
