#!/usr/bin/ruby

require_relative '../lib/cmd-editor'

require_relative 'UtUtility'

class TestCmdEditor < Test::Unit::TestCase
  include UtUtility

  context('TestCmdEditor') {
    merge_block(&UtUtility.defTeardown)

    context('with few lines') {
      setup {
        setFileContent(['line1', 'line2', 'line3'])
      }

      context('basic functionality') {
        should('replace line') {
          CmdEditor.edit(@fn) { |e|
            e.replace(line: 2, with: 'replaced')
          }

          assert_file_content(['line1', 'replaced', 'line3'])
        }

        should('delete line') {
          CmdEditor.edit(@fn) { |e|
            e.delete(line: 2)
          }

          assert_file_content(['line1', 'line3'])
        }

        should('insert line at the begining') {
          CmdEditor.edit(@fn) { |e|
            e.insert(line: 1, text: 'inserted')
          }

          assert_file_content(['inserted', 'line1', 'line2', 'line3'])
        }

        should('insert line in the middle') {
          CmdEditor.edit(@fn) { |e|
            e.insert(line: 2, text: 'inserted')
          }

          assert_file_content(['line1', 'inserted', 'line2', 'line3' ])
        }

        should('insert line at the end') {
          CmdEditor.edit(@fn) { |e|
            e.insert(line: 4, text: 'inserted')
          }

          assert_file_content(['line1', 'line2', 'line3', 'inserted'])
        }

        should('find first match') {
          CmdEditor.edit(@fn) { |e|
            assert_equal(1, e.find(first: 'line'))
          }
        }

        should('find last match') {
          CmdEditor.edit(@fn) { |e|
            assert_equal(3, e.find(last: 'line'))
          }
        }

        [ { sym: :first }, { sym: :last } ].each { |sym:|
          should("return nil when #{sym} match was not found") {
            CmdEditor.edit(@fn) { |e|
              assert_equal(nil, e.find(sym => 'unknown'))
            }
          }
        }

        should('return empty array when nothing was matched using multi match') {
          CmdEditor.edit(@fn) { |e|
            assert_equal([], e.find(any: 'unknown'))
          }
        }

        should('find all matched') {
          CmdEditor.edit(@fn) { |e|
            assert_equal([1,3], e.find(any: /(1|3)/))
          }
        }
      }

      [ :read, :edit ].each { |mode|
        context("#{mode} mode") {
          should('returns yield result') {
            actual = CmdEditor.send(mode, @fn) { |e|
              e[1]
            }

            assert_equal('line1', actual)
          }

          should('save changes') {
            CmdEditor.send(mode, @fn) { |e|
              e[1] = '-'
            }

            assert_file_content(['-', 'line2', 'line3'])
          } if mode == :edit

          should('not save changes') {
            CmdEditor.send(mode, @fn) { |e|
              e[1] = '-'
            }

            assert_file_content(['line1', 'line2', 'line3'])
          } if mode == :read
        }
      }

      context('patern replace') {
        should('replace matched patern') {
          CmdEditor.edit(@fn) { |e|
            e.replace(line: 1, patern: /l(..)e(\d)/, with: '\1: \2')
          }

          assert_file_content(['in: 1', 'line2', 'line3'])
        }

        should('replace matched global patern') {
          CmdEditor.edit(@fn) { |e|
            e.replace(line: 2, gpatern: /[ln]/, with: '?')
          }

          assert_file_content(['line1', '?i?e2', 'line3'])
        }

        [{ name: 'patern', sym: :patern}, { name: 'global patern', sym: :gpatern }].each { |name:, sym:|
          should("not replace when #{name} is not matched") {
            CmdEditor.edit(@fn) { |e|
              e.replace(line: 2, sym =>  /text/, with: '????')
            }

            assert_file_content(['line1', 'line2', 'line3'])
          }
        }
      }

      context('multiple lines') {
        should('delete multiple lines') {
          CmdEditor.edit(@fn) { |e|
            e.delete(line: [1,3])
          }

          assert_file_content('line2')
        }

        should('replace matched patern in many places') {
          CmdEditor.edit(@fn) { |e|
            e.replace(line: [2,3], patern: /l(..)e(\d)/, with: '\1: \2')
          }

          assert_file_content(['line1', 'in: 2', 'in: 3'])
        }

        should('replace one line with many lines') {
          CmdEditor.edit(@fn) { |e|
            e.replace(line: 2, with: ['l1.5', 'l2.5'])
            e.replace(line: 4, with: 'l4')
          }

          assert_file_content(['line1', 'l1.5', 'l2.5', 'l4'])
        }

        should('replace many lines with many lines') {
          CmdEditor.edit(@fn) { |e|
            e.replace(line: [1,3], with: ['x', 'y'])
          }

          assert_file_content(['x', 'line2', 'y'])
        }

        [ { sym: :patern }, { sym: :gpatern } ].each { |sym:|
          should("raise argument error when #{sym} passed with array replace") {
            CmdEditor.edit(@fn) { |e|
              assert_raise(ArgumentError) {
                e.replace(line: [1,3], with: ['x', 'y'], sym => //)
              }
            }
          }
        }

        should('raise argument error when sizes doesn\'t match in replase') {
          CmdEditor.edit(@fn) { |e|
            assert_raise(ArgumentError) {
              e.replace(line: [1,2], with: ['a','b','c'])
            }
          }
        }

        should('insert same line in many places') {
          CmdEditor.edit(@fn) { |e|
            e.insert(line: [1,2,3,4], text: '-')
          }

          assert_file_content(['-', 'line1', '-', 'line2', '-', 'line3', '-'])
        }

        should('insert many lines in one place') {
          CmdEditor.edit(@fn) { |e|
            e.insert(line: 2, text: ['-', 'xxx', '='])
            e.insert(line: 7, text: 'line7')
          }

          assert_file_content(['line1', '-', 'xxx', '=', 'line2', 'line3', 'line7'])
        }

        should('insert many lines in many places') {
          CmdEditor.edit(@fn) { |e|
            e.insert(line: [2, 3], text: ['1.5', '2.5'])
          }

          assert_file_content(['line1', '1.5', 'line2', '2.5', 'line3'])
        }

        should('raise argument error when sizes doesn\'t match in insert') {
          CmdEditor.edit(@fn) { |e|
            assert_raise(ArgumentError) {
              e.insert(line: [1,2], text: ['a','b','c'])
            }
          }
        }
      }

      context('find using rules') {
        should('find using \'after first\' rule') {
          CmdEditor.edit(@fn) { |e|
            assert_equal(2, e.find({ after: { first: 'line' } }, first: 'line'))
          }
        }

        should('find using \'before last\' rule') {
          CmdEditor.edit(@fn) { |e|
            assert_equal(2, e.find({ before: { last: 'line' } }, last: 'line'))
          }
        }

        should('find using \'after first\' rule with any pater') {
          CmdEditor.edit(@fn) { |e|
            assert_equal([2,3], e.find({ after: { first: 'line' } }, any: ''))
          }
        }

        should('find using \'before first\' rule with any pater') {
          CmdEditor.edit(@fn) { |e|
            assert_equal([1,2], e.find({ before: { last: 'line' } }, any: ''))
          }
        }

        [ { rule: :after, sym: :first }, { rule: :before, sym: :last } ].each { |rule:, sym:|
          should("return nil when '#{rule} #{sym}' rule was not matched") {
            CmdEditor.edit(@fn) { |e|
              assert_equal(nil, e.find({ rule => { sym => 'unknown' } }, sym => 'line'))
            }
          }

          should("return empty array when '#{rule} #{sym}' rule was not matched using multi match") {
            CmdEditor.edit(@fn) { |e|
              assert_equal([], e.find({ rule => { sym => 'unknown' } }, any: 'line'))
            }
          }
        }

        [ { rule: :after }, { rule: :before } ].each { |rule:|
          should("raise argument error when using '#{rule} any' rule") {
            CmdEditor.edit(@fn) { |e|
              assert_raise(ArgumentError) {
                e.find({ rule => { any: 'line' } }, first: 'line')
              }
            }
          }
        }
      }
    }
  }
end
