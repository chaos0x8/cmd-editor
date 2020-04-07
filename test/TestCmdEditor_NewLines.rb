#!/usr/bin/ruby

require_relative '../lib/cmd-editor'

require_relative 'UtUtility'

class TestCmdEditor < Test::Unit::TestCase
  include UtUtility

  context('with many new lines') {
    merge_block(&UtUtility.defTeardown)

    setup {
      setFileContent("\n\nx\n\n\n")
    }

    should('keep new lines') {
      CmdEditor.edit(@fn) { |e|
        e.insert(line: 3, text: '-')
      }

      assert_file_content("\n\n-\nx\n\n\n")
    }
  }
end
