#!/usr/bin/ruby

# \author <https://github.com/chaos0x8>
# \copyright
# Copyright (c) 2015 - 2016, <https://github.com/chaos0x8>
#
# \copyright
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# \copyright
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

require 'rake/testtask'

file('lib/cmd-editor.rb' => FileList['lib/cmd-editor/*.rb']) { |t|
  d = []
  d << "#!/usr/bin/env ruby"
  d << ""
  t.sources.each { |fn|
    d << "require_relative 'cmd-editor/#{File.basename(fn)}'"
  }

  IO.write(t.name, d.join("\n"))
}

Rake::TestTask.new(:test => 'lib/cmd-editor.rb') { |t|
  t.pattern = "#{File.dirname(__FILE__)}/test/**/Test*.rb"
}

desc "#{File.basename(File.dirname(__FILE__))}"
task(:default => :test)

desc "builds gem file"
task(:gem => ['cmd-editor.gemspec', 'lib/cmd-editor.rb']) {
  sh 'gem build cmd-editor.gemspec'
  Dir['*.gem'].sort{ |a, b| File.mtime(a) <=> File.mtime(b) }[0..-2].each { |fn|
    FileUtils.rm(fn, verbose: true)
  }
}

task(:clean) {
  Dir['*.gem'].each { |fn|
    FileUtils.rm(fn, verbose: true)
  }
}
