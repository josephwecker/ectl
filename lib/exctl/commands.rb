module Exctl
  class Cmd
    attr_accessor :name, :synopsis, :desc, :args, :priority, :prerequisites
    attr_accessor :priority, :finished, :run
    def initialize(ns, name, opts)
      @ns   = ns.dup
      @name = name
      @opts = opts
    end

    def full_name
      @full_name ||= (@ns + [@name]).map(&:to_s).join('.')
    end
  end

  class Commands
    include Enumerable
    def initialize(proj_root)
      @root = proj_root
      @cmd_manifests = Path[@root]['**/**/.commands']
      @namespace = []
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
        cmd_path.shift if ['bin','scripts'].include?(cmd_path[0])
        @namespace = cmd_path.dup
        eval(File.read(cf), binding, cf.to_s)
        @namespace = []
      end
      @commands
    end

    # ------ Interface ------
    def family(name, opts={}, &block)
      @namespace << name
      yield
      @namespace.pop
    end

    def task(name, opts={}, &block)
      cmd = Cmd.new(@namespace, name, opts)
      init_res = yield cmd
      if init_res
        @commands << cmd
      end
    end
  end
end
