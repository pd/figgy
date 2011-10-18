require "yaml"
require "configy/version"
require "configy/configuration"
require "configy/hash"
require "configy/finder"
require "configy/store"

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

    if @config.preload?
      @finder.all_key_names.each { |key| @store.get(key) }
    end
  end

  def method_missing(m, *args, &block)
    @store.get(m)
  end
end
