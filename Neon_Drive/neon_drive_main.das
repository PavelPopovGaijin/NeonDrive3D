require daslib/media
options indenting = 4
require graphics
require dasbox
require math
require daslib/random
require strings

struct Camera
    pos: float

struct HorizontalLine
    pos: float
    vel: float

struct VerticalLine
    pos: float

struct Obstacle
    line: float
    posX: float
    posY: float
    velY: float
    radius: float

struct Road
    pos: float

let
    PLAYER_COLOR = 0x1DD2FFFF
    OBSTACLE_COLOR = 0xD821E9FF
    ROAD_LINE_COLOR = 0x4BFD4FF0
    GROUND_COLOR    = 0x460a46FF
    SKY_COLOR       = 0x250030FF
    SUN_COLOR       = 0xFFB411FF

    FONT_WIDTH = 4
    FONT_HEIGHT = 5
    font = [[string[FONT_HEIGHT]
        "###  #  ### ### # # ### ### ### ### ### ";
        "# # ##    #   # # # #   #     # # # # # ";
        "# #  #  ###  ## ### ### ###  #  ### ### ";
        "# #  #  #     #   #   # # # #   # #   # ";
        "### ### ### ###   # ### ### #   ### ### "
    ]]

var
    seed: int4
    camera: Camera
    verticalLines: array<VerticalLine>
    horizontalLines: array<HorizontalLine>
    roads: array<Road>
    obstacles: array<Obstacle>

    score = 0
    timeToRestart: float = -1f
    isDriving: bool = true

    sky_offset = 250f
    vertical_lines_count = 5000
    vertical_lines_offset = 300f
    horizontal_lines_count = 20
    horizontal_lines_offset = 3f
    roads_count = 20
    obstacles_offset = 5f
    road_scale = 100f
    obstacle_scale = 3.5
    safe_area = 100000f
    vertical_velocity = 20f
    horizontal_velocity = 2000f
    player_radius = 120f
    carOffsetHorizontal = 78f
    carOffsetVertical = 180f
    collisionOffsetHorizontal = 50f
    collisionOffsetVertical = -50f

    car_image: Image
    background_image: Image
    obstacle_image: Image
    theme: PcmSound <- create_sound( "assets/main_theme.mp3" )
    themeHandle: PlayingSoundHandle

def start()
    var h: HorizontalLine
    h.pos = sky_offset
    h.vel = 0f
    push(horizontalLines, h)

    for i in range(0, vertical_lines_count)
        var v: VerticalLine
        push(verticalLines, v)

    for i in range(0, roads_count)
        var ol: Road
        ol.pos = float(get_screen_width())/2f - float(roads_count) + float(i) * (vertical_lines_offset)
        push(roads, ol)

    car_image <- create_image("assets/car.png")
    background_image <- create_image("assets/background.png")
    obstacle_image <- create_image("assets/obstacle.png")

//Update
def update_horizontal_lines()
    if (length(horizontalLines) == 0 ||(horizontalLines[length(horizontalLines) - 1]).pos >= sky_offset + horizontal_lines_offset)
        var h: HorizontalLine
        h.pos = float(sky_offset)
        push(horizontalLines, h)
        if (isDriving)
            score++

    var idx = length(horizontalLines) - 1
    while idx >= 0
        if horizontalLines[idx].pos > float(get_screen_height())
            erase(horizontalLines, idx)
        idx--

def update_obstacles()
    if (length(obstacles) == 0 || (obstacles[length(obstacles) - 1]).posY >= sky_offset + obstacles_offset)
        var o: Obstacle
        o.posY = float(sky_offset)
        o.posX = float(get_screen_width())/2f
        o.line = roads[random_int(seed) % length(roads)].pos;
        push(obstacles, o)

    var idx = length(obstacles) - 1
    while idx >= 0
        if (obstacles[idx].posY > float(get_screen_height()) + obstacles[idx].radius)
            erase(obstacles, idx)
        idx--

def check_collision(dt: float)
    if timeToRestart <= 0f
        for c in obstacles
            if (((float(get_screen_width())/2f - c.posX) * (float(get_screen_width())/2f - c.posX) <= (player_radius + collisionOffsetHorizontal)*(player_radius + collisionOffsetHorizontal)) && (float(get_screen_height()) - c.posY + collisionOffsetVertical) * (float(get_screen_height()) - c.posY + collisionOffsetVertical) <= (player_radius + collisionOffsetVertical)*(player_radius + collisionOffsetVertical)) 
                timeToRestart = 1f
                isDriving = false

    if timeToRestart > 0f
        timeToRestart -= dt
        if timeToRestart < 0f
            reset_game()


//Render
def horizontal_lines_render()
    for h in horizontalLines
        var idx = 5
        while idx >= 0
            line(0f, h.pos, float(get_screen_width()), h.pos , ROAD_LINE_COLOR)
            idx-- 

def vertical_lines_render()
    var i=-int(vertical_lines_count/2)
    for v in verticalLines
        v.pos = vertical_lines_offset * float(i) + camera.pos
        i++

    for v in verticalLines 
        var idx = 5
        while idx >= 0
            line(float(get_screen_width())/2f, sky_offset, float(get_screen_width())/2f + v.pos, float(get_screen_height()), ROAD_LINE_COLOR)
            idx-- 

def obstacle_render(var o: Obstacle)
    var i=-int(roads_count/2)
    for r in roads
        r.pos = float(get_screen_width()) + vertical_lines_offset * float(i) //+ camera.pos
        i++
    obstacle_image |> draw_image(o.posX - o.radius/2f, o.posY - o.radius * 0.7f/2f, 0xFFFFFFFF, float2(o.radius, o.radius * 0.7f))

def sky_render()
    background_image |> draw_image(0f, -450f ,0xFFFFFFFF, float2(float(get_screen_width()),700f))

def ground_render()
    fill_rect (0, 0, get_screen_width(), 200, SKY_COLOR)

def player_render()
    if timeToRestart > 0f
        if (int(timeToRestart * 16.0) & 1) == 0
            return;
    car_image |> draw_image(float(get_screen_width())/2f - carOffsetHorizontal, float(get_screen_height()) - carOffsetVertical, 0xFFFFFFFF, float2(player_radius*1.3f, player_radius))

def render_num_centered(x: int; y: int; size: int; border: int; num: int; color: uint)
    let buf = "{num}"
    let len = length(buf)
    let left = x - FONT_WIDTH * size * len / 2
    var i = -1

    for c in buf
        i++
        let n = c - '0'
        for iy in range(0, FONT_HEIGHT)
            for ix in range(0, FONT_WIDTH)
                if character_at(font[iy], ix + n * FONT_WIDTH) != ' '
                    fill_rect(left + (ix + i * FONT_WIDTH) * size - border, y + iy * size - border,
                        size + border * 2, size + border * 2, color)

//Movement
def camera_move(var c: Camera; dir: float; dt: float)
    if (c.pos >= float(get_screen_width())/2f - safe_area && c.pos <= float(get_screen_width())/2f + safe_area)
        c.pos += dir * dt
    if (c.pos < float(get_screen_width())/2f - safe_area)
        c.pos = float(get_screen_width())/2f - safe_area
    if (c.pos > float(get_screen_width())/2f + safe_area)
        c.pos = float(get_screen_width())/2f + safe_area
        
def horizontal_line_move(var h: HorizontalLine; dir: float; dt: float)
    h.vel += road_scale * dt
    h.pos += h.vel * dt

def obstacle_move_x(var o: Obstacle; dt: float)
    o.posX += o.velY * dt * (o.line - float(get_screen_width())/2f) / ( float(get_screen_height()) - sky_offset)

def obstacle_move_y(var o: Obstacle; dir: float; dt: float)
    o.velY += road_scale * dt
    o.posY += o.velY * dt

def obstacle_move_by_camera(var o: Obstacle; dir: float; dt: float)
    o.line += dir * dt
    o.posX += dir * dt * (o.posY-sky_offset) / (float(get_screen_height())-sky_offset)
    
def road_move_by_camera(var r: Road; dir: float; dt: float)
    r.pos += dir * dt 

def obstacle_radius(var o: Obstacle; rad: float; dt: float)
    o.radius += rad * dt * obstacle_scale

def draw_score()
    render_num_centered(get_screen_width() / 2, 10, 6, 2, score, 0xFFFFFFFF)

[export]
def initialize
    set_window_title("Neon Drive")
    randomize_seed(seed)
    reset_game()
    start()

def reset_game
    clear(obstacles)
    score = 0
    timeToRestart = -1f
    isDriving = true

[export]
def act(dt: float)
    if get_key(VK_LEFT)
        camera_move(camera, horizontal_velocity, dt)
        for o in obstacles
            obstacle_move_by_camera(o, horizontal_velocity, dt)
    if get_key(VK_RIGHT)
        camera_move(camera, -horizontal_velocity, dt)
        for o in obstacles
            obstacle_move_by_camera(o, -horizontal_velocity, dt)

    if get_key(VK_ESCAPE)
        schedule_quit_game()

    for h in horizontalLines
        horizontal_line_move(h, vertical_velocity, dt)

    for o in obstacles
        obstacle_move_x(o, dt)
        obstacle_move_y(o, vertical_velocity, dt)
        obstacle_radius(o, vertical_velocity, dt)

    update_horizontal_lines()
    update_obstacles()
    check_collision(dt)

    if !is_playing( themeHandle )
        themeHandle = theme |> play_sound()

[export]
def draw()
    enable_alpha_blend() 
    ground_render()
    vertical_lines_render() 
    horizontal_lines_render()
    sky_render()

    var idx = length(obstacles) - 1
    while idx >= 0
        obstacle_render(obstacles[idx])
        idx--

    player_render()
    draw_score()

