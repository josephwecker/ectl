module Exctl
  class Commands
    include Enumerable
    def initialize(proj_root)
      @root = proj_root
      @cmd_files = Path[@root]['**/**/.commands']
    end

    def each(&block) commands.each(&block) end

    def commands
      return @commands unless @commands.nil?

      # 1. Commands in manifests
      # 2. Default commands (unless overridden already)
      # 3. Commands found in 'scripts' etc. (unless overridden)

      @cmd_files.each do
        # TODO: You are here- figure out what representation they should be in, pull them in and eval/parse/etc. them
      end


    end
  end
end
