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
    @store  = Store.new(@finder, @config)
  end

  def method_missing(m, *args, &block)
    @store.get(m)
  end

  class Store
    def initialize(finder, config)
      @finder = finder
      @config = config
      @cache  = {}
    end

    def get(key)
      key = key.to_s
      maybe_invalidate(key)
      if @cache.key?(key)
        @cache[key]
      else
        @cache[key] = @finder.load(key)
      end
    end

    private

    def maybe_invalidate(key)
      if @config.always_reload? # || stale?
        @cache.delete(key)
      end
    end
  end

  class Configuration
    attr_reader :root, :overlays
    attr_accessor :always_reload

    def initialize
      self.root = Dir.pwd
      @overlays = []
      @always_reload = false
    end

    def root=(path)
      @root = File.expand_path(path)
    end

    def always_reload?
      @always_reload
    end

    def define_overlay(name, value = nil)
      value = yield if block_given?
      @overlays << [name, value]
    end

    def define_combined_overlay(*names)
      combined_name = names.join("_").to_sym
      value = names.map { |name| overlay_value(name) }.join("_")
      @overlays << [combined_name, value]
    end

    def overlay_dirs
      return [@root] if @overlays.empty?
      overlay_values.map { |v| v ? File.join(@root, v) : @root }.uniq
    end

    private

    def overlay_value(name)
      overlay = @overlays.find { |n, v| name == n }
      raise "No such overlay: #{name.inspect}" unless overlay
      overlay.last
    end

    def overlay_values
      @overlays.map &:last
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
