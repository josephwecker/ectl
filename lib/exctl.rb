module Exctl
  VERSION = File.exist?(File.join(File.dirname(__FILE__),'..','VERSION')) ? File.read(File.join(File.dirname(__FILE__),'..','VERSION')) : ""
  def self.version() Exctl::VERSION end
end

require 'exctl/cli'

