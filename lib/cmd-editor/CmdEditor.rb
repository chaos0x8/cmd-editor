#!/usr/bin/ruby

class CmdEditor
  def self.open fn
    editor = CmdEditor.new fn
    yield editor
  end

  def self.edit fn
    editor = CmdEditor.new fn
    yield editor
    editor.update
  end

  attr_reader :path

  def initialize fn
    @path = File.expand_path(fn)
    @data = IO.readlines(@path, chomp: true)
  end

  def [] line
    if line.respond_to? :each
      each_index(line).collect { |index|
        @data[index]
      }
    else
      @data[to_index(line)]
    end
  end

  def []= line, value
    value = [value].flatten

    indexes = each_index(line).to_a
    indexes[0..value.size-1].each_with_index { |index, vi|
      @data[index] = value[vi]
    } if value.size > 0 and indexes.size > 0

    if indexes.size > value.size
      indexes[value.size..-1].reverse_each { |index|
        @data.delete_at(index)
      }
    end

    if value.size > indexes.size
      value[indexes.size..-1].reverse_each { |line|
        @data.insert(indexes.last+1, line)
      }
    end

    nil
  end

  def find patern, range: nil
    range ||= lines

    if patern.kind_of? Array
      find_range(patern, range: range)
    else
      find_single(patern, range: range)
    end
  end

  def self.indent_of text
    if m = text.match(/^(\s+)\S/)
      m[1].size
    else
      0
    end
  end

  def self.indent text, indentLevel
    if text.respond_to? :each
      CmdEditor.indent_range text, indentLevel
    else
      CmdEditor.indent_single text, indentLevel
    end
  end

  def insert line, text, indentMode: nil
    index = to_index(line)

    indentLevel = to_indentLevel(indentMode, index)

    if text.respond_to? :each
      text.reverse_each { |item|
        @data.insert(index, CmdEditor.indent(item, indentLevel))
      }
    else
      @data.insert(index, CmdEditor.indent(text, indentLevel))
    end
  end

  def replace line, patern, with
    each_index(line) { |index|
      @data[index].sub!(patern, with)
    }
  end

  def delete line
    each_index(line).sort.reverse_each { |index|
      @data.delete_at(index)
    }
  end

  def update
    content = ''
    @data.each { |line|
      content += "#{line}\n"
    }

    IO.write(@path, content) if content != IO.read(@path)
  end

  def lines
    1..@data.size
  end

private
  def self.indent_single text, indentLevel
    if indentLevel.kind_of? Integer
      text.sub(/^\s*/, ' ' * indentLevel)
    else
      text
    end
  end

  def self.indent_range text, indentLevel
    text.collect { |x| CmdEditor.indent_single(x, indentLevel) }
  end

  def find_single patern, range:
    to_range(range).each { |l|
      return l if @data[l-1].match(patern)
    }

    nil
  end

  def find_range paterns, range:
    found = []

    to_range(range).each { |l|
      found << l if @data[l-1].match(paterns[found.size])

      if found.size == paterns.size
        return found.first..found.last
      end
    }

    nil
  end

  def to_index line
    unless line.kind_of? Integer
      raise ArgumentError.new "Expected line number, but got: #{line}"
    end

    if lines.include? line
      line - 1
    elsif line == -1
      @data.size
    else
      raise ArgumentError.new "Invalid line value: #{line}"
    end
  end

  def each_index line, &block
    if line.respond_to? :each
      line.collect { |l| to_index(l) }.each(&block)
    else
      [to_index(line)].each(&block)
    end
  end

  def to_indentLevel mode, index
    return mode if mode.kind_of? Integer
    return CmdEditor.indent_of(@data[index-1]) if mode == :prev and index >= 1
    return CmdEditor.indent_of(@data[index]) if [:next, :keep].include?(mode) and index < @data.size
    return nil
  end

  def to_range v
    if v.respond_to? :each and v.respond_to? :all?
      unless v.all? { |x| lines.include? x }
        raise ArgumentError.new "Invalid range value: #{v}"
      end

      v
    elsif v.kind_of? Integer
      raise ArgumentError.new "Invalid range value: #{v}" unless lines.include? v

      v..@data.size
    else
      raise ArgumentError.new "Invalid range type: #{v.class}"
    end
  end
end
