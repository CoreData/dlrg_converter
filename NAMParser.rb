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
  attr_accessor :number, :name, :category, :heat

  def initialize(number=0, name="", category="", heats={})
    @number = number
    @name = name
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

# STEUER.TXT
  # We need a certain entry for the event category in this file
  #case event.category
  #when 'w'
  #  event_category = "weiblich"
  #when 'm'
  #  event_category = "männlich"
  #when 'gem.'
  #  event_category = "mixed"
  #end
  # Format string: #EventNumber, #Count #Distance #Number #Category
  #FileWriter.new("STEUER.TXT", sprintf("%-6s1 x%6s %-21s%s\r\n", event.number, event.name.match('\d*m')[0], event.name.match('\D+')[0][2,16], event_category))
#end

  # NAM Files
  # 
  #file_name = sprintf("%05d", event.number) << "001.NAM"
  #event.heat.each do |heat|
    #Format string #Whitespace #LaneNumber #LastName #FirstName, #Club
    #puts heat[1].first_name
    #FileWriter.new file_name, sprintf("%02d%-30s%-30s%-20s\r\n", heat[0], heat[1].last_name, heat[1].first_name, heat[1].club[0..19])
  #end
