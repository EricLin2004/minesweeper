require 'debugger'
require 'yaml'
require 'colorize'

class Minesweeper
  attr_accessor :gameboard, :name, :size, :mines

  def initialize
    user_settings
  end

  def user_settings
    puts "What's your name?"
    @name = gets.chomp

    puts "Do you want to load a saved game? Yes/No"
    @saved = gets.chomp.downcase

    if @saved != "yes"
      puts "Board size?"
      @size = gets.chomp.to_i

      puts "How many mines?"
      @mines = gets.chomp.to_i
    end
  end

  def run
    if @saved == "yes"
      @gameboard = YAML::load(File.read("#{@name}-minesweeper.txt"))
    else
      @gameboard = Board.new(@size, @mines)
    end

    @gameboard.print_high_scores

    start_time = Time.now
    until @gameboard.over
      @gameboard.display
      play_turn
      @gameboard.check_win(@name, Time.now - start_time)
    end
    @gameboard.display
    @gameboard.print_high_scores
  end

  def play_turn
    puts "Input position to check (x,y)? ex. 1,2 or press 'f' for flag or 's' to save"
    input = gets.chomp
    until Regexp.new(/^\d,\d$/).match(input) || Regexp.new(/^[fs]$/).match(input)
      puts "Invalid input, try again:"
      input = gets.chomp
    end

    if input == 'f'
      flag_input
    elsif input == 's'
      save_game
    else
      input = input.split(',')
      input_array = input.map { |x| x.to_i}.reverse
      @gameboard.update(input_array)
    end
  end

  def flag_input
    puts "Which position do you want to flag? Or to un-flag, re-enter a flagged position"
    flag = gets.chomp
    until Regexp.new(/^\d,\d$/).match(flag)
      puts "Invalid input, try again:"
      flag = gets.chomp
    end

    flag = flag.split(',')
    flag_array = flag.map { |x| x.to_i}.reverse
    @gameboard.flag_position(flag_array)
    puts "Position Flagged."
  end

  def save_game
    saved_board = @gameboard.to_yaml
    File.open("#{@name}-minesweeper.txt", 'w') do |line|
      line.puts saved_board
    end
    @gameboard.over = true
    puts "Game has been saved in #{@name}-minesweeper.txt"
  end

end

class Board
  attr_accessor :mine_pos, :over, :check_pos, :flagged_pos

  def initialize(size = 9, mines = 20)
    @size = size
    @mines = mines
    @mine_pos = []
    @flagged_pos = []
    @over = false
    @high_scores = []
    @board = Array.new(@size) { ['*'] * @size }
    set_mines(@size, mines)
  end

  def set_mines(size, mines)
    counter = 0
    while counter < mines
      pos = [rand(size), rand(size)]
      unless mine_pos.include?(pos)
        @mine_pos << pos
        counter += 1
      end
    end
  end

  def display
    print "   "
    (0..@size-1).each { |x| print x.to_s + " "}
    puts
    print "   #{'_ '*@size}"
    puts
    @board.each_with_index do |row, index|
      puts "#{index} |" + row.join(" ")
      #print "\n"
    end
  end

  def check_win(name, duration)
    stars = @board.inject(0) { |total, row| total + row.count("*") }
    if @flagged_pos.length + stars == @mines
      @over = true
      puts "Congratulations, you won!!"
      high_scores(name, duration)
    end
  end

  def update(pos)
    if @mine_pos.include?(pos)
      gameover(pos)
    else
      search_surrounding_spots(pos)
    end
  end

  def search_surrounding_spots(pos)
    queue = [pos]
    checked = []
    until queue.empty?
      this_pos = queue.shift
      checked << this_pos
      num_bombs = check_bomb(this_pos)
      if num_bombs == 0
        reveal_blanks(this_pos, checked, queue)
      else
        reveal_bomb_count(this_pos, num_bombs)
      end
    end
  end

  def reveal_blanks(this_pos, checked, queue)
    @board[this_pos[0]][this_pos[1]] = '_'.colorize( :white )
    @check_pos.each do |position|
      unless checked.include?(position) || queue.include?(position) || @flagged_pos.include?(position)
        queue << position
        @board[position[0]][position[1]] = '_'.colorize( :white)
      end
    end
  end

  def reveal_bomb_count(this_pos, num_bombs)
    unless @flagged_pos.include?(this_pos)
      case num_bombs
      when 1
        @board[this_pos[0]][this_pos[1]] = num_bombs.to_s.colorize( :blue )
      when 2
        @board[this_pos[0]][this_pos[1]] = num_bombs.to_s.colorize( :green )
      when 3
        @board[this_pos[0]][this_pos[1]] = num_bombs.to_s.colorize( :red )
      else
        @board[this_pos[0]][this_pos[1]] = num_bombs.to_s.colorize( :magenta )
      end
    end
  end

  def gameover(pos)
    @over = true
    puts "You hit a bomb! Gameover"
    @board[pos[0]][pos[1]] = 'B'.colorize( :color => :red, :background => :blue)
  end


  def flag_position(pos)
    if @board[pos[0]][pos[1]] == '*'
      @board[pos[0]][pos[1]] = 'F'
      @flagged_pos << pos
    elsif @board[pos[0]][pos[1]] == 'F'
      @board[pos[0]][pos[1]] = '*'
      @flagged_pos.slice!(@flagged_pos.index(pos))
    else
      puts "Try again"
    end
  end

  def check_bomb(pos)
    counter = 0
    @check_pos = [
    [pos[0],pos[1]+1], [pos[0]+1,pos[1]],
    [pos[0]+1,pos[1]+1], [pos[0],pos[1]-1],
    [pos[0]-1,pos[1]], [pos[0]-1,pos[1]-1],
    [pos[0]-1,pos[1]+1], [pos[0]+1,pos[1]-1]
    ]
    @check_pos.select! do |position|
      position[0] < @size && position[1] < @size && position[0] >= 0 && position[1] >= 0
    end

    @check_pos.each do |coord|
      if @mine_pos.include?(coord)
        counter += 1
      end
    end
    counter
  end

  def high_scores(name, duration)
    @high_scores = YAML::load(File.read("high-scores-minesweeper.txt"))
    @high_scores << [name, @size, @mines, duration]
    File.open("High-scores-minesweeper.txt", 'w') do |line|
      line.puts @high_scores.to_yaml
    end
  end

  def print_high_scores
      high_scores = YAML::load(File.read("high-scores-minesweeper.txt"))
      puts "**HIGH SCORES**"
      high_scores.sort!{ |num1, num2| num1[3] <=> num2[3]}
      high_scores.each do |entry|
        print "Name: #{entry[0]} Board size: #{entry[1]} Mines: #{entry[2]} Time: #{entry[3]} \n"
      end
    end
end


x = Minesweeper.new
x.run