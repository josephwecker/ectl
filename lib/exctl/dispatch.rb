require 'exctl/commands'

module Exctl
  class Dispatch
    def self.dispatch(proj_root, args)
      commands = Exctl::Commands.new(proj_root)

      pp commands.to_a
    end
  end
end
