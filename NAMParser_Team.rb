#!/usr/bin/ruby

require 'csv'
require 'time'

POOL_LANES = 8

class Team
  attr_accessor :name, :club

  def initialize(name = "", club = "", category = "")
    @name = name
    @club = club
    @category = category
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
  attr_accessor :name, :date, :events

  def initialize(name, date, events = [])
    @name = name
    @date = Date.parse(date)
    @events = events
  end
end

class FileWriter
  attr_accessor :filename, :payload

  def initialize(filename, payload)
    @filename = filename
    @payload = payload
    @omega_dir = "OMEGA"
    @ares_dir = "Ares"
    
    Dir.mkdir(@omega_dir) unless File.exists? @omega_dir 
    Dir.mkdir(@ares_dir) unless File.exists? @ares_dir

    case
    when "STEUER.TXT" || @filename.match("NAM")
      @filename = @omega_dir << "/" << @filename
    when @filename.match("LST")
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

##################
#
# Data processing
#
##################

line = 1
setting = Hash.new
event = Event.new
tournament = Tournament.new "Salzpokal DLRG", "2013-09-14 09:00"
CSV.foreach('ll_finals_team.csv', :headers => true, :col_sep => ',', :encoding => 'iso-8859-1:UTF-8') do |row|
  if line == 1
    1.upto POOL_LANES do |i|
      if row[2+i] == nil || row[2+i].length == 0
        setting[i] = nil
      else
        name = row[2+i].split(',')[0]
        category = row[1].split(" ").last
        setting[i] = Team.new name, nil, category
      end
    end
    number = row[0].to_i + 100
    category = row[1].split(" ")[1]
    name = row[2]
    distance = row[2].split(" ")[0].strip
    event = Event.new number, name, distance, category
  elsif line == 2
    1.upto POOL_LANES do |i|
      setting.each do |key, value|
        value.club = row[2+key]unless value == nil
        event.heat[key] = value
      end
    end
  else
    raise "We are on a line count > 2. This is wrong."
  end

  if line == 1
    line += 1
  elsif line == 2
    tournament.events.push event
    line = 1
  end
end

#tournament.events.each do |event|
#  puts "###"
#  puts "#{event.number}: #{event.name}"
#  event.heat.each do |key, value|
#    puts "#{key}: #{value.inspect}"
#  end
#end

#############
#
# File processing
#
#############

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
  FileWriter.new("STEUER.TXT", sprintf("%-6s4 x%6s %-21s%s\r\n", event.number, event.name.split(" ").first, event.name.split(" ").last[0..10], event_category))

  # NAM Files
  filename = sprintf("%05d", event.number) << "001.NAM"
  event.heat.each do |key, value|
    #puts "#{key.class}: #{value}"
    if value == nil
      FileWriter.new filename, sprintf("%02d\r\n", key) 
    else
     #Format string #Whitespace #LaneNumber #LastName #FirstName, #Club
     FileWriter.new filename, sprintf("%02d%-30s%-20s\r\n", key, value.name, value.club[0..19])
    end
  end
end
