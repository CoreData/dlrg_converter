#!/usr/bin/ruby

require 'csv'
require 'time'

POOL_LANES = 8

class Swimmer
  attr_accessor :first_name, :last_name, :club, :category
  attr_reader :birth_year

  def initialize(first_name = "", last_name = "", club = "", category = "")
    @first_name = first_name
    @last_name = last_name
    @club = club
    @category = category
    @birthyear = "1990"
  end
end

class Event
  attr_accessor :number, :name, :distance, :category, :heat

  def initialize(number=0, name="", distance="", category="", heat={})
    @number = number
    @name = name
    @distance = distance    
    @category = category
    @heat = heat
  end
end

class Tournament
  attr_accessor :name, :date, :start_time, :events

  def initialize(name, date, events = [])
    @name = name
    @date = Date.parse(date)
    @start_time = Time.parse(date)
    @events = events
  end
end

class FileWriter
  attr_accessor :filename, :payload

  def initialize(filename, payload)
    @filename = filename
    @payload = payload
    
    @scoreboard_dir = "_SCOREBOARD_"
    @ares_dir = "_Ares_"

    Dir.mkdir(@scoreboard_dir) unless File.exists? @scoreboard_dir 
    Dir.mkdir(@ares_dir) unless File.exists? @ares_dir

    if @filename == "STEUER.TXT" || @filename.match("NAM")
      @filename = @scoreboard_dir << "/" << @filename
    elsif @filename.match("LST")
      @filename = @ares_dir << "/" << @filename
    else
      raise "We can't handle this filename."
    end

    self.write_file
  end

  def write_file
    begin
      file = File.open(@filename, "a:iso-8859-1")
      file.write(@payload)
    rescue IOError => e
      puts "Error while writing #{@filename}: #{e}."
    ensure
      file.close unless file == nil
    end
  end
end

class Storage
  def initialize
    @storage = Hash.new
    @key = 0
  end
  
  def add candidate
    if self.stored? candidate
      candidate 
    else
      @storage[@key] = candidate
      @key += 1 
    end
  end
  
  def list
    @storage.each do |key, value|
      value
    end
  end
  
  def stored? candidate
    @storage.value? candidate
  end
  
  def storage_id candidate
    @storage.each do |key, value|
      if value == candidate
        return key
      end
    end
  end
end


##################
#
# Data processing
#
##################

line = 1
setting = Hash.new
event = Event.new
tournament = Tournament.new "Salzpokal DLRG", "2013-09-14 09:00"
styles = Storage.new
distances = Storage.new

raise "Please provide a filename as argument." unless ARGV.length > 0

CSV.foreach(ARGV[0], :headers => true, :col_sep => ',', :encoding => 'iso-8859-1:UTF-8') do |row|
  if line == 1
    1.upto POOL_LANES do |i|
      if row[2+i] == nil || row[2+i].length == 0
        setting[i] = nil
      else
        first_name = row[2+i].split(',')[1].strip
        last_name = row[2+i].split(',')[0]
        setting[i] = Swimmer.new first_name, last_name, nil, nil
      end
    end
  elsif line == 2
    1.upto POOL_LANES do |i|
      number = row[0]
      category = row[1].split(" ")[2]
      name = row[2]
      club = row[3]
      distance = row[2].split(" ")[0].strip
      event = Event.new number, name, distance, category
      styles.add event.name.match('\D+')[0][2, event.name.length]
      distances.add event.name.match('\d{1,3}')[0]

      setting.each do |key, value|
        value.club = row[2+key]unless value == nil
        event.heat[key] = value
      end
    end
  elsif line == 3
    1.upto POOL_LANES do |i|
      event.heat[i].category = row[2+i].split(" ").last unless row[2+i] == nil || row[2+i].length == 0
    end
  else
    raise "We are on a line count > 3. This is wrong."
  end

  if line < 3
    line += 1
  elsif line == 3
    tournament.events.push event
    line = 1
  end
end

#tournament.events.each do |event|
#  puts "###"
#  puts event.number
#  event.heat.each do |key, value|
#    puts "#{key}: #{value.inspect}"
#  end
#end

#############
#
# File processing
#
#############

# ARES files
# LSTCAT.TXT
#header = "\"Kategorie\";\"AbrCat\"\r\n"
#body = "\"weiblich\";\"W\"\r\n\"männlich\";\"M\"\r\n\"mixed\";\"X\"\r\n"
#FileWriter.new "LSTCAT.TXT", header << body

# LSTLONG.TXT
#header = "\"idLength\";\"Longueur\";\"MLongueur\";\"Relais\"\r\n"
#body = "0;\"50 m\";50;0\r\n1;\"100 m\";100;0\r\n2;\"200 m\";200;0\r\n3;\"400 m\";400;0\r\n4;\"800 m\";800;0\r\n5;\"1500 m\";1500;0\r\n6;\"4x100m\";400;4\r\n7;\"4x200m\";800;4\r\n8;\"4x50 m\";200  ;4\r\n9;\"25 m\";25;1"
#FileWriter.new "LSTLONG.TXT", header << body

# LSTRACE.TXT
#header = "event;round;nbHeat;idLen;idStyle;abCat;date;time\r\n"
#FileWriter.new "LSTRACE.TXT", header

tournament.events.each do |event|
# STEUER.TXT
  # We need a certain entry for the event category in this file
  case event.category
  when 'w'
    event_category = "weiblich"
  when 'm'
    event_category = "männlich"
  when 'gem.'
    event_category = "mixed"
  end
   #Format string: #EventNumber, #Count #Distance #Number #Category
  FileWriter.new("STEUER.TXT", sprintf("%-6s1 x%6s %-21s%s\r\n", event.number, event.name.match('\d*m')[0], event.name.match('\D+')[0][2,10], event_category))

#  FileWriter.new "LSTRACE.TXT", sprintf("%s;%s;%s;%s;%s;%s;%s;\r\n", event.number, 0,0,1,styles.style_id(event.name.match('\D+')[0][2,event.name.length]),tournament.date,tournament.start_time+1) 
  # NAM File
  filename = sprintf("%05d", event.number) << "001.NAM"
  event.heat.each do |key, value|
    #puts "#{key.class}: #{value}"
    if value == nil
      FileWriter.new filename, sprintf("%02d\r\n", key) 
    else
     #Format string #Whitespace #LaneNumber #LastName #FirstName, #Club
     FileWriter.new filename, sprintf("%02d%-30s%-30s%-20s\r\n", key, value.last_name, value.first_name, value.club[0..19])
    end
  end
end
