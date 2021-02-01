#!/usr/bin/env ruby

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

task(:test) {
  files = Dir["#{File.dirname(__FILE__)}/test/**/Test*.rb"]
  sh 'ruby', *files.collect { |x| ['-e', "require '#{File.expand_path(x)}'"] }.flatten

  files = Dir["#{File.dirname(__FILE__)}/test/**/*_spec.rb"]
  sh 'rspec', *files, '-f', 'd'
}

desc 'Generates require all file'
file('lib/cmd-editor.rb' => FileList['lib/cmd-editor/*.rb']) { |t|
  d = []
  d << "#!/usr/bin/env ruby"
  d << ""
  t.sources.each { |fn|
    d << "require_relative 'cmd-editor/#{File.basename(fn)}'"
  }
  d << ""

  IO.write(t.name, d.join("\n"))
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
