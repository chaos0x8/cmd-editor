#!/usr/bin/ruby

require 'test/unit'
require 'mocha/setup'
require 'shoulda'

require_relative '../lib/cmd-editor'

class TestCmdEditorHelper < Test::Unit::TestCase
  include CmdEditorHelper

  context('CmdEditorHelper') {
    should('return indent value of line') {
      assert_equal(0, indent('hello'))
      assert_equal(2, indent('  hello'))
      assert_equal(4, indent('    hello'))
    }

    should('return indent value of line with tabs') {
      assert_equal(2, indent("\thello", tabwidth: 2))
      assert_equal(6, indent(" \t hello", tabwidth: 4))
      assert_equal(6, indent(" \t hello"))
    }

    should('set indent') {
      assert_equal('  hello', set_indent(" \t hello", 2))
      assert_equal('    hello', set_indent('hello', 4))
      assert_equal('hello', set_indent('  hello', 0))
    }
  }
end

