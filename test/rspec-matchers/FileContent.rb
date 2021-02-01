RSpec::Matchers.define(:file_content) {
  match { |actual|
    if actual.is_a? Proc
      @actual = IO.read(actual.call)
    else
      @actual = IO.read(actual)
    end

    case @op
    when :==
      @actual == @expected
    when :include
      @expected.all? { |exp|
        !!@actual.split("\n").find { |a| a == exp }
      }
    else
      raise('Invalid op')
    end
  }

  failure_message { |actual|
    case @op
    when :==
      "expected to contain data:\n#{@expected.inspect}, but it is:\n#{@actual.inspect}"
    when :include
      "expected to include lines: #{@expected}, but it is:\n#{@actual.inspect}"
    end
  }

  chain(:eq) { |arg|
    @op = :==
    @expected = arg
  }

  chain(:eq_lines) { |*args|
    @op = :==
    @expected = args.join("\n")
  }

  chain(:include) { |arg|
    @op = :include
    @expected ||= []
    @expected << arg
  }

  supports_block_expectations
}


