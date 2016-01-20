// Typical beehive frame is 480mm x 240mm, 29mm deep
// numbers based on https://en.wikipedia.org/wiki/Langstroth_hive\
// should average ~7000 cells
// http://www.beesource.com/forums/archive/index.php/t-230451.html

final float FRAME_WIDTH   = 480;
final float FRAME_HEIGHT  = 230; // our specific case
final float FRAME_DEPTH   = 19;  
final float CELL_DIAMETER = 6.235; // 5.4mm from flat side to flat side, -> diameter is 5.4mm / sin(60) = 6.235mm
final float CELL_SIZE     = CELL_DIAMETER * SIN60;
      float CELL_ANGLE    = 6;    // cell angle in degrees (set to 0 when in demo mode, therefore no 'final' attribute)

// some configuration variables
final float   CELL_ROUGHNESS = 0; // values between 0 (no irregularities) to maybe 10 (extreme)

final boolean DEMO_MODE         = false;
final int     DEMO_RESET_TIME   = 45; // seconds

final int     FRAMES_PER_SECOND         = 60;
final int     FRAMES_PER_AGENT_MOVEMENT = 5; // how many frames for the agents to do one step