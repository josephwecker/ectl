require 'exctl/commands'

module Exctl
  class Dispatch
    def self.dispatch(proj_root, args)
      commands = Exctl::Commands.new(proj_root)

      pp commands.map{|c| c.full_name}
    end
  end
end
