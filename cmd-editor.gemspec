Gem::Specification.new { |s|
  s.name        = 'cmd-editor'
  s.version     = '1.2.1'
  s.date        = '2021-01-13'
  s.summary     = "#{s.name}"
  s.description = "library which allows file edition with commands"
  s.authors     = ["chaos0x8"]
  s.files       = Dir['lib/**/*.rb', 'bin/*.rb']
  s.executables = Dir['bin/*.rb'].collect { |x| File.basename(x) }
  s.add_development_dependency 'rspec', '~> 3.10'
  s.add_development_dependency 'mocha', '~> 1.11'
}
