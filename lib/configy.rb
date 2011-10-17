require "configy/version"
require "yaml"

class Configy
  FileNotFound = Class.new(StandardError)

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
  end

  class Finder
    def initialize(config)
      @config = config
    end

    def load(name)
      filename = "#{name}.yml"

      result = @config.overlay_dirs.reduce(nil) do |result, dir|
        path = File.join(dir, filename)
        next result unless File.exist?(path)

        object = YAML.load(File.read(path))
        if result && result.respond_to?(:merge)
          deep_merge(result, object)
        else
          object
        end
      end

      raise(Configy::FileNotFound, "Can't find config files for key: #{name.inspect}") unless result
      result
    end

    private

    def deep_merge(a, b)
      a.merge(b) do |key, oldval, newval|
        oldval.respond_to?(:merge) && newval.respond_to?(:merge) ? deep_merge(oldval, newval) : newval
      end
    end
  end
end
