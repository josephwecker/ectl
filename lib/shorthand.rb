require 'ostruct'
require 'pathname'
require 'etc'
require 'set'
require 'pp'
require 'digest'
require 'base64'

class Nilish
  def self.global()$__N||= self.new end
  def inspect()    "nil(ish)"       end
  def to_str()     ''               end
  def blank?()     true             end
  def nil?()       true             end
  def empty?()     true             end
  def wrap(*args)  ''               end
  def method_missing(m,*a,&b)
    case
    when nil.respond_to?(m)   then nil.send(m,*a,&b)
    when false.respond_to?(m) then false.send(m,*a,&b)
    when m.to_s[-1..-1]=='?'  then nil
    else self end
  end
end

class Object
  def blank?()     respond_to?(:empty?) ? empty? : !self    end
  def maybe()      self.nil? ? Nilish.global : self         end
  def present?()   !blank?                                  end
  def presence()   self if present?                         end
  def to_sig()     Digest::SHA1.digest(self.to_s).base64url end
  def numeric?()   respond_to?(:to_f)                       end
end

class NilClass
  def blank?()     true  end
  def wrap(*args)  ''    end
  def s(*args)     ''    end
  def sign()       nil  end
end
class FalseClass;  def blank?() true  end       end 
class TrueClass;   def blank?() false end       end
class Numeric;     def blank?() false end       end
class Hash;        alias_method :blank?,:empty? end
class Array;       alias_method :blank?,:empty? end
class Set;         alias_method :blank?,:empty? end

module Enumerable
  def amap(m,*a,&b) self.map {|i|i.send(m,*a,&b)} end
  def amap!(m,*a,&b)self.map!{|i|i.send(m,*a,&b)} end
  def sum() self.inject(0){|acc,i|acc + i} end
  def average() self.sum/self.length.to_f end
  def median()    self.dup.to_a.sort[self.size/2] end
  def medianr(r)  d = self.dup.to_a.sort; d[self.size/2-r..self.size/2+r].average end
  def median_ad() m = self.median; self.map{|v| (v.to_f - m.to_f).abs}.average end
  def median_mad() m = self.median; self.map{|v| (v.to_f - m.to_f).abs}.median end
  def median_madr(r) m = self.median; self.map{|v| (v.to_f - m.to_f).abs}.medianr(r) end
  def mean_ad() m = self.average; self.map{|v| (v.to_f - m.to_f).abs}.average end
  def mid() srt=self.sort; self.size % 2 == 0 ? (srt[self.size/2] + srt[self.size/2-1]).to_f/2.0 : srt[self.size/2] end
  def robust_ad() r = self.robust_avg; self.map{|v| (v.to_f - r).abs}.average end
  def robust_ad2() r = self.robust_avgm; self.map{|v| (v.to_f - r).abs}.average end
  def q20()
    fifth = self.size.to_f / 5.0
    return self[0] if fifth < 1.0
    i1,i2 = [fifth.floor-1, fifth.ceil-1]
    srt = self.sort
    return srt[i1].to_f if i1 == i2
    return srt[i1].to_f * (fifth.ceil - fifth) + srt[i2] * (fifth - fifth.floor)
  end
  def q80()
    fifth = self.size.to_f / 5.0
    return self.last if fifth < 1.0
    i1,i2 = [self.size - fifth.floor, self.size - fifth.ceil]
    srt = self.sort
    return srt[i1].to_f if i1 == i2
    return srt[i1].to_f * (fifth.ceil - fifth) + srt[i2] * (fifth - fifth.floor)
  end
  def robust_avg() (self.q20 + self.mid + self.q80) / 3.0 end
  def robust_avgm() (self.q20 + self.mid + self.mid + self.q80) / 4.0 end
  def sample_variance
    avg=self.average
    sum=self.inject(0){|acc,i|acc + (i-avg)**2}
    sum.to_f/self.length.to_f
  end
  def standard_deviation() Math.sqrt(self.sample_variance) end
  def summarize_runs
    return [] if size == 0
    self.slice_before([self[0]]){|e,c| e==c[0] ? false : (c[0]=e; true)}.map do |chk|
      [chk.size, chk[0]]
    end
  end
  alias_method :stddev, :standard_deviation
  alias_method :avg,    :average
  alias_method :mean,   :average
  alias_method :var,    :sample_variance
end

class Set; alias_method :[],:member? end

unless defined?(Path)
  Path = Pathname
  class Pathname
    def self.[](p) Path.new(p) end
    alias old_init initialize
    def initialize(*args) old_init(*args); @rc={}; @rc2={} end
    alias_method :exists?,:exist?
    def to_p()  self             end
    def **  (p) self+p.to_p      end
    def r?  ()  readable_real?   end
    def w?  ()  writable_real?   end
    def x?  ()  executable_real? end
    def rw? ()  r? && w?         end
    def rwx?()  r? && w? && x?   end
    def dir?()  directory?       end
    def ===(p)  real == p.real   end
    def perm?() exp.dir? ? rwx? : rw?               end
    def exp ()  return @exp ||= self.expand_path    end
    def real()  begin exp.realpath rescue exp end   end
    def dir()   (exp.dir? || to_s[-1].chr == '/') ? exp : exp.dirname end
    def dir!()  (exp.mkpath unless exp.dir? rescue return nil); self end
    def [](p,dots=true)   Path.glob((dir + p.to_s).to_s, dots ? File::FNM_DOTMATCH : 0)  end
    def older_than?(p) self.stat.mtime < p.stat.mtime end
    def missing?() !self.exist? end
    def as_other(new_dir, new_ext=nil)
      p = new_dir.nil? ? self : (new_dir.to_p + self.basename)
      p = Path[p.to_s.sub(/#{self.extname}$/,'.'+new_ext)] if new_ext
      return p
    end
    def rel(p=nil,home=true)
      p ||= ($pwd || Path.pwd)
      return @rc2[p] if @rc2[p]
      r = abs.rel_path_from(p.abs)
      r = r.sub(ENV['HOME'],'~') if home
      r
    end
    def contents; IO.read(self) end
    def different_contents?(str) IO.read(self).strip != str.strip end
    def short(p=nil,home=true)
      p ||= ($pwd || Path.pwd)
      return @rc2[p.to_s] if @rc2[p.to_s]
      sr  = real; pr  = p.real
      se  = exp;  pe  = p.exp
      candidates  = [sr.rel_path_from(pr), sr.rel_path_from(pe),
        se.rel_path_from(pr), se.rel_path_from(pe)]
      candidates += [sr.sub(ENV['HOME'],'~'), se.sub(ENV['HOME'],'~')] if home
      @rc2[p.to_s] = candidates.sort_by{|v|v.to_s.size}[0]
    end
    def rel_path_from(p) @rc ||= {}; @rc[p.to_s] ||= relative_path_from(p) end
    def relation_to(p)
      travp = p.rel(self,false).to_s
      if    travp =~ /^(..\/)+..(\/|$)/ then :child
      else  travp =~ /^..\// ? :stranger : :parent end
    end
    def dist_from(p)
      return 0 if self === p
      travp = p.dir.rel(self.dir,false).to_s
      return 1 if travp =~ /^\/?\.\/?$/
      return travp.split('/').size + 1
    end
    alias old_mm method_missing
    def method_missing(m,*a,&b) to_s.respond_to?(m) ? to_s.send(m,*a,&b) : old_mm(m,*a,&b) end
    def abs(wd=nil)
      wd ||= ($pwd || Path.pwd); wd = wd.to_s
      s    = self.to_s
      raise ArgumentError.new('Bad working directory- must be absolute') if wd[0].chr != '/'
      if    s.blank? ;                                   return nil
      elsif s[0].chr=='/' ;                              return s
      elsif s[0].chr=='~' && (s[1].nil?||s[1].chr=='/'); _abs_i(s[1..-1], ENV['HOME'])
      elsif s =~ /~([^\/]+)/;                            _abs_i($', Etc.getpwnam($1).dir)
      else                                               _abs_i(s, wd) end
    end

    private
    def _abs_i(p,wd)
      str   = wd + '/' + p ; last  = str[-1].chr
      combo = []
      str.split('/').each do |part|
        case part
        when part.blank?, '.' then next
        when '..' then combo.pop
        else combo << part end
      end
      Path.new('/' + combo.join('/') + (last == '/' ? '/' : ''))
    end
  end

  class String
    def to_p()   Path.new(self) end
    alias old_mm method_missing
    #def method_missing(m,*a,&b) to_p.respond_to?(m) ? to_p.send(m,*a,&b) : old_mm(m,*a,&b) end
    #def respond_to_missing?(m,p=false) to_p.respond_to?(m,p) end
    def same_path(p) to_p === p end
  end
end


class String
  alias_method :l, :ljust
  alias_method :r, :rjust
  def eval() Kernel.eval(self) end
  def base64url() Base64::encode64(self).tr("\n\s\r=",'').tr('+/','-_') end
  def fnv32() bytes.reduce(0x811c9dc5)        {|h,b|((h^b)*0x01000193)    % (1<<32)} end
  def fnv64() bytes.reduce(0xcbf29ce484222325){|h,b|((h^b)*0x100000001b3) % (1<<64)} end
  def blank?() self !~ /[^[:space:]]/      end
  def to_sh()  blank? ? '' : gsub(/([^A-Za-z0-9_\-.,:\/@\n])/n, "\\\\\\1").gsub("\n","'\n'") end

  def wrap(indent=:first, width=90)
    width ||= 90
    ind = case indent
          when :first  then self[/^[[:space:]]*/u]
          when String  then indent
          when Integer then ' ' * indent.abs
          else ' ' * indent.to_i.abs end
    ind_size = ind.count("\t")*8 + ind.count("^\t")
    width = width.to_i.abs - ind_size; width = 1 if width < 1
    paras = dup.strip.split(/\n[ \t]*\n[[:space:]]*/mu)
    paras = paras.map{|p| p.strip.gsub(/[[:space:]]+/mu,' ')}
    paras = paras.map{|p| p.scan(/.{1,#{width}}(?: |$)/u).map{|row| ind + row.strip}.join("\n")}
    paras.join("\n\n")
  end
  def sentences() gsub(/\s+/,' ').scan(/([^.!?]+([.!?](\s+|$)|$))/).map{|s|s[0].strip}.reject{|s|s.nil? || s.strip==''} end
  def make_esc(esc_interp=true)
    if esc_interp
      gsub(/\$([A-Za-z0-9_-]+)/){|m| "${"+$1.gsub(/\W/,'_')+"}"}.gsub("\n","\\\n")
    else
      gsub('$','$$').gsub("\n","\\\n")
    end
  end
  def numeric?()   true if Float(self) rescue false end
  alias_method :ssize, :size
  def last(n=1) self.size < n ? self : self[-n..-1] end
end

class Numeric
  def sign(neg=-1,zer=0,pos=1) self == 0 ? zer : (self < 0 ? neg : pos) end
  def sign2(neg=-1,pos=1) self < 0 ? neg : pos end
  def ssize() self.to_s.size end
end

class Integer
  def fact() f=1; (1..self).each{|i| f *= i}; f end
end

class Fixnum
  def numeric?() true end
  def s(p=0,ch='0')
    return ch if self == 0 && !ch.nil?
    p > 0 ? ("%.#{p}f" % self) : self.to_s
  end
end

class Float
  def numeric?() true end
  def s(p=2,ch='0')
    return ch if self == 0.0 && p == 0 && !ch.nil?
    v = self.round
    v = (self > 0.0 ? self.ceil : self.floor) if v == 0 && !ch.nil?
    ret = p > 0 ? ("%.#{p}f" % self) : v.to_s
    (ret =~ /^0+(\.0+)?$/ && !ch.nil?) ? ch : ret
  end
end

class Array
  def wrap(indent=:first, width=nil) join(' ').wrap(indent, width) end
  def sentences() join(' ').sentences end
  def compacted() map{|v| v.blank? ? nil : v}.compact end
  alias_method :stable_compact, :compacted
  def avg0() _i = map{|v| v.numeric? ? v.to_f : nil}.compact; _i.size > 0 ? (_i = _i.inject(:+) / size.to_f) : 0.0 end
  def hmap(&block) OrderedHash[*(self.each_with_index.map{|v,k| yield(k,v)}.compact.flatten)] end
end

class Proj
  def initialize(cwd=nil, cf=nil)
    @cached_lookups = {}
    @p_cf           = nil
    @p_cwd          = (cwd || Path.pwd).exp
    @p_cf           = cf.exp unless cf.blank?
  end

  def root_dir
    wd_root = root_dir_for(@p_cwd)
    return wd_root if @p_cf.blank?
    cf_root = root_dir_for(@p_cf)
    return @p_cwd  if wd_root.blank? && cf_root.blank?
    return cf_root if wd_root.blank?
    return wd_root if cf_root.blank?
    return wd_root if wd_root === cf_root
    return wd_root if wd_root.relation_to(cf_root) == :parent
    return cf_root
  end

  def [](pattern,refresh=false)
    @cached_lookups.delete(pattern) if refresh
    return @cached_lookups[pattern] ||= root_dir[pattern]
  end

  private
  def root_dir_for(path)
    in_cvs = in_svn = in_rcs = false
    tentative = path.dir
    tentative.ascend do |d|
      has_cvs = has_svn = has_rcs = false
      d['{.hg,.svn,CVS,RCS,[MR]akefile,configure,LICENSE}'].each do |c|
        case c.basename.to_s
        when '.hg'||'.git'           then return d
        when '.svn' then in_svn = d; has_svn = true
        when 'CVS'  then in_cvs = d; has_cvs = true
        when 'RCS'  then in_rcs = d; has_rcs = true
        when /[MR]akefile.*/         then tentative = d
        when 'configure'||'LICENSE'  then tentative = d
        end
      end
      return in_svn if in_svn && !has_svn
      return in_cvs if in_cvs && !has_cvs
      return in_rcs if in_rcs && !has_rcs
    end
    return tentative
  end
end

module ForHashes
  def stable_compact()
    h = self.dup
    h = h.reject{|k,v| v.nil?}
    dat = h.map do |k,v|
      v = v.stable_compact if v.respond_to?(:stable_compact)
      [k.to_s, v]
    end
    dat.sort
  end
  def to_sig() stable_compact.inspect.to_sig end
  def map_vals!(&block) each{|k,v| self[k] = yield(k,v)}; self end
  def map_vals(&block) dup.map_vals!(&block) end
  def hmap(&block) OrderedHash[*(self.map{|k,v| yield(k,v)}.compact.flatten)] end
  def clean() map_vals{|k,v| v.respond_to?(:clean) ? v.clean : (v.respond_to?(:to_str) ? v.to_str : v.to_s)} end
end


if RUBY_VERSION >= '1.9'
  OrderedHash = ::Hash
else
  class OrderedHash < Hash
    def self.[](*args)
      ordered_hash = new
      args.each_with_index { |val,ind|
        # Only every second value is a key.
        next if ind % 2 != 0
        ordered_hash[val] = args[ind + 1]
      }
      ordered_hash
    end
    alias_method :blank?,:empty?
    def initialize(*args, &block) super; @keys = [] end
    def initialize_copy(other) super; @keys = other.keys end
    def []=(key, value) @keys << key if !has_key?(key); super end
    def delete(key)
      $stderr.puts "Deleting key #{key}"
      if has_key? key
        index = @keys.index(key)
        @keys.delete_at index
      end
      super
    end
    def delete_if() super; sync_keys!; self end
    def reject!; super; sync_keys!; self end
    def reject(&block) dup.reject!(&block) end
    def keys; @keys.dup end
    def values; @keys.collect { |key| self[key] } end
    def to_hash; self end
    def to_a; @keys.map { |key| [ key, self[key] ] } end
    def each_key; @keys.each { |key| yield key } end
    def each_value; @keys.each { |key| yield self[key]} end
    def each; @keys.each {|key| yield [key, self[key]]} end
    alias_method :each_pair, :each
    def clear; super; @keys.clear; self end
    def shift; k = @keys.first; v = delete(k) [k, v] end
    def merge!(other_hash) other_hash.each {|k,v| self[k] = v }; self end
    def merge(other_hash) dup.merge!(other_hash) end
    def inspect; "#<OrderedHash #{super}>" end
    private
    def sync_keys!() @keys.delete_if {|k| !has_key?(k)} end
  end
end

class Hash;        include ForHashes end
if RUBY_VERSION < '1.9'
  class OrderedHash; include ForHashes end
end

class OStruct < OpenStruct
  def initialize(hash=nil)
    @table = OrderedHash.new
    if hash
      for k,v in hash
        @table[k.to_sym] = v
        new_ostruct_member(k)
      end
    end
  end

  def to_h() self.marshal_dump end
  def pp() marshal_dump.map{|k,v| "#{k.to_s.ljust(24)} = #{String===v ? v : v.pretty_inspect.strip}"}.join("\n") end
  def |(other_ostruct) OStruct.new(marshal_dump.merge(other_ostruct.marshal_dump.reject{|k,v|v.nil?})) end
  def to_sig() marshal_dump.to_sig end
end

class UnixPerm
  def initialize(v) @v = v.numeric? ? (String===v ? (v.strip[0..0]=='0' ? eval(v) : eval('0'+v)) : v) : UnixPerm.desc_to_oct(v) end
  def to_s()    as_oct_str  end
  def inspect() as_desc_str end
  def as_oct_str()  '0' + @v.to_s(8) end
  def as_desc_str(prefix='') UnixPerm.oct_to_desc(@v,prefix)  end

  def self.desc_to_oct(v) raise "not yet implemented. haven't needed it yet." end
  def self.oct_to_desc(v, part_prefix='')
    s = ('0'*(3*4) + v.to_s(2))[-12..-1].each_char.map{|c| c == '1'}
    u = []; g = []; o = []; a = []
    u<<'s' if s[0]; g<<'s' if s[1];  a<<'t' if s[2]
    u<<'r' if s[3]; u<<'w' if s[4];  u<<'x' if s[5]
    g<<'r' if s[6]; g<<'w' if s[7];  g<<'x' if s[8]
    o<<'r' if s[9]; o<<'w' if s[10]; o<<'x' if s[11]
    "#{part_prefix}a=#{a.join},#{part_prefix}u=#{u.join},#{part_prefix}g=#{g.join},#{part_prefix}o=#{o.join}"
  end
end

class MatchData
  def to_hash()
    names = [] unless methods.include?(:names)
    nm = names || []
    nm.size > 0 ? OrderedHash[*(nm.amap(:to_sym).zip(captures) + [[0,self[0]]]).flatten] :
                  OrderedHash[*(0..size-1).to_a.zip(to_a).flatten]
  end
end

class Time
  def nmsec() Time.mktime(self.month == 12 ? self.year + 1 : self.year, ((self.month % 12) + 1), 1) - self     end
  def parts() [self.year, self.month, self.day, self.hour, self.min, self.sec, self.nmsec.round, self.wday, self.yday] end
end
