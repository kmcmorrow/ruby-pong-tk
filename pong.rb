# A simple game of Pong using Ruby and Tk
# Kevin McMorrow
# Feb 2014

require 'tk'

FPS = 60

WIDTH = 640
HEIGHT = 480

BALL_DIAMETER = 20

PADDLE_OFFSET = 40
PADDLE_WIDTH = 16
PADDLE_HEIGHT = 80

UP = -1
DOWN = 1

BALL_COLOR = '#dddddd'
PLAYER1_COLOR = '#00ff00'
PLAYER2_COLOR = '#0000ff'
BACKGROUND_COLOR = '#222222'
SCORE_COLOR = '#444444'

BALL_SPEED = 5
BALL_MAX_SPEED = 20
PADDLE_SPEED = 5

RESTART_DELAY = 3000

PLAYER1_AI = true
PLAYER2_AI = true

#DEBUG = true

# Sprite class
class Sprite
  attr_reader :rect

  def initialize(canvas, x, y, width, height)
    @canvas = canvas
    @rect = {
      x1: x - width / 2,
      y1: y - height / 2,
      x2: x + width / 2,
      y2: y + height / 2
    }
  end

  def update
    puts 'sprite update not implemented'
  end

  def draw
    if @canvas_obj
      @canvas.coords(@canvas_obj, @rect[:x1], @rect[:y1],
                     @rect[:x2], @rect[:y2])
    else
      puts 'WARNING: No canvas object set'
    end
  end

  def overlaps?(other)
    @rect[:x1] < other.rect[:x2] &&
      @rect[:x2] > other.rect[:x1] &&
      @rect[:y1] < other.rect[:y2] &&
      @rect[:y2] > other.rect[:y1]
  end

  def move(dx, dy)
    @rect[:x1] += dx
    @rect[:x2] += dx
    @rect[:y1] += dy
    @rect[:y2] += dy
  end

  def set_position(x, y)
    @rect = {
      x1: x - width / 2,
      y1: y - height / 2,
      x2: x + width / 2,
      y2: y + height / 2
    }
  end

  def width
    @rect[:x2] - @rect[:x1]
  end

  def height
    @rect[:y2] - @rect[:y1]
  end

  def mid_point
    {
      x: @rect[:x1] + width / 2,
      y: @rect[:y1] + height / 2
    }
  end
end

# Ball
class Ball < Sprite
  attr_writer :angle
  attr_accessor :speed

  def initialize(canvas, x, y, diameter, speed, angle, color)
    @canvas_obj = TkcOval.new(canvas, x, y, diameter, diameter, 'fill' => color)
    super(canvas, x, y, diameter, diameter)
    @diameter = diameter
    @speed = speed
    @angle = angle
  end

  def update
    dx = @speed * Math.cos(@angle)
    dy = @speed * Math.sin(@angle)
    move(dx, dy)
    bounce_off_walls
  end

  private

  def bounce_off_walls
    if @rect[:y1] < 0
      @angle = 2 * Math::PI - @angle
      move(0, -@rect[:y1])
    end
    if @rect[:y2] > HEIGHT
      move(0, HEIGHT - @rect[:y2])
      @angle = 2 * Math::PI - @angle
    end
=begin
    if @rect[:x1] < 0
      #@angle = 180 - @angle
      move(-@rect[:x1], 0)
      @angle = Math::PI - @angle
    end
    if @rect[:x2] > WIDTH
      #@angle = 180 - @angle
      move(WIDTH - @rect[:x2], 0)
      @angle = Math::PI - @angle
    end
=end
  end
end

# Paddle
class Paddle < Sprite
  attr_accessor :ai

  def initialize(canvas, x, y, width, height, color)
    @canvas_obj = TkcRectangle.new(canvas, x, y, x + width, x + height,
                                   'fill' => color)
    super(canvas, x, y, width, height)
    @speed = PADDLE_SPEED
    @dy = 0
    @ai = false
  end

  def start_moving(direction)
    @dy = @speed * direction
  end

  def stop_moving
    @dy = 0
  end

  def update
    move(0, @dy)
    if @rect[:y1] < 0
      move(0, -@rect[:y1])
    elsif @rect[:y2] > HEIGHT
      move(0, HEIGHT - @rect[:y2])
    end
  end
end

# main game class
class Pong
  def initialize
    root = setup_layout

    #start_angle = deg_to_rad(rand(360))
    start_angle = deg_to_rad(rand(90) - 45 + 180 * rand(2))
    @ball = Ball.new(@canvas, WIDTH / 2, HEIGHT / 2, BALL_DIAMETER,
                     BALL_SPEED, start_angle, BALL_COLOR)
    @player1 = Paddle.new(@canvas, PADDLE_OFFSET, HEIGHT / 2,
                          PADDLE_WIDTH, PADDLE_HEIGHT, PLAYER1_COLOR)
    @player2 = Paddle.new(@canvas, WIDTH - PADDLE_OFFSET, HEIGHT / 2,
                          PADDLE_WIDTH, PADDLE_HEIGHT, PLAYER2_COLOR)

    @player1.ai = PLAYER1_AI
    @player2.ai = PLAYER2_AI

    @player1_score = 0
    @player2_score = 0

    @running = false

    bind_events root

  end

  def start
    @running = true
    update
    Tk.mainloop
  end

  def toggle_player1_ai
    @player1.ai = !@player1.ai
    @player1.stop_moving
  end

  def toggle_player2_ai
    @player2.ai = !@player2.ai
    @player2.stop_moving
  end

  private

  # create window components
  def setup_layout
    root = TkRoot.new do
      title 'Pong'
    end

    score_frame = TkFrame.new(root) do
      pack('side' => 'top')
    end

    @player1_score_label = TkLabel.new(score_frame) do
      text '0'
      font TkFont.new('sans 26 bold')
      foreground SCORE_COLOR
      pack('side' => 'left', 'padx' => '10', 'pady' => '0')
    end

    @player2_score_label = TkLabel.new(score_frame) do
      text '0'
      font TkFont.new('sans 26 bold')
      foreground SCORE_COLOR
      pack('side' => 'left', 'padx' => '10', 'pady' => '0')
    end

    @canvas = TkCanvas.new(root) do
      width WIDTH
      height HEIGHT
      background BACKGROUND_COLOR
      pack('side' => 'top')
    end

    this = self
    TkCheckButton.new(root) do
      text 'Player 1 AI'
      command(select) if PLAYER1_AI
      place('height' => 25, 'width' => 100, 'x' => 0, 'y' => 10)
      command(proc { this.toggle_player1_ai })
    end

    TkCheckButton.new(root) do
      text 'Player 2 AI'
      command(select) if PLAYER2_AI
      place('height' => 25, 'width' => 100, 'x' => WIDTH - 100, 'y' => 10)
      command(proc { this.toggle_player2_ai })
    end

    root
  end

  # setup event handlers
  def bind_events(root)
    root.bind('KeyPress-Up', proc { @player2.start_moving UP })
    root.bind('KeyRelease-Up', proc { @player2.stop_moving })
    root.bind('KeyPress-Down', proc { @player2.start_moving DOWN })
    root.bind('KeyRelease-Down', proc { @player2.stop_moving })

    root.bind('KeyPress-w', proc { @player1.start_moving UP })
    root.bind('KeyRelease-w', proc { @player1.stop_moving })
    root.bind('KeyPress-s', proc { @player1.start_moving DOWN })
    root.bind('KeyRelease-s', proc { @player1.stop_moving })
  end

  def update
    Tk.after(1000 / FPS, proc { update })
    if @running
      @ball.update
      update_ai @player1 if @player1.ai
      update_ai @player2 if @player2.ai
      @player1.update
      @player2.update
      check_for_collisions
      check_ball_out_of_bounds
    end

    @ball.draw
    @player1.draw
    @player2.draw

    update_score
  end

  def update_score
    @player1_score_label.configure('text' => @player1_score.to_s)
    @player2_score_label.configure('text' => @player2_score.to_s)
  end

  def update_ai(player)
    if player.rect[:y1] > @ball.rect[:y2]
      player.start_moving UP
    end
    if player.rect[:y2] < @ball.rect[:y1]
      player.start_moving DOWN
    end
  end

  def check_for_collisions
    if @ball.overlaps? @player1
      @ball.move(2 * (@player1.rect[:x2] - @ball.rect[:x1]), 0)
      @ball.angle = angle(@player1.mid_point[:x],
                          @player1.mid_point[:y],
                          @ball.mid_point[:x],
                          @ball.mid_point[:y])
      @ball.speed += 0.1 if @ball.speed < BALL_MAX_SPEED
    end
    if @ball.overlaps? @player2
      @ball.move(2 * (@player2.rect[:x1] - @ball.rect[:x2]), 0)
      @ball.angle = angle(@player2.mid_point[:x],
                          @player2.mid_point[:y],
                          @ball.mid_point[:x],
                          @ball.mid_point[:y])
      @ball.speed += 0.1 if @ball.speed < BALL_MAX_SPEED
    end
  end

  def check_ball_out_of_bounds
    if @ball.rect[:x1] < 0
      @player2_score += 10
      restart
    elsif @ball.rect[:x2] > WIDTH
      @player1_score += 10
      restart
    end
  end

  def restart
    @running = false
    @ball.set_position(WIDTH / 2, HEIGHT / 2)
    @ball.speed = BALL_SPEED
    @ball.angle = deg_to_rad(rand(90) - 45 + 180 * rand(2))
    @player1.set_position(PADDLE_OFFSET, HEIGHT / 2)
    @player2.set_position(WIDTH - PADDLE_OFFSET, HEIGHT / 2)

    Tk.after(RESTART_DELAY, proc { @running = true })
  end

end

###################
# helper functions
###################

# convert degrees to radians
def deg_to_rad(deg)
  deg * Math::PI / 180
end

# convert radians to degrees
def rad_to_deg(rad)
  rad * 180 / Math::PI
end

# return the angle between two points in radians
def angle(x1, y1, x2, y2)
  Math.atan2(y2 - y1, x2 - x1)
end

# start the game
Pong.new.start
