const rl = @import("raylib");

pub const ACTIVE_COLOR = rl.Color.init(32, 32, 32, 100);
pub const FOREGROUND_COLOR = rl.Color.init(255, 255, 255, 255);
pub const BACKGROUND_COLOR = rl.Color.init(43, 43, 45, 255);
pub const OPTION_BOX_COLOR = rl.Color.init(88, 88, 91, 255);
pub const INACTIVE_COLOR = OPTION_BOX_COLOR;
pub const MOVE_INDEX = 0;
pub const DRAW_INDEX = 1;

pub const R = 0;
pub const G = 1;
pub const B = 2;
pub const A = 3;
