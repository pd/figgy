require "configy/version"
require 'yaml'

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
    attr_accessor :root, :overlays

    def initialize
      @root = Dir.pwd
      @overlays = []
    end

    def define_overlay(name, value)
      @overlays << [name, value]
    end

    def each_overlay_dir
      @overlays.each do |name, value|
        yield File.join(@root, value)
      end
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
        if result && result.respond_to?(:merge!)
          result.merge!(YAML.load(File.read(path)))
        else
          result = YAML.load(File.read(path))
        end
      end

      result
    end
  end
end
