#!/usr/bin/ruby

class CmdEditor
  def initialize(fileName)
    @fileName = fileName
    self.load
  end

  def self.read(fileName)
    ed = CmdEditor.new(fileName)
    yield ed
  end

  def self.edit(fileName)
    ed = CmdEditor.new(fileName)
    result = yield ed
    ed.save
    result
  end

  def replace(line:, with:, **opts)
    if line.respond_to? :each
      if with.respond_to? :each
        raise ArgumentError.new('\'patern\' or \'gpatern\' was unexpected') if opts.has_key?(:patern) or opts.has_key?(:gpatern)
        raise ArgumentError.new('sizes of \'line\' and \'with\' doesn\'t match') unless line.size == with.size
        line.zip(with).sort { |a, b| b[0] <=> a[0] }.each { |l, w|
          replace(line: l, with: w, **opts)
        }
      else
        line.each { |l|
          replace(line: l, with: with, **opts)
        }
      end
    else
      if opts.has_key? :patern
        @data[line-1].sub!(opts[:patern], with)
      elsif opts.has_key? :gpatern
        @data[line-1].gsub!(opts[:gpatern], with)
      else
        if with.respond_to? :each
          delete(line: line)
          insert(line: line, text: with)
        else
          @data[line-1] = with
        end
      end
    end
  end

  def delete(line:)
    if line.respond_to? :sort and line.respond_to? :each
      line.sort { |a, b| b <=> a }.each { |l|
        delete(line: l)
      }
    else
      @data.delete_at(line-1)
    end
  end

  def insert(line:, text:)
    if line.respond_to? :sort and line.respond_to? :each
      if text.respond_to? :each
        raise ArgumentError.new('sizes of \'line\' and \'text\' doesn\'t match') unless line.size == text.size
        line.zip(text).sort { |a, b| b[0] <=> a[0] }.each { |l, t|
          insert(line: l, text: t)
        }
      else
        line.sort { |a, b| b <=> a }.each { |l|
          insert(line: l, text: text)
        }
      end
    else
      if text.respond_to? :each
        text.reverse.each { |t|
          insert(line: line, text: t)
        }
      else
        @data.insert(line-1, text)
      end
    end
  end

  def find(*rules, **opts)
    _beg_ = opts[:beg] || 0
    _end_ = opts[:end] || @data.size-1

    rules.each { |rule|
      rule.each { |rkey, rval|
        raise ArgumentError.new('\'any\' cannot appear in rule') if rval.has_key?(:any)

        it = find_in_range(_beg_: _beg_, _end_: _end_, **rval)
        case rkey
        when :after
          _beg_ = it + 1
        when :after_including
          _beg_ = it
        when :before
          _end_ = it - 1
        when :before_including
          _end_ = it
        end
      }
    }

    it = find_in_range(_beg_: _beg_, _end_: _end_, **opts)
    if it.respond_to? :collect
      it.collect { |i| i + 1 }
    else
      it + 1
    end
  rescue LineNotFound
    if opts.has_key? :any
      Array.new
    end
  end

  def [] index
    if index.respond_to? :each
      raise ArgumentError.new('0 is an invalid line number') if index.include?(0)
      index.collect { |i| @data[i-1].clone }
    else
      raise ArgumentError.new('0 is an invalid line number') if index == 0
      @data[index-1].clone
    end
  end

  def []= index, value
    raise ArgumentError.new('0 is an invalid line number') if index == 0

    @data[index-1] = value
  end

  def each *indexes, &block
    raise ArgumentError.new('0 is an invalid line number') if indexes.include?(0)

    Enumerator.new { |e|
      if indexes.empty?
        @data.each { |line|
          e << line.clone
        }
      else
        indexes.each { |i|
          e << @data[i-1].clone
        }
      end
    }.each(&block)
  end

  def load
    data = File.open(@fileName, 'r') { |f| f.read }
    newLines = countNewLines(data)
    data = data.split("\n")
    newLines.times {
      data << ''
    }
    @data = data
  end

  def save
    File.open(@fileName, 'w') { |f|
      f.write @data.join("\n")
    }
  end

private
  class LineNotFound < RuntimeError; end

  def find_in_range(_beg_:, _end_:, **opts)
    it =
    if opts.has_key?(:any)
      (_beg_.._end_).select { |i|
        @data[i].match(opts[:any])
      }
    elsif opts.has_key?(:first)
      @data[_beg_.._end_].index { |line| line.match(opts[:first]) }
    elsif opts.has_key?(:last)
      @data[_beg_.._end_].rindex { |line| line.match(opts[:last]) }
    elsif opts.has_key?(:matching)
      find_in_range_matching(_beg_, _end_, opts[:matching])
    end

    raise LineNotFound.new if it.nil?

    if it.respond_to? :collect
      it
    else
      it + _beg_
    end
  end

  def find_in_range_matching(_beg_, _end_, open)
    map = { '(' => ')',
            '{' => '}',
            '[' => ']',
            '<' => '>' }
    close = map[open]
    found = false
    count = 0
    @data[_beg_.._end_].each_with_index { |line, it|
      line.each_char { |ch|
        count += 1 if ch == open
        count -= 1 if ch == close
        found = true if count > 0
        return it if found and count == 0
      }
    }

    nil
  end

  def countNewLines data
    if it = data.rindex(/[^\n]/)
      (data.size-1) - it
    else
      data.size
    end
  end
end
