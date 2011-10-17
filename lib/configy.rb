require "configy/version"
require "yaml"

class Configy
  def self.build(&block)
    config = Configuration.new
    block.call(config)
    new(config)
  end

  def initialize(config)
    @config = config
    @finder = Finder.new(config)
    @cache  = {}
  end

  def method_missing(m, *args, &block)
    m = m.to_s
    if @cache.key?(m)
      @cache[m]
    else
      @cache[m] = @finder.load(m)
    end
  end

  class Configuration
    attr_reader :root, :overlays

    def initialize
      self.root = Dir.pwd
      @overlays = []
    end

    def root=(path)
      @root = File.expand_path(path)
    end

    def define_overlay(name, value)
      @overlays << [name, value]
    end

    def overlay_values
      @overlays.map &:last
    end

    def overlay_dirs
      return [@root] if @overlays.empty?
      overlay_values.map { |v| v ? File.join(@root, v) : @root }.uniq
    end

    def each_overlay_dir(&block)
      overlay_dirs.each(&block)
    end
  end

  class Finder
    def initialize(config)
      @config = config
    end

    def load(name)
      result = nil

      @config.each_overlay_dir do |dir|
        path = File.join(dir, "#{name}.yml")

        next unless File.exist?(path)
        if result && result.respond_to?(:merge)
          result = deep_merge(result, YAML.load(File.read(path)))
        else
          result = YAML.load(File.read(path))
        end
      end

      result
    end

    def deep_merge(a, b)
      a.merge(b) do |key, oldval, newval|
        oldval.respond_to?(:merge) && newval.respond_to?(:merge) ? deep_merge(oldval, newval) : newval
      end
    end
  end
end
