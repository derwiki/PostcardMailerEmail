# frozen_string_literal: true

class ImageProcessor
  attr_accessor :file, :metadata, :filename, :format, :dimensions

  def initialize(file)
    self.file = file
    self.metadata = `identify #{self.file.path}`
    self.filename, self.format, dimensions, = metadata.split(' ')
    x, y = dimensions.split('x').map(&:to_i)
    self.dimensions = { x: x, y: y }
    puts("[ImageProcessor#initialize dimensions x:#{x}, y:#{y}")
  end

  def run
    if square?
      add_borders!
    else
      rotate!
    end
    # resize!
  end

  def ratio
    (dimensions[:x].to_f / dimensions[:y]).tap {|x| puts("[ImageProcessor#ratio] ratio: #{x}")}
  end

  def rotate!
    puts("[ImageProcessor#rotate!] entry")
    return unless rotate?
    puts("[ImageProcessor#rotate!] executing")
    execute("mogrify -rotate 90 #{file.path}")
  end

  def rotate?
    (ratio < 1).tap {|x| puts("[ImageProcessor#rotate?] #{x}")}
  end

  def square?
    puts("[ImageProcessor#square?] ratio-1 #{ratio-1}")
    ((ratio - 1).abs < 0.05).tap {|x| puts("[ImageProcessor#square?] #{x}")}
  end

  def add_borders!
    puts("[ImageProcessor#add_borders!] entry")
    return unless square?
    execute("convert #{file.path} -gravity center -background white -extent 138%x100 #{file.path}.border")
    execute("mv #{file.path}.border #{file.path}")
  end

  def resize!
    execute("mogrify -resize 2048 #{file.path}")
  end

  def execute(cmd)
    puts("[ImageProcessor#cmd] #{cmd}")
    `#{cmd}`.tap { |x| puts("[output] #{x}") }
  end
end
