#!/usr/bin/ruby

require_relative '../lib/cmd-editor'

require_relative 'UtUtility'

class TestCmdEditor < Test::Unit::TestCase
  include UtUtility

  context('TestCmdEditor.[]') {
    merge_block(&UtUtility.defTeardown)

    setup {
      setFileContent(['line1', 'line2', 'line3'])

      @yielded = Array.new
    }

    should('access single line') {
      CmdEditor.read(@fn) { |e|
        assert_equal('line2', e[2])
      }
    }

    should('access few lines') {
      CmdEditor.read(@fn) { |e|
        assert_equal(['line1', 'line3'], e[[1,3]])
      }
    }

    should('raise argument error when passing \'0\' as index when accessing line') {
      CmdEditor.read(@fn) { |e|
        assert_raise(ArgumentError) {
          e[0]
        }
      }
    }

    should('yield every line') {
      CmdEditor.read(@fn) { |e|
        e.each { |line| @yielded << line }
      }

      assert_equal(['line1', 'line2', 'line3'], @yielded)
    }

    should('yield single line') {
      CmdEditor.read(@fn) { |e|
        e.each(3) { |line| @yielded << line }
      }

      assert_equal(['line3'], @yielded)
    }

    should('yield few lines') {
      CmdEditor.read(@fn) { |e|
        e.each(1,3) { |line| @yielded << line }
      }

      assert_equal(['line1', 'line3'], @yielded)
    }

    should('raise argument error when passing \'0\' as one of indexes when accessing line') {
      CmdEditor.read(@fn) { |e|
        assert_raise(ArgumentError) {
          e.each(1,0,3)
        }
      }
    }
  }
end

