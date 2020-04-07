#!/usr/bin/ruby

require_relative '../lib/cmd-editor'

require_relative 'UtUtility'

class TestCmdEditor < Test::Unit::TestCase
  include UtUtility

  context('with nested code') {
    merge_block(&UtUtility.defTeardown)

    setup {
      setFileContent([
        'class Foo',
        '{',
        'public:',
        '  void bar()',
        '  {',
        '    auto a = std::vector<int>({1,2,3});',
        '    if (std::find_if(a.begin(), a.end(), [](auto x) { return x == 2; } != a.end()) {',
        '      baz();',
        '    }',
        '  }',
        '',
        '  void baz()',
        '  {',
        '',
        '  }',
        '}; // class Foo',
        '',
        'int main()',
        '{',
        '  return 0;',
        '} // int main()'
      ])
    }

    should('find matching bracket/1') {
      result = CmdEditor.read(@fn) { |e|
        e[e.find(matching: '{')]
      }

      assert_equal('}; // class Foo', result)
    }

    should('find matching bracket/2') {
      result = CmdEditor.read(@fn) { |e|
        e[e.find({ after_including: { first: 'std::vector' }}, matching: '{')]
      }

      assert_match('std::vector<int>({1,2,3})', result)
    }

    should('find matching bracket/3') {
      result = CmdEditor.read(@fn) { |e|
        e[e.find({ after: { first: /\bif\b/ }}, matching: '(')]
      }

      assert_match('baz();', result)
    }

    should('find matching bracket/4') {
      result = CmdEditor.read(@fn) { |e|
        e[e.find({ after: { matching: '{' }}, matching: '{')]
      }

      assert_equal('} // int main()', result)
    }
  }
end
