
module Exctl
  class CLI
    def initialize(argv)
      @args = argv.clone
    end

    def run
      puts "Welcome! #{Exctl.version}"
    end
  end
end
