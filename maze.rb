#!/usr/local/bin/ruby

#------------------------------------------------------------------------------
# Maze Solver
#------------------------------------------------------------------------------

HEADER = 1
CELL = 2
PATH = 3
$simple_maze_format = ""
$invalid_output = ""
$invalid_maze = false

def parse(file)
  # header
  line = file.gets
  while line =~ /^[\s]*$\n/
    # skip empty lines
    line = file.gets
  end
  if line_valid?(line, HEADER)
    # parse it
    valid_header = line.split(/[^0-9]/)
    valid_header.delete("")
    size, x_start, y_start, x_end, y_end = valid_header
    # valid header
    $simple_maze_format << size + " " + x_start + " "
    $simple_maze_format << y_start + " " + x_end + " " + y_end + "\n"
  else
    # invalid header
    $invalid_maze = true
    $invalid_output << line
  end
 
  # cells and paths
  while line = file.gets
    if line =~ /^[\s]*$\n/
      next 
    end
    if line =~ /^"/ #/path/i
      if valid_multiple_paths?(line)
        parse_multiple_paths(line)
      elsif line_valid?(line, PATH)
          parse_single_path(line)
      else
          # invalid path (single)
          $invalid_maze = true
          $invalid_output << line
      end

    else
      # process cell
      if line_valid?(line, CELL)
        # parse it
        parse_cell(line)
      else
        # invalid cell
        $invalid_maze = true
        $invalid_output << line
      end
    end
  end

  $invalid_output.insert(0, "invalid maze\n")
  if $invalid_maze
    puts $invalid_output
  else
    puts $simple_maze_format
  end
end

def line_valid?(line, type)
  case type

  when HEADER
    header_regex = /maze:\s\d+\s\d+:\d+\s->\s\d+:\d+/
    return header_regex =~ line ? true : false # validate header

  when CELL
    cell_regex = /\d+,\d+:\s([udlr]{0,4})\s(-?\d*.\d+){0,1}(,-?\d*.\d+){0,4}\s*$/
    return cell_regex =~ line ? true : false  

  when PATH
    sing_path_regex = /"[^: ]+:\(\d+,\d+\)(,[udlr])*"/
    return sing_path_regex =~ line ? true : false   
  end  
end

def more_than_one_direction?(dirs)
  return dirs.count('u') > 1 || dirs.count('d') > 1 || dirs.count('l') > 1 || dirs.count('r') > 1
end

def valid_multiple_paths?(line)
  mult_paths_regexp = /^"[^: ]+:\(\d+,\d+\)(,[udlr])*"(,"[^: ]+:\(\d+,\d+\)(,[udlr])*")+\s*$/
  return mult_paths_regexp =~ line
end

def parse_cell(line)
  valid_cell = line.chomp

  coors, values = valid_cell.split(/:/)
  x_coor, y_coor = coors.split(/,/)

  values = values.lstrip
  values = values.rstrip

  if values != nil
    dirs, weights_values = values.split(/\s/)
    if dirs != nil
      if dirs.length > 4 || more_than_one_direction?(dirs)
        #invalid line
        $invalid_maze = true
        $invalid_output << line
      else
        # valid dirs and weight
        weights_array = weights_values.split(/,/)
        weights = ""
        weights_array.each { |w| weights << " " + w  }
        $simple_maze_format << x_coor + " " + y_coor + " " + dirs + weights + "\n"
      end
    else
      # coordinates only
      $simple_maze_format << x_coor + " " + y_coor + "\n"
    end
  end
end

def parse_multiple_paths(line)
  mult_paths = line.chomp.strip
  # break it into chunks
  sing_paths = mult_paths.split(/","/)
  sing_paths.each { |p| 
    if p[0] != "\""
      p.insert(0, "\"")
    end
    if p[-1] != "\""
      p.insert(-1, "\"")
    end

    if line_valid?(p, PATH)
      parse_single_path(p)
    else
      # invalid path (multipe)
      $invalid_maze = true
      $invalid_output << line
      break
    end
  }
end

def parse_single_path(single_path)
  name, values = single_path.split(/:/)
  # name
  # replace scaped for normal quotes
  name.gsub!("\\\"","\"")
  name.sub!("\"", "")

  coords, dirs = values.split(/\),/)

  # coordinates
  coords.sub!("(", "")
  x_coor, y_coor = coords.split(/,/)

  # directions
  dirs.sub!("\"", "")
  dirs.chomp!
  dirs.gsub!(",", "")
  $simple_maze_format << "path " + name + " " + x_coor + " " + y_coor + " " + dirs + "\n"
end


class Maze
  def initialize(file)
    line = file.gets
    if line == nil
      return end
    # header
    @size = line.split(/\s/)[0].to_i
    @x_start = line.split(/\s/)[1].to_i
    @y_start = line.split(/\s/)[2].to_i
    @x_end = line.split(/\s/)[3].to_i
    @y_end = line.split(/\s/)[4].to_i

    # cells and paths
    @cells = Array.new(@size){Array.new(@size)}
    @paths = Array.new
    i = p = 0
    while line = file.gets

      if line =~ /path/i
        # create path
        name, x, y, dirs = Path.parse(line)
        @paths[p] = Path.new(name, x, y, dirs)
        p += 1
      else 
        # create cell
        x, y, dw_hash = Cell.parse(line)
        @cells[x][y] = Cell.new(dw_hash)
        i += 1
      end 
    end
  end

  attr_accessor "size", "x_start", "y_start", "x_end", "y_end", "cells", "paths"

  def to_s
    s =  "#{size} #{x_start} #{y_start} #{x_end} #{y_end}\n" 
    for y in (0...@size)
      for x in (0...@size)
        if @cells[x][y] != nil
          s += x.to_s + " " + y.to_s + " " + @cells[x][y].to_s + "\n"
        end
      end
    end
    @paths.each { |p| s += p.to_s}
    return s
  end

  # returns the number of closed cells or a formatted string 
  # indicating the number of open walls in each cell, depending 
  # on the parameter ("closed" or "open")
  def properties(which)
    case which
    when "closed"
      count = 0
      for y in 0...@size
        for x in 0...@size
          if @cells[x][y] == nil #closed 
            count += 1
          elsif @cells[x][y].dw_hash.empty?
            count += 1
          end
        end
      end
      puts count
    when "open"
      u = d = l = r = 0
      for y in 0...@size
        for x in 0...@size
          if @cells[x][y] != nil && !@cells[x][y].dw_hash.empty?
            @cells[x][y].dw_hash.keys.each { |k| 
              case k
              when "u"
                u += 1
              when "d"
                d += 1
              when "l"
                l += 1
              when "r"
                r += 1
              end
            }
          end
        end
      end
      wall_counts = "u: #{u}, d: #{d}, l: #{l}, r: #{r}"
      puts wall_counts
    end      
  end

  def rank_paths_by_cost
    @paths.each { |p| 
      x_coor = p.x_start
      y_coor = p.y_start
      path_dirs = p.dirs
      w_sum = 0
      path_dirs.each_char { |d| 
        if cells[x_coor][y_coor] != nil

          w_sum += cells[x_coor][y_coor].dw_hash[d] == nil ? 0 : cells[x_coor][y_coor].dw_hash[d]
          case d
          when "u"
            y_coor -= 1
          when "d"
            y_coor += 1
          when "l"
            x_coor -= 1
          when "r"
            x_coor += 1
          else
            puts "Error: unknown direction"
          end

        else
          # puts "Error: closed cell"
        end
      }
      p.cost = w_sum
    }
    result = @paths.sort { |x, y| x.cost <=> y.cost }
    result.each_with_index { |x, i| 
      if i != 0 then print ", " end
      print x.name }
      print "\n"
  end

  def pretty_print
    for y in 0...@size
      print "+"

      # plus signs (vertcal dirs)
      for x in 0...@size
        if @cells[x][y] == nil # closed cell
          print "-"  
        else
          direcs = @cells[x][y].dw_hash.keys
          if direcs.include? "u"
            print " "
          else
            print "-"
          end
        end
        print "+"
      end
      print "\n"

      # pipes (horizontal dirs)
      print "|"
      for x in 0...@size
        if x == x_start && y == y_start
          print "s"
        elsif x == x_end && y == y_end
          print "e"
        else
            print " "
        end

        if @cells[x][y] == nil # closed cell
          print "|"
        else
          direcs = @cells[x][y].dw_hash.keys
          if direcs.include? "r"
            print " "
          else
            print "|"
          end
        end
      end
      print "\n"
    end

    # outer bottom wall
    print "+"
    for i in 0...@size
      print "-+"
    end
    print "\n"
  end

  def solvable?
    m_graph = Graph.new(self)
    m_graph.doDFS([x_start, y_start], [x_end, y_end])
  end

  class Cell
    def initialize(dw_hash)
      @dw_hash = dw_hash
    end

    attr_accessor "dw_hash"

    def to_s
      s = ""
      @dw_hash.keys.each { |k| s += k}
      @dw_hash.keys.each { |k| s += " " + dw_hash[k].to_s}
      return s
    end

    def self.parse(line)
      x_pos, y_pos, dirs, weights = line.split(/\s/, 4)
      # convert coordinates to int
      x_pos = x_pos.to_i
      y_pos = y_pos.to_i

      weights = weights.split(/\s/)
      # convert strings to floats
      weights.collect! {|f| f.to_f}

      # check that dir and weight's can be evenly mapped
      dirs_len = dirs.length
      weights_len = weights.length
      if dirs_len != weights_len
        puts "Error: Invalid Cell"
        exit
      end

      dw_hash = Hash.new
      dirs.split("").each_with_index { |x, i| dw_hash[x] = weights[i]}
      
      return [x_pos, y_pos, dw_hash]
    end
  end

  class Path
    def initialize(name, x, y, dirs)
      @name = name
      @x_start = x
      @y_start = y
      @dirs = dirs
      @cost = 0
    end

    attr_accessor "name", "x_start", "y_start", "dirs", "cost"

    def to_s
      return "#{@name} #{@x_start} #{@y_start} #{@dirs}"
    end

    def self.parse(line)
      line.chomp!
      elements = line.split(/[^0-9a-zA-Z]/, 5)
      if elements[0].casecmp("path") == 0 
        elements.shift
      end

      name = elements[0]
      x_start = elements[1].to_i
      y_start = elements[2].to_i
      dirs = elements[3]

      return [name, x_start, y_start, dirs]
    end
  end

end

class Graph
  def initialize(maze)
    @adj_map = Hash.new{|hash, key| hash[key] = Array.new}
    @data_map = Hash.new

    start_pos = [maze.x_start, maze.y_start] 
    end_pos = [maze.x_end, maze.y_end]

    add_vertex(start_pos, "s")
    add_vertex(end_pos, "e")

    for y in 0...maze.size
      for x in 0...maze.size

        from_vertex = [x, y]
        if maze.cells[x][y] == nil then next end # closed cell
        maze.cells[x][y].dw_hash.keys.each { |d|
          case d
          when 'u'
            y_coor = y - 1
            to_vertex = [x, y_coor]
          when 'd'
            y_coor = y + 1
            to_vertex = [x, y_coor]
          when 'l'
            x_coor = x - 1
            to_vertex = [x_coor, y]
          when 'r'
            x_coor = x + 1
            to_vertex = [x_coor, y]
          else
            # puts "Error: unknown direction"
          end
          add_directed_edge(from_vertex, to_vertex)
        }
      end
    end
  end

  def add_directed_edge(from_vertex, to_vertex)
    @adj_map[from_vertex].push(to_vertex)
  end

  def add_vertex(vertex_pos, data)
    @data_map[vertex_pos] = data
  end

  attr_accessor "adj_map", "data_map"

  def to_s
    return "#{adj_map} #{data_map}"
  end

  def doDFS(start_vertex, end_vertex)
    visited_vertices = Hash.new
    stack = Array.new

    stack.push(start_vertex)
    while !stack.empty?
      curr_vertex = stack.pop
      if visited_vertices[curr_vertex] == nil # not visited
        # mark as visited
        visited_vertices[curr_vertex] = "v"
        if curr_vertex == end_vertex
          return true
        end
      end

      while (edge = @adj_map[curr_vertex].pop) != nil
        stack.push(edge)
      end
    end
     return false
  end

  # DFS Algorithm
  # 1 let S be a stack
  # 3      S.push(v)
  # 4      while S is not empty
  # 5            v ← S.pop() 
  # 6            if v is not labeled as discovered:
  # 7                label v as discovered
  # 8                for all edges from v to w in G.adjacentEdges(v) do
  # 9                    S.push(w)
end

#-----------------------------------------------------------
# the following is a parser that reads in a simpler version
# of the maze files.  Use it to get started writing the rest
# of the assignment.  You can feel free to move or modify 
# this function however you like in working on your assignment.

def read_and_print_simple_file(file)
  line = file.gets
  if line == nil then return end

  # read 1st line, must be maze header
  sz, sx, sy, ex, ey = line.split(/\s/)
  puts "header spec: size=#{sz}, start=(#{sx},#{sy}), end=(#{ex},#{ey})"

  # read additional lines
  while line = file.gets do

    # begins with "path", must be path specification
    if line[0...4] == "path"
       p, name, x, y, ds = line.split(/\s/)
       puts "path spec: #{name} starts at (#{x},#{y}) with dirs #{ds}"

    # otherwise must be cell specification (since maze spec must be valid)
    else
       x, y, ds, w = line.split(/\s/,4)
       puts "cell spec: coordinates (#{x},#{y}) with dirs #{ds}"
       ws = w.split(/\s/)
       ws.each {|w| puts "  weight #{w}"}
    end
  end
end


#------------------------------------------------------------------------------
# EXECUTABLE CODE
#------------------------------------------------------------------------------

#----------------------------------
# check # of command line arguments

if ARGV.length < 2
  fail "usage: maze.rb <command> <filename>" 
end

command = ARGV[0]
file = ARGV[1]
maze_file = open(file)

#----------------------------------
# perform command

case command
  
  when "parse"
    parse(maze_file)

  when "print"
    maze = Maze.new(maze_file)
    maze.pretty_print

  when "solve"
    maze = Maze.new(maze_file)
    puts maze.solvable?

  when "closed"
    maze = Maze.new(maze_file)
    maze.properties("closed")

  when "open"
    maze = Maze.new(maze_file)
    maze.properties("open")

  when "paths"
    maze = Maze.new(maze_file)
    if maze.paths.empty? 
      puts "None" 
    else 
      maze.rank_paths_by_cost
    end

  else
    fail "Invalid command"
end
