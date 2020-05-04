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

  def initialize fn
    @fn = fn
    @data = IO.readlines(@fn, chomp: true)
  end

  def find patern, range: nil
    range ||= lines

    to_range(range).each { |l|
      return l if @data[l-1].match(patern)
    }

    nil
  end

  def self.indent_of text
    if m = text.match(/^(\s+)\S/)
      m[1].size
    else
      0
    end
  end

  def self.indent text, indentLevel
    if indentLevel.kind_of? Integer
      text.sub(/^\s*/, ' ' * indentLevel)
    else
      text
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
    index = to_index(line)

    @data[index].sub!(patern, with)
  end

  def delete line
    @data.delete_at(to_index(line))
  end

  def update
    content = ''
    @data.each { |line|
      content += "#{line}\n"
    }

    IO.write(@fn, content)
  end

  def lines
    1..@data.size
  end

private
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
