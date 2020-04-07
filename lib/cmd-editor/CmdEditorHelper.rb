#!/usr/bin/ruby

module CmdEditorHelper
  def indent(line, tabwidth: 4)
    whiteChars = line.match(/^(\s*)/)[1]
    whiteChars.count(' ') + whiteChars.count("\t") * tabwidth
  end

  def set_indent(line, indent)
    ' ' * indent + line.lstrip
  end
end
