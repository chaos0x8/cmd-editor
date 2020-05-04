#!/usr/bin/env ruby

require_relative '../lib/cmd-editor/CmdEditor'

require 'test/unit'
require 'shoulda'
require 'mocha'

require 'tempfile'

class TestCmdEditor < Test::Unit::TestCase
  context('TestCmdEditor') {
    setup {
      @tmp = Tempfile.new File.basename(__FILE__)
      @tmp.write([
        "int main() {",
        "  return 0;",
        "}"
      ].join "\n")
      @tmp.close
    }

    teardown {
      @tmp.unlink
    }

    should('return number of lines') {
      CmdEditor.open(@tmp.path) { |e|
        assert_equal(1..3, e.lines)
      }
    }

    should('find patern') {
      CmdEditor.open(@tmp.path) { |e|
        assert_equal(2, e.find(/return \d;/))
        assert_equal(2, e.find('return 0;'))
        assert_equal(2, e.find('return 0;', range: 1))
        assert_equal(2, e.find('return 0;', range: 2))
        assert_equal(2, e.find('return 0;', range: [1,2]))
        assert_equal(2, e.find('return 0;', range: [2]))
        assert_equal(2, e.find('return 0;', range: 1..2))
        assert_equal(2, e.find('return 0;', range: 2..2))
      }
    }

    should('find patern not find patern when it is outside of range') {
      CmdEditor.open(@tmp.path) { |e|
        assert_equal(nil, e.find('return 0;', range: 3))
        assert_equal(nil, e.find('return 0;', range: 1..1))
        assert_equal(nil, e.find('return 0;', range: 3..3))
        assert_equal(nil, e.find('return 0;', range: [1,3]))
      }
    }

    [ 0..1, 0, 1..5, 5 ].each_with_index { |range, index|
      should("raise argument error when range is invalid/#{index}") {
        CmdEditor.open(@tmp.path) { |e|
          assert_raise(ArgumentError) {
            e.find('return 0;', range: range)
          }
        }
      }
    }

    should('return indent level') {
      assert_equal(0, CmdEditor.indent_of('x'))
      assert_equal(0, CmdEditor.indent_of('   '))
      assert_equal(1, CmdEditor.indent_of(' x  '))
      assert_equal(3, CmdEditor.indent_of('   x'))
    }

    should('return indent text') {
      assert_equal('  x', CmdEditor.indent('x', 2))
      assert_equal('  x', CmdEditor.indent(' x', 2))
      assert_equal('  x', CmdEditor.indent('    x', 2))
      assert_equal(' x ', CmdEditor.indent('x ', 1))
      assert_equal(' x ', CmdEditor.indent(' x ', 1))
      assert_equal(' x ', CmdEditor.indent('    x ', 1))
    }

    should('add line to file') {
      CmdEditor.edit(@tmp.path) { |e|
        e.insert 1, ['#include <iostream>', '']
        e.insert e.find('return 0;'), 'std::cout << "Hello world!" << std::endl;', indentMode: :next
      }

      expected = [
        "#include <iostream>",
        "",
        "int main() {",
        "  std::cout << \"Hello world!\" << std::endl;",
        "  return 0;",
        "}"
      ]

      assert_equal(expected, IO.readlines(@tmp.path, chomp: true))
    }

    should('add replace line') {
      CmdEditor.edit(@tmp.path) { |e|
        e.replace e.find('return 0;'), 'return 0;', 'std::cout << "Hello world!" << std::endl;'
      }

      expected = [
        "int main() {",
        "  std::cout << \"Hello world!\" << std::endl;",
        "}"
      ]

      assert_equal(expected, IO.readlines(@tmp.path, chomp: true))
    }

    should('add at the end of file') {
      CmdEditor.edit(@tmp.path) { |e|
        e.insert -1, '// Bye'
      }

      expected = [
        "int main() {",
        "  return 0;",
        "}",
        "// Bye"
      ]

      assert_equal(expected, IO.readlines(@tmp.path, chomp: true))
    }

    should('delete line from file') {
      CmdEditor.edit(@tmp.path) { |e|
        e.delete e.find('return 0;')
      }

      expected = [
        "int main() {",
        "}"
      ]

      assert_equal(expected, IO.readlines(@tmp.path, chomp: true))
    }

    should('raise when insert at wrong line') {
      CmdEditor.edit(@tmp.path) { |e|
        assert_raise(ArgumentError) { e.insert 0, '' }
        assert_raise(ArgumentError) { e.insert 4, '' }
        assert_raise(ArgumentError) { e.insert 72, '' }
      }
    }

    should('raise when delete at wrong line') {
      CmdEditor.edit(@tmp.path) { |e|
        assert_raise(ArgumentError) { e.delete 0 }
        assert_raise(ArgumentError) { e.delete 4 }
        assert_raise(ArgumentError) { e.delete 72 }
      }
    }
  }
end
