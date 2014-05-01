#!/usr/local/bin/ruby

def gen_open
	
	dirs = Array.new

	# u
	ran = 1 + rand(6)
	if ran.odd?
		dirs.push('u')
	end

	# d
	ran = 1 +  rand(6)
	if ran.odd?
		dirs.push('d')
	end

	# l
	ran = 1 + rand(6)
	if ran.odd?
		dirs.push('l')
	end

	# r
	ran = 1 + rand(6)
	if ran.odd?
		dirs.push('r')
	end
	return dirs
end

def gen_float
	ran = rand * rand(10)
end

def gen_int
	ran = rand(SIZE)
end

def letter?(lookAhead)
  lookAhead =~ /[[:alpha:]]/
end

def numeric?(lookAhead)
  lookAhead =~ /[[:digit:]]/
end

if ARGV.length < 1
  fail "usage: mazeGen.rb <size>" 
end

command = ARGV[0]
SIZE = command.to_i

cells = Array.new(SIZE) { Array.new(SIZE, Array.new) }
puts SIZE.to_s + " " + gen_int.to_s + " " + gen_int.to_s + " " + gen_int.to_s + " " + gen_int.to_s


for x in 0...SIZE
	for y in 0...SIZE
		dirs = gen_open
		cells[x][y] = dirs.dup

		if cells[x][y-1].include?('r')
			cells[x][y].delete('l')
			cells[x][y].push('l')
		else
			cells[x][y].delete('l')
		end

		if cells[x-1][y].include?('d')
			cells[x][y].delete('u')
			cells[x][y].push('u')
		else
			cells[x][y].delete('u')
		end

		len = cells[x][y].length
		i = 0
		while i < len

			cells[x][y].push(gen_float)
			i += 1
		end
	end
end


y = x = 0
d = "u"
while y < SIZE
	if cells[x][y].delete(d) != nil
		cells[x][y].pop
	end
	y += 1
end


y = y - 1
x = 0
d = "r"
while x < SIZE
	if cells[x][y].delete(d) != nil
		cells[x][y].pop
	end
	x += 1
end


x = 0
y = 0
d = "l"
while x < SIZE
	if cells[x][y].delete(d) != nil
		cells[x][y].pop
	end
	x += 1
end

x = x - 1
y = 0
d = "d"
while y < SIZE
	if cells[x][y].delete(d) != nil
		cells[x][y].pop
	end
	y += 1
end

# used for std maze files
# $comma = ","
# $colon = ": "
for x in 0...SIZE
	for y in 0...SIZE
		print y.to_s, ",", x.to_s, ": " 
		cells[x][y].each { |c| 
			print c, 
			if !letter?(c)
				print " "
			end
		}
		print "\n"
	end
	# print "\n"
end
