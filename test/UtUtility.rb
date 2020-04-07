#!/usr/bin/ruby

require 'test/unit'
require 'mocha/setup'
require 'shoulda'

require 'securerandom'

module UtUtility
  def setFileContent content
    content = content.join("\n") if content.kind_of? Array

    @fn ||= "/tmp/#{SecureRandom.hex}_testCmdEditorFile.txt"
    File.open(@fn, 'w') { |f|
      f.write content
    }
  end

  def assert_file_content expectedContent
    expectedContent = expectedContent.join("\n") if expectedContent.kind_of? Array
    assert_equal(expectedContent, File.open(@fn, 'r') { |f| f.read })
  end

  def assert_file_content_match expectedContent
    expectedContent = expectedContent.join("\n") if expectedContent.kind_of? Array
    assert_match(expectedContent, File.open(@fn, 'r') { |f| f.read })
  end

  def self.defTeardown
    proc {
      teardown {
        if @fn and File.exist?(@fn)
          FileUtils.rm @fn
        end
      }
    }
  end
end
