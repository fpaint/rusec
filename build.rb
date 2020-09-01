#!/usr/bin/env ruby

require 'zip'
require 'fileutils'
require 'action_view'
require 'facets/file'

#=====================================================
class Helper
  extend ActionView::Helpers::TextHelper
end

#=====================================================
class Entry

  attr_reader :author, :title, :file, :lang

  def initialize(author:, genre:, title:, file:, ext:, lang:, **rest)
    @author = (author.split(':').first || '_').split(',').join(' ').gsub(/\.$/, '').gsub(/\./, '_')
    @genre = genre.split(':').reject(&:empty?)
    @title = title || '_'
    @file = file
    @ext = ext
    @lang = lang
  end

  def filename
    "#{@file}.#{@ext}"
  end

  def ru?
    @lang == 'ru' 
  end

  def to_s
    "#{filename}: #{@author}, \"#{@title}\" (#{@genre.join(',')})"
  end

  def output_file
    genre = genre_str
    author = @author
    title_full = @title.gsub(/[^[[:alnum:]]]+/, ' ').strip.gsub(/\s/, '_')
    title = Helper.truncate(title_full, length: 100, separator: '_', omission: '')
    "#{genre}/#{author}/#{title}_#{@file}.#{@ext}"
  end

  def genre_str
    child_genre || @genre
  end

  def child_genre
    return @child_genre if instance_variable_defined?("@child_genre")
    genres = {
      "child_tale" => "Fairy Tales",
      "child_ver" => "Verses for Kids",
      "child_pro" => "Prose for Kids",
      "child_sf" => "Science Fiction for Kids",
      "child_det" => "Detective for Kids",
      "child_adv" => "Adventures for Kids",
      "child_education" => "Education for Kids",
      "children" => "For Kids Misk",
      "child_folklore" => "Child Folklore",
      "prose_game" => "Game book"
    }
    genre = @genre.find{|x| genres[x]}
    @child_genre = genre ? genres[genre] : nil
  end

end

#=====================================================
class Extractor

  def initialize(filename, output_path)
    @filename = filename
    @output_path = output_path
  end

  def extract(entries)
    Zip::File.open(@filename) do |zip|
      entries.each do |entry|
        file = zip.find_entry(entry.filename)
        if(file)
          filename = "#{@output_path}/#{entry.output_file}"
          if(File::exists?(filename))
            puts "Skip #{filename}, already exists"
          else
            puts "Extract #{filename}"
            create_path(filename)
            file.extract(filename)
          end
        end
      end
    end
  end

  def create_path(filename)
    path = File.dirname(filename)
    unless File.directory?(path)
      puts "Creating folder #{path}"
      FileUtils.mkpath(path)
    end
  end

end

#=====================================================
class InpReader 

  def self.read(data)
    entries = []
    data.each do |line|
      entry = self.read_line(line)
      entries << entry if(entry.ru? && entry.child_genre) 
    end
    entries
  end

  def self.read_line(line)
    keys = [:author, :genre, :title, :series, :serno, :file, :size, :libid, :del, :ext, :date, :lang]
    record = keys.zip(line.force_encoding('UTF-8').split(/\x04/)).to_h
    Entry.new(record)
  end

end

#=====================================================
class Contents 

  def initialize
    @books = {}
  end

  def add(entries)
    entries.each do |entry|
      key = entry.genre_str
      @books[key] ||= []
      @books[key] << "#{entry.author}, \"#{entry.title}\""
    end
  end

  def write(output_path)
    @books.keys.each do |key|
      filename = "#{output_path}/#{key}.txt"
      File.writelines filename, @books[key].sort
    end
  end

end

#=====================================================
class InpxReader 
  
  INPX_FILENAME = 'librusec_local_fb2.inpx'

  def initialize(input_path, output_path)
    @input_path = input_path
    @output_path = output_path
    @contents = Contents.new 
  end

  def extract
    Zip::File.open("#{@input_path}/#{INPX_FILENAME}") do |zip|
      # extract_file zip.glob('*.inp').first
      zip.glob('*.inp').each{|file| extract_file(file)}
    end
    @contents.write(@output_path)
  end

  def extract_file(file)
    name = file.name.split('.').first
    entries = InpReader.read(file.get_input_stream.readlines)
    puts "File #{name}, #{entries.count} book found"
    extractor = Extractor.new("#{@input_path}/lib.rus.ec/#{name}.zip", @output_path)
    extractor.extract(entries)
    @contents.add(entries)
  end

end

input_path = '/media/andrew/Backup/Library/_Lib.rus.ec - Официальная'
output_path = '/media/andrew/Backup/Library/Rusec'

reader = InpxReader.new(input_path, output_path)
reader.extract
