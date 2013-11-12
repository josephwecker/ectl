module Exctl
  VERSION = File.exist?(File.join(File.dirname(__FILE__),'..','VERSION')) ? File.read(File.join(File.dirname(__FILE__),'..','VERSION')) : ""
  def self.version() Exctl::VERSION end
  def self.cli(argv) Exctl::CLI.new(argv).run! end

  class CLI
    def initialize(argv)
      @args = argv.clone
      @cmd = (@args.shift || 'help').strip.downcase
      @cmd = 'help'    if [nil,'-h','--help','h'].include?(@cmd)
      @cmd = 'version' if [nil,'-v','--version','v'].include?(@cmd)
      @cmd = ('cmd_' + @cmd.gsub(/^-+/,'').gsub('-','_')).to_sym
      @opts = {}
    end

    def run!()
      if self.respond_to?(@cmd) then self.send @cmd
      else
        $stderr.puts "ERROR: Command '#{@cmd}' not implemented."
        $stderr.puts "USAGE: exctl (#{avail_cmds.join('|')}) [OPTIONS]"
        exit 1
      end
    end

    def avail_cmds()
      @avail_cmds ||= (self.methods-Object.methods).map(&:to_s).select{|m|m[0..3]=='cmd_'}.map{|m|m[4..-1]}
    end

    def doc_help; 'Output this help.' end
    def cmd_help
      puts "exctl - Execution control; project command-line generator."
      puts "        v#{Exctl.version}\n\n"
      puts "USAGE: exctl (#{avail_cmds.join('|')}) [OPTIONS]\n\n"
      puts avail_cmds.map{|c| hc='doc_'+c; respond_to?(hc) ? '   ' + c.ljust(10) + ':  ' + send(hc) : nil}.compact.join("\n") + "\n\n"
    end

    def cmd_version
      puts Exctl.version
    end

    def doc_init; 'BIN-NAME [DIR=.] - Creates/updates main ctl script and support files in the given DIR.' end
    def cmd_init

      $stderr.puts "just kidding, not implemented yet."
      exit 1
    end
  end
end
