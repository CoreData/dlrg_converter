#!/usr/bin/ruby

# This script parses a file format used by a certain type of 
# result software of the DLRG and produces NAM files for SPORTLICHT scoreboards.
#
# File format is as follows:
# First row contains athlete names, starting at column 4 to column 11,
# representing lanes 1 to 8 in the pool. 
# Second row contains event number in column 1, followed by AK and 
# style in column 2 and 3. Column 4 to column 11 contain club names corresponding
# with athlete names in row 1. 
# Line 3 of the file contains age divisions. 

require 'csv'

class Swimmer
  attr_accessor :last_name, :first_name, :club, :category

  def initialize(last_name, first_name, club, category)
    @last_name = last_name
    @first_name = first_name
    @club = club
    @category = category
  end
end

def write_lsttitpr(event_number, event_name)
  puts "Writing LSTTITPR.TXT"
  begin
    file = File.open("Ares/LSTTITPR.TXT", "a")
    reader = File.open("Ares/LSTTITPR.TXT", "r")
    header = reader.read.split(";")[0]

    if header == "event"
      file.write(sprintf("%s;0;\"%s %s\" ;\"WK %%0 Lauf %%2 %%4 %%5 %%3\" ; \"\"\n", event_number, event_name.match('\d*m')[0], event_name))
    else
      file.write("event;round;text")
      file.write(sprintf("%s;0;\"%s %s\" ;\"WK %%0 Lauf %%2 %%4 %%5 %%3\" ; \"\"\n", event_number, event_name.match('\d*m')[0], event_name))
    end
  rescue IOError => e
    print "Whoops. Write error: #{e}"
  ensure 
    file.close unless file == nil
  end
end

def write_lstrace(event_number, event_category)
  puts "Writing LSTRACE.TXT"
  begin
    file = File.open("Ares/LSTRACE.TXT", "a")
    reader = File.open("Ares/LSTRACE.TXT", "r")
    header = reader.read.split(";")[0]

    case event_category
    when "mixed"
      event_category = "X"
    when "weiblich"
      event_category = "W"
    when "männlich"
      event_category = "M"
    end
    if header == "event"
      file.write(sprintf("%s ;0 ;0 ;0 ;0 ;\"%s\" ;\"09/14/13\" ;\"00:00\" ;\n", event_number, event_category))
    else
      file.write("event;round;nbHeat;idLen;idStyle;abCat;date;time\n")
      file.write(sprintf("%s ;0 ;0 ;0 ;0 ;\"%s\" ;\"09/14/13\" ;\"00:00\" ;\n", event_number, event_category))
    end
  rescue IOError => e
    print "Whoops. Write error: #{e}"
  ensure 
    file.close unless file == nil
  end
end

def write_lstlong
  puts "Writing LSTLONG.TXT"
  begin
    file = File.open("Ares/LSTLONG.TXT", "w")
    file.write("\"idLength\";\"Longueur\";\"Mlongueur\";\"Relais\"\n0;\"50 m\";50;0\n1;\"100 m\";100;0\n2;\"200 m\";200;0\n3;\"400 m\";400;0\n4;\"1500 m\";1500;0\n5;\"800 m\";800;0\n")
  rescue IOError => e
    puts "Whoops. Write error: #{e}"
  ensure
    file.close unless file == nil
  end
end

def write_lststyle
  puts "Writing LSTSTYLE.TXT"
  begin
    file = File.open("Ares/LSTSTYLE.TXT", "w")
    file.write("idStyle;Style;StyleAbrév\n0;\"50MFREISTIL\";\"FR\"\n1;\"100MRÜCKEN\";\"BA\"\n2;\"200MBRUST\";\"BR\"\n3;\"50MRÜCKEN\";\"BA\"\n4;\"100MFREISTIL\";\"FR\"\n5;\"50MBRUST\";\"BR\"\n6;\"50MSCHMETTERLING\";\"BU\"\n7;\"100MRÜCKENFINALE\";\"BA\"\n8;\"100MFREISTILFINALE\";\"FR\"\n9;\"200MSCHMETTERLING\";\"BU\"\n10;\"400MLAGEN\";\"ME\"\n11;\"1500MFREISTIL\";\"FR\"\n12;\"800MFREISTIL\";\"FR\"\n13;\"200MFREISTIL\";\"FR\"\n14;\"100MBRUST\";\"BR\"\n15;\"200MRÜCKEN\";\"BA\"\n16;\"100MSCHMETTERLING\";\"BU\"\n17;\"400MFREISTIL\";\"FR\"\n18;\"100MBRUSTFINALE\";\"BR\"\n19;\"100MSCHMETTERLINGFINALE\";\"BU\"\n20;\"200MLAGEN\";\"ME\"\n")
  rescue IOError => e
    puts "Whoops. Write error: #{e}"
  ensure 
    file.close unless file == nil
  end
end

def write_lstcat
  puts "Writing LSTCAT.TXT"
  begin
    file = File.open("Ares/LSTCAT.TXT", "w")
    file.write("\"Kategorie\";\"AbrCat\"\n\"weiblich\";\"W\"\n\"männlich\";\"M\";\n\"mixed\";\"X\"\n")
  rescue IOError => e
    puts "Whoops. Write error: #{e}"
  ensure
    file.close unless file == nil
  end
end

def write_lststart(event, lane, bib)
  puts "Writing LSTSTART.TXT for event: #{event}"
  begin
    file = File.open("Ares/LSTSTART.TXT", "a")
    reader = File.open("Ares/LSTSTART.TXT", "r")
    header = reader.read.split(";")[0]
    # Header already written
    if(header == "event")
      file.write(sprintf("%s;%s;%s;%s;%s;%s;\n", event,0,0,lane,0,bib))
    else
      # File has just been created, write header and first data line
      file.write("event;round;heat;lane;relais;idBib\n") 
      file.write(sprintf("%s;%s;%s;%s;%s;%s;\n", event,0,0,lane,0,bib))
    end
  rescue IOError => e
    puts "Whoops. Write error: #{e}"
  ensure
    reader.close unless reader == nil
    file.close unless file == nil
  end
end

def write_lstconc(swimmers)
  puts "Writing LSTCONC.TXT"
  begin
    file = File.open("Ares/LSTCONC.TXT", "a")
    file.write("id;bib;lastname;firstname;birthyear;abNat;abCat\n")

    swimmers.each do |key, value|
      file.write(sprintf("%s;\"%s\";\"%s\";\"%s\";\"%s\";\"%s\";\"%s\";\n", key,key, value.last_name, value.first_name, 0, value.club, value.category))
    end
  rescue IOError => e
    puts "Whoops. File write error: #{e}"
  ensure 
    file.close unless file == nil
  end
end

line = 1
event_number = 1
event_name = ""
bib = 1
setting = Hash.new
swimmers = Hash.new

# read file in
CSV.foreach('Laufliste.csv', :headers => true, :col_sep => ';', encoding: "iso-8859-1:UTF-8") do |row|
  # Line 1 of the CSV holds athletes names
  if line == 1
    1.upto(8) do |i|
      if row[2+i] != nil
        name = row[2+i].split(',')
        setting[i] = Swimmer.new(name[0], name[1].strip, "", "")
      else
        setting[i] = Swimmer.new(nil, nil, nil, nil)
      end
    end
  # Line 2 of the CSV holds event number, event name, category and athlete's club
  elsif line == 2
    event_number = row[0]      
    event_name = row[2]
    event_category = row[1].split(" ")[1]
      
    1.upto(8) do |i|
      setting[i].club = row[2+i]
    end
    
    # Write NAM file for the heat.
    file_name = sprintf("%04d", event_number) << "001.NAM"
    Dir.mkdir("OMEGA") unless File.exists?("OMEGA") 
    Dir.mkdir("Ares") unless File.exists?("Ares") 
    puts "Writing NAM files for event: #{event_number}.\n"

    begin 
      file = File.open("OMEGA/#{file_name}", "w")
      setting.each do |swimmer|
        #Format string #Whitespace #LaneNumber #LastName #FirstName, #Club
        file.write(sprintf(" %s%-30s%-30s%s\n", swimmer[0], swimmer[1].last_name, swimmer[1].first_name, swimmer[1].club))
      end
    rescue IOError => e
      puts "Whoops. Write error: #{e}."
    ensure
      file.close unless file == nil
    end
    
    # Create STEUER.TXT 
    begin
      puts "Processing STEUER.TXT for event: #{event_number}"
      file = File.open("OMEGA/STEUER.TXT", "a")

      case event_category
      when "w"
        event_category = "weiblich"
      when "m"
        event_category = "männlich"
      when "gem."
        event_category = "mixed"
      end
      
      # Format string: #EventNumber, #Count #Distance #Number #Category
      file.write(sprintf("%-6s1 x%6s %-21s%s\n", event_number, event_name.match('\d*')[0], event_name.match('\D+')[0][2,16], event_category))
    rescue IOError => e
      puts "Whoops. Write error: #{e}."
    ensure
      file.close unless file == nil
    end

    # Write LSTTITPR.TXT
    # INSERT CODE HERE
    write_lsttitpr(event_number, event_name)
    write_lstrace(event_number, event_category)

  elsif line == 3
    found = false
    1.upto(8) do |i|
      if row[2+i] == nil
        setting[i].category = nil
      else
        category = row[2+i].split[2]      
        case category
        when "männlich"
          setting[i].category = "m"
        when "weiblich"
          setting[i].category = "w"
        end
      end
      p setting[i].last_name   
      swimmers.each do |key, value|
        if value.last_name == setting[i].last_name && value.first_name == setting[i].first_name
          found = true
          if key == 1
            write_lststart(event_number, i, 0) 
          else
            write_lststart(event_number, i, key)
          end
        end
      end
      
      if found == false
        if setting[i].last_name == nil
          write_lststart(event_number, i, 1)
        else
          swimmers[bib] = setting[i]
          write_lststart(event_number, i, bib)
          bib += 1
        end
      end
    end
  end
  
  if line == 1 || line == 2
    line += 1
  else
    line = 1
  end
end

write_lstconc(swimmers)
write_lstcat
write_lstlong
write_lststyle
