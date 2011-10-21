require "yaml"
require "erb"
require "json"

require "figgy/version"
require "figgy/configuration"
require "figgy/hash"
require "figgy/finder"
require "figgy/store"

class Figgy
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

    if @config.preload?
      @finder.all_key_names.each { |key| @store.get(key) }
    end
  end

  def method_missing(m, *args, &block)
    @store.get(m)
  end
end
