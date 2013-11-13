module Exctl
  require 'shorthand'

  LIB_DIR      = Path[File.dirname(__FILE__)]
  TEMPLATE_DIR = (LIB_DIR ** '..') ** 'templates'

  VFILE        = (LIB_DIR ** '..') ** 'VERSION'
  VERSION      = VFILE.exists? ? VFILE.read : ''
  def self.version() Exctl::VERSION end

  def self.cli(argv)
    require 'exctl/cli'
    Exctl::CLI.new(argv).run!
  end
end
