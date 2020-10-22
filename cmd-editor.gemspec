Gem::Specification.new { |s|
  s.name        = 'cmd-editor'
  s.version     = '1.2.0'
  s.date        = '2020-10-23'
  s.summary     = "#{s.name}"
  s.description = "library which allows file edition with commands"
  s.authors     = ["chaos0x8"]
  s.files       = Dir['lib/**/*.rb', 'bin/*.rb']
  s.executables = Dir['bin/*.rb'].collect { |x| File.basename(x) }
}
