gem 'bundler'

require 'bundler'
Bundler.require(:default, :test)

require_relative '../lib/cmd-editor'
require_relative 'rspec-matchers/FileContent'

require 'tempfile'

describe(CmdEditor) {
  subject {
    proc {
      @tmp.path
    }
  }

  let(:fileData) {
    [
      "int main() {",
      "  return 0;",
      "}\n"
    ].join("\n")
  }

  before {
    @tmp = Tempfile.new File.basename(__FILE__)
    @tmp.write(fileData)
    @tmp.close
  }

  after {
    @tmp.unlink
  }

  testPath = proc {
    context('.path') {
      it('is expected to return path') {
        CmdEditor.open(@tmp.path) { |e|
          expect(e.path).to eq(File.expand_path(@tmp.path))
        }

        should file_content.eq(fileData)
      }
    }
  }

  instance_eval(&testPath)

  testLines = proc {
    context('.lines') {
      it('is expected to return number of lines') {
        CmdEditor.open(@tmp.path) { |e|
          expect(e.lines).to eq(1..3)
        }

        should file_content.eq(fileData)
      }
    }
  }

  instance_eval(&testLines)

  testOpen = proc {
    context('.open') {
      it('is expected to not modify file') {
        CmdEditor.new(@tmp.path) { |e|
          e.insert(1, '//')
        }

        should file_content.eq(fileData)
      }
    }
  }

  instance_eval(&testOpen)

  context('.insert') {
    [1,2,3].each_with_index { |lineNo, index|
      it("is expected to insert/#{index}") {
        CmdEditor.edit(@tmp.path) { |e|
          e.insert(lineNo, '//')

          expect(e.lines).to eq(1..4)
          expect(e[lineNo]).to eq('//')
        }

        should file_content.include('//')
      }
    }

    it('is expected to insert at the end of file') {
      CmdEditor.edit(@tmp.path) { |e|
        e.insert(-1, '//')

        expect(e.lines).to eq(1..4)
        expect(e[4]).to eq('//')
      }

      should file_content.eq_lines(
        'int main() {',
        '  return 0;',
        '}',
        "//\n")
    }

    [-2, 4, 5, 100, -25].each_with_index { |lineNo, index|
      it("is expected to raise when insert at unknown line/#{index}") {
        CmdEditor.edit(@tmp.path) { |e|
          expect { e.insert(lineNo, '//') }.to raise_error(ArgumentError)
        }
      }
    }

    it('is expected to add multiple lines to file') {
      CmdEditor.edit(@tmp.path) { |e|
        e.insert(2, ['//1', '//2'], indentMode: :next)
      }

      should file_content.eq_lines(
        'int main() {',
        '  //1',
        '  //2',
        '  return 0;',
        "}\n")
    }

    it('is expected to add multiple lines to file at the end') {
      CmdEditor.edit(@tmp.path) { |e|
        e.insert(-1, ['//1', '//2'], indentMode: :next)
      }

      should file_content.eq_lines(
        'int main() {',
        '  return 0;',
        '}',
        '//1',
        "//2\n")
    }
  }

  context('.edit') {
    it('is expected to not add additional empty line at the end of file') {
      CmdEditor.edit(@tmp.path) { }

      should file_content.eq(fileData)
    }
  }

  context('no new line at the end of file') {
    let(:fileData) {
      [
        "int main() {",
        "  return 0;",
        "}"
      ].join("\n")
    }

    instance_eval(&testPath)
    instance_eval(&testLines)
    instance_eval(&testOpen)

    context('.edit') {
      it('is expected to add missing new line at the end of file') {
        CmdEditor.edit(@tmp.path) { }

        should file_content.eq(fileData + "\n")
      }
    }
  }
}

