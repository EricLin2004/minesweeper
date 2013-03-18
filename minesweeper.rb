require 'debugger'
require 'yaml'

class Minesweeper
  attr_accessor :gameboard, :name

  def initialize
    puts "What's your name?"
    @name = gets.chomp
    puts "Do you want to load a saved game? Yes/No"
    @saved = gets.chomp
    puts "Board size?"
    size = gets.chomp.to_i
    puts "How many mines?"
    mines = gets.chomp.to_i
    @gameboard = Board.new(size, mines)
  end

  def run
    if @saved == "Yes"
      @gameboard = YAML::load(File.read("#{@name}-minesweeper.txt"))
    end
    @start_time = Time.now
    until @gameboard.over
      @gameboard.display
      play_turn
      @gameboard.check_win(@name, Time.now - @start_time)
    end
    @gameboard.display

  end

  def play_turn
    puts "Input position to check? ex. 1,2 or press 'f' for flag or 's' to save"
    input = gets.chomp
    if input == 'f'
      puts "Which position do you want to flag? Or to un-flag, re-enter a flagged position"
      flag = gets.chomp.split(',')
      flag_array = flag.map { |x| x.to_i}
      @gameboard.flag_position(flag_array)
    elsif input == 's'
      saved_board = @gameboard.to_yaml
      File.open("#{@name}-minesweeper.txt", 'w') do |line|
        line.puts saved_board
      end
      @gameboard.over = true
      puts "Game has been saved in #{@name}-minesweeper.txt"
    else
      input = input.split(',')
      input_array = input.map { |x| x.to_i}
      @gameboard.update(input_array)
    end
  end

end

class Board
  attr_accessor :mine_pos, :over, :check_pos, :flagged_pos

  def initialize(size = 9, mines = 20)
    @size = size
    @board = Array.new(@size) { ['*'] * @size }
    @mine_pos = []
    set_mines(@size, mines)
    @over = false
    @flagged_pos = []
    @mines = mines
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
    @board.each do |row|
      puts row.join(" ")
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
    if @board[pos[0]][pos[1]] == 'F'
      puts "This position is flagged."
    elsif @mine_pos.include?(pos)
      @over = true
      puts "You hit a bomb! Gameover"
      @board[pos[0]][pos[1]] == 'B'
    else
      queue = [pos]
      checked = []
      until queue.empty?
        this_pos = queue.shift
        checked << this_pos
        num_bombs = check_bomb(this_pos)
        #p 'got here'
        if num_bombs == 0
          @board[this_pos[0]][this_pos[1]] = '_'
          @check_pos.each do |position|
            #p 'inside here'
            unless checked.include?(position) || queue.include?(position) || @flagged_pos.include?(position)
              queue << position
              #debugger
              @board[position[0]][position[1]] = '_'
            end
          end
        else
          @board[this_pos[0]][this_pos[1]] = num_bombs unless @flagged_pos.include?(this_pos)
        end
      end
    end
  end

  def flag_position(pos)
    if @board[pos[0]][pos[1]] != 'F'
      @board[pos[0]][pos[1]] = 'F'
      @flagged_pos << pos
    else
      @board[pos[0]][pos[1]] = '*'
      @flagged_pos.slice!(@flagged_pos.index(pos))
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
    File.open("High-scores-minesweeper.txt", 'a') do |line|
      line.puts "#{name}, Board: #{@size}, Mines: #{@mines}, Time: #{duration}"
    end
  end

end

class Player
  def initialize

  end
end

x = Minesweeper.new
x.run