module Exctl
  class Commands
    include Enumerable
    def initialize(proj_root)
      @root = proj_root
      @cmd_manifests = Path[@root]['**/**/.commands']
      #@bin_files = `find '#{@root}' -executable -type f -print0`.split("\x00")
      #pp @bin_files
    end

    def each(&block) commands.each(&block) end

    def commands
      return @commands unless @commands.nil?

      # 1. Commands in manifests
      # 2. Default commands (unless overridden already)
      # 3. Commands found in 'scripts' etc. (unless overridden)

      @commands = []
      @cmd_manifests.each do |cf|
        cmd_path = cf.short(Path[@root]).to_s.split('/')[0..-2]
        @commands << cmd_path
        eval(File.read(cf), binding, cf.to_s)
      end
      @commands
    end

    def 

    end
  end
end
