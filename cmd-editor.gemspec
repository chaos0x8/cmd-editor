Gem::Specification.new { |s|
  s.name        = 'cmd-editor'
  s.version     = '0.1.0'
  s.date        = '07.04.2020'
  s.summary     = "#{s.name}"
  s.description = "application/library which allows file edition with commands"
  s.authors     = ["chaos0x8"]
  s.files       = Dir['lib/**/*.rb', 'bin/*.rb']
  s.executables = Dir['bin/*.rb'].collect { |x| File.basename(x) }
}
