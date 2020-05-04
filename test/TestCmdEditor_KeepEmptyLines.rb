#!/usr/bin/env ruby

require_relative '../lib/cmd-editor/CmdEditor'

require 'test/unit'
require 'shoulda'
require 'mocha'

require 'tempfile'

class TestCmdEditor_KeepEmptyLines < Test::Unit::TestCase
  context('TestCmdEditor_KeepEmptyLines') {
    setup {
      @tmp = Tempfile.new File.basename(__FILE__)
      @tmp.write([
        "int main() {\n",
        "\n",
        "\n",
        "  return 0;\n",
        "}\n",
        "\n",
        "\n",
        ""
      ].join '')
      @tmp.close
    }

    teardown {
      @tmp.unlink
    }

    should('keep new lines intact') {
      org = IO.read(@tmp.path)

      CmdEditor.edit(@tmp.path) { |e|
        nil
      }

      assert_equal(org, IO.read(@tmp.path))
    }
  }
end
