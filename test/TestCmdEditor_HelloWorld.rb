#!/usr/bin/ruby

require_relative '../lib/cmd-editor'

require_relative 'UtUtility'

class TestCmdEditor < Test::Unit::TestCase
  include UtUtility

  def assert_return_0_inserted
    assert_file_content_match([
      'int main()',
      '{',
      '  sayHello();',
      '  return 0;',
      '}'
    ])
  end

  context('with hello world') {
    merge_block(&UtUtility.defTeardown)

    setup {
      setFileContent([
        '#include <iostream>',
        '',
        'void sayHello();',
        '',
        'int main()',
        '{',
        '  sayHello();',
        '}',
        '',
        'void sayHello()',
        '{',
        '  std::cout << "Hello world!\n";',
        '}'
      ])
    }

    should('insert return 0; using simple find') {
      CmdEditor.edit(@fn) { |e|
        callSayHello = e.find( first: /^\s+sayHello/ )
        e.insert(line: callSayHello + 1, text: '  return 0;')
      }

      assert_return_0_inserted
    }

    should('insert return 0; using advanced find') {
      CmdEditor.edit(@fn) { |e|
        callSayHello = e.find({ after: { first: 'main' } }, first: 'sayHello' )
        e.insert(line: callSayHello + 1, text: '  return 0;')
      }

      assert_return_0_inserted
    }

    should('inline sayHello') {
      CmdEditor.edit(@fn) { |e|
        sayHelloCode = e[e.find({after: { last: 'void sayHello' }}, { after: { first: '{' }}, {before: { first: '}' }}, any: '')]
        e.replace(line: e.find({after: { first: 'main' }}, first: 'sayHello'), with: sayHelloCode)

        sayHelloImpl = e.find({after_including: { last: 'void sayHello' }}, {before_including: { first: '}' }}, any: '')
        sayHelloDef = e.find(first: 'void sayHello')
        e.delete(line: [sayHelloImpl.first-1] + sayHelloImpl + [sayHelloDef-1] + [sayHelloDef])
      }

      assert_file_content([
        '#include <iostream>',
        '',
        'int main()',
        '{',
        '  std::cout << "Hello world!\n";',
        '}'
      ])
    }
  }
end
