// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");
const screenWidth = 1600;
const screenHeight = 850;
const std = @import("std");
const print = std.debug.print;

const ACTIVE_COLOR = rl.Color.init(32, 32, 32, 100);
const FOREGROUND_COLOR = rl.Color.init(255, 255, 255, 255);
const BACKGROUND_COLOR = rl.Color.init(43, 43, 45, 255);
const OPTION_BOX_COLOR = rl.Color.init(88, 88, 91, 255);
const INACTIVE_COLOR = OPTION_BOX_COLOR;
const MOVE_INDEX = 0;
const DRAW_INDEX = 1;

const R = 0;
const G = 1;
const B = 2;
const A = 3;
var currentColor: [4]u8 = [_]u8{ 255, 255, 255, 255 };
var brushStroke: f32 = 10;
const Buttons = enum {
    Move,
    Draw,
};

var zoomMode: bool = false;
pub fn main() anyerror!void {
    rl.initWindow(screenWidth, screenHeight, "Zignature");
    defer rl.closeWindow();
    var camera = rl.Camera2D{
        .target = .{ .x = 0, .y = 0 },
        .offset = .{ .x = 0, .y = 0 },
        .zoom = 1.0,
        .rotation = 0,
    };

    rl.setTargetFPS(60);

    // Get Option Box
    const options = GetOptionBox();
    var ActiveButton: Buttons = .Draw;

    // Load Textures
    const MoveButtonImage = try rl.loadImage(options.MoveButton.image_path);
    const MoveButtonTexture = try rl.loadTextureFromImage(MoveButtonImage);
    rl.setTextureFilter(MoveButtonTexture, rl.TextureFilter.bilinear);
    rl.unloadImage(MoveButtonImage);

    const DrawButtonImage = try rl.loadImage(options.DrawButton.image_path);
    const DrawButtonTexture = try rl.loadTextureFromImage(DrawButtonImage);
    rl.setTextureFilter(DrawButtonTexture, rl.TextureFilter.bilinear);
    rl.unloadImage(DrawButtonImage);

    //

    defer rl.unloadTexture(MoveButtonTexture);

    const target = try rl.loadRenderTexture(screenWidth, screenHeight);

    // Clear render texture before entering the game loop
    rl.beginTextureMode(target);
    rl.clearBackground(BACKGROUND_COLOR);
    rl.endTextureMode();
    rl.enableEventWaiting();
    while (!rl.windowShouldClose()) {
        const mouse = rl.getMousePosition();
        // Translate based on mouse right click

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

        // Draw
        rl.beginDrawing();
        rl.clearBackground(BACKGROUND_COLOR);
        defer rl.endDrawing();
        {
            camera.begin();
            defer camera.end();

            rl.drawTextureRec(target.texture, rl.Rectangle.init(0, 0, @floatFromInt(target.texture.width), @floatFromInt(-target.texture.height)), rl.Vector2.init(0, 0), rl.Color.init(currentColor[R], currentColor[G], currentColor[B], currentColor[A]));
        }
        const OptionsRect = rl.Rectangle.init(options.x, options.y, options.width, options.height);
        rl.drawRectangleRounded(OptionsRect, 0.2, 100, OPTION_BOX_COLOR);
        // Draw Move Button
        const MoveButtonRect = rl.Rectangle.init(options.MoveButton.x, options.MoveButton.y, options.MoveButton.width, options.MoveButton.height);
        rl.drawRectangleRounded(MoveButtonRect, 0.2, 100, if (ActiveButton == .Move) ACTIVE_COLOR else INACTIVE_COLOR);
        rl.drawTexture(MoveButtonTexture, @intFromFloat(options.MoveButton.x + 5), @intFromFloat(options.MoveButton.y + 5), FOREGROUND_COLOR);

        // Draw 'Draw' Button
        const DrawButtonRect = rl.Rectangle.init(options.DrawButton.x, options.DrawButton.y, options.DrawButton.width, options.DrawButton.height);
        rl.drawRectangleRounded(DrawButtonRect, 0.2, 100, if (ActiveButton == .Draw) ACTIVE_COLOR else INACTIVE_COLOR);
        rl.drawTexture(DrawButtonTexture, @intFromFloat(options.DrawButton.x + 5), @intFromFloat(options.DrawButton.y + 5), FOREGROUND_COLOR);

        if (ActiveButton == .Draw) {
            // Handle Color Options Box
            const ColorOptionsBox = rl.Rectangle.init(20, 200, 200, 400);
            rl.drawRectangleRounded(ColorOptionsBox, 0.2, 100, OPTION_BOX_COLOR);

            // Handle Coloring
            const color = rl.Color.init(currentColor[R], currentColor[G], currentColor[B], currentColor[A]);

            if (rl.isMouseButtonDown(.left)) {
                rl.beginTextureMode(target);
                if (mouse.y > 50) {
                    rl.drawCircle(@intFromFloat(mouse.x), @intFromFloat(mouse.y), brushStroke, color);
                }
                rl.endTextureMode();
            }
        }
    }
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

pub fn GetOptionBox() OptionBox {
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
    return options;
}

pub fn MoveButton(last_x: f32, last_y: f32, padding_left: f32) Button {
    const x = last_x + padding_left;
    const y = last_y + 10;
    const position = Button{
        .x = x,
        .y = y,
        .image_path = "assets/move30x30.png",
    };
    return position;
}

pub fn DrawButton(last_x: f32, last_y: f32, padding_left: f32) Button {
    const x = last_x + padding_left;
    const y = last_y + 10;
    const position = Button{
        .x = x,
        .y = y,
        .image_path = "assets/draw30x30.png",
    };

    return position;
}
