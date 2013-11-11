require 'exctl/cli'

module Exctl
  VERSION = File.exist?(File.join(File.dirname(__FILE__),'..','VERSION')) ? File.read(File.join(File.dirname(__FILE__),'..','VERSION')) : ""
  def self.version() Exctl::VERSION end
  def self.cli(argv)
    Exctl::CLI.new(argv).run
  end
end
