#!/bin/ruby
require 'optparse'

class ProfileLabel
  attr_accessor :label, :methods, :count, :timestamp

  def initialize(label, timestamp, count=1 , methods={})
    @label = label
    @timestamp = timestamp
    @methods = methods
    @count = count
    @method_no = 0
  end

  def +(other)
    raise "Could not add profile method #{@label} to #{other.label}" if @label != other.label
    merged_methods = @methods.merge(other.methods) do |key, old, new|
      if old.nil?
        new
      elsif new.nil?
        old
      else
        old + new
      end
    end
    return ProfileLabel.new @label, other.timestamp, @count + other.count, merged_methods
  end

  def add_method(method)
    method.number = @method_no
    @method_no = @method_no.succ
    if @methods[method.name].nil?
      @methods[method.name] = method
    else
      @methods[method.name] = @methods[method.name] + method
    end
  end

  def to_s
    rt = "Label:#{@label} count:#{@count}\r\n"
    total_vals = @methods.values.inject(0){|sum,m| sum = sum + m.value}
    @methods.sort_by{|_,v| v.number}.each do |_, method|
      prop = method.value / total_vals * 100
      prop = sprintf "%-10.2f", prop
      prop = prop.rstrip!
      prop << "%"
      rt << "    " << method.format(prop) << "\r\n"
    end
    rt << "\r\n"
  end
end

class ProfileMethod
  attr_accessor :name, :value, :count, :max, :min, :number

  def initialize(name, value, count=1,  min=-1, max= -1)
    @name = name
    @value = value
    @min = @max = value
    @min = min if min > 0
    @max = max if max >0
    @count = count
  end
  
  def +(other)
    raise "Could not add profile method #{@name} to #{other.name}" if @name != other.name
    min = @min < other.min ? @min : other.min
    max = @max < other.max ? other.max : @max
    new_method = ProfileMethod.new @name, @value + other.value, @count + other.count, min, max
    new_method.number = other.number
    return new_method
  end

  def mean_value
    @value.to_f / @count
  end

  def to_s
    sprintf "Method: %-50s mean: %-10.2f min: %-10.2f max: %-10.2f count: %-10d", @name, mean_value, @min, @max, @count
  end
  def format(prop)
    sprintf "Method: %-50s mean: %-10.2f min: %-10.2f max: %-10.2f count: %-10d proportion: %-10s", @name, mean_value, @min, @max, @count, prop
  end
end

class LogParser
  def initialize(options)
    @opts = options
    @labels = {}
    @methods = {}
  end
  def parse
    current_labels = {}
    File.open @opts[:file], "r" do |f|
      while !f.eof? and line = f.readline
        if line =~ /\[prowl\-profiler\] (.*)\-(\d+) (.*) : (.*) msecs/
          label = $1
          timestamp = $2.to_i
          method_name = $3
          value = $4.to_f
          method = ProfileMethod.new method_name, value
          exists_label = current_labels[label]
          if exists_label.nil?
            #If current label is nil,create one.
            current_labels[label] = ProfileLabel.new label, timestamp
            exists_label = current_labels[label]
          else
            ##timestamp is changed,create a new label.
            if exists_label.timestamp != timestamp
              if @labels[label]
                @labels[label] = @labels[label] + exists_label
              else
                @labels[label] = exists_label
              end
              current_labels[label] = ProfileLabel.new label, timestamp
              exists_label = current_labels[label]
            end
          end
          exists_label.add_method method
          if @methods[method_name].nil?
            @methods[method_name] = method
          else
            @methods[method_name] = @methods[method_name] + method
          end
        end
      end
    end
    current_labels.each do |label_name,label|
      if @labels[label_name]
        @labels[label_name] = @labels[label_name] + label
      else
        @labels[label_name] = label
      end
    end
  end

  def to_s
    rt = "Prowl profile results:\r\n"
    rt << "Labels:\r\n"
    @labels.each do |_,label|
      rt << "  " << label.to_s
    end
    rt << "Methods:\r\n"
    @methods.each do |_,method|
      rt << "  " << method.to_s << "\r\n"
    end
    return rt
  end
end


if __FILE__ == $0
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: parse.rb [options]"

    opts.on("-f", "--file LOG_FILE", "Log file") do |f|
      options[:file] = f
    end
    opts.on("-l", "--label LABEL", "Profiled label") do |l|
      options[:label] = l
    end
    opts.on("-m", "--method METHOD", "Profiled method") do |m|
      options[:method] = m
    end
  end.parse! ARGV

  if options[:file].nil?
    STDERR.puts "Please provide log file at least by -f option."
    STDERR.puts "Usage: parse.rb [options]"
    STDERR.puts "     -h  print help menu"
    exit 1
  end
  puts "Parsing log file #{options[:file]} ..."
  parser = LogParser.new options
  parser.parse
  puts parser.to_s
end
