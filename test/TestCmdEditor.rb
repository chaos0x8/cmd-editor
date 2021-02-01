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

    should('find range') {
      CmdEditor.open(@tmp.path) { |e|
        assert_equal(2..3, e.find(['return 0;', '}']))
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

    should('return indent array') {
      assert_equal(['  x', '  y'], CmdEditor.indent(['x', ' y'], 2))
    }

    should('replace line') {
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

    should('replace range') {
      CmdEditor.edit(@tmp.path) { |e|
        e.replace e.find(['{', '}']), /(.*)/, '// \1'
      }

      expected = [ '// int main() {', '//   return 0;', '// }' ]

      assert_equal(expected, IO.readlines(@tmp.path, chomp: true))
    }

    should('return line') {
      CmdEditor.open(@tmp.path) { |e|
        assert_equal('  return 0;', e[e.find('return 0;')])
      }
    }

    should('return range') {
      CmdEditor.open(@tmp.path) { |e|
        expected = [
          'int main() {',
          '  return 0;',
          '}'
        ]

        assert_equal(expected, e[e.lines])
      }
    }

    should('change line') {
      CmdEditor.edit(@tmp.path) { |e|
        e[e.find('return 0;')] = "std::cout << \"Hello world!\" << std::endl;"
      }

      expected = [
        "int main() {",
        "std::cout << \"Hello world!\" << std::endl;",
        "}"
      ]

      assert_equal(expected, IO.readlines(@tmp.path, chomp: true))
    }

    [ "int main() { return 0; }",
      ["int main() { return 0; }"] ].each_with_index { |data, index|

      should("change bigger range/#{index}") {
        CmdEditor.edit(@tmp.path) { |e|
          e[e.lines] = data
        }

        expected = [
          "int main() { return 0; }"
        ]

        assert_equal(expected, IO.readlines(@tmp.path, chomp: true))
      }
    }

    [ 'return 0;',
      ['return 0;'] ].each_with_index { |data, index|

      should("change smaller range/#{index}") {
        CmdEditor.edit(@tmp.path) { |e|
          e[e.find(data)] = [
            '  std::cout << "Hello\n";',
            '  return 0;'
          ]
        }

        expected = [
          'int main() {',
          '  std::cout << "Hello\n";',
          '  return 0;',
          '}'
        ]

        assert_equal(expected, IO.readlines(@tmp.path, chomp: true))
      }
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

    should('delete range from file') {
      CmdEditor.edit(@tmp.path) { |e|
        e.delete e.lines
      }

      expected = []

      assert_equal(expected, IO.readlines(@tmp.path, chomp: true))
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
