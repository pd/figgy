require "yaml"
require "erb"
require "json"

require "figgy/version"
require "figgy/configuration"
require "figgy/hash"
require "figgy/finder"
require "figgy/store"

# An instance of Figgy is the object used to provide access to your
# configuration files. This does very little but recognize missing
# methods and go look them up as a configuration key.
#
# To create a new instance, you probably want to use +Figgy.build+:
#
#   MyConfig = Figgy.build do |config|
#     config.root = '/path/to/my/configs'
#   end
#   MyConfig.foo.bar #=> read from /path/to/my/configs/foo.yml
#
# This should maybe be a BasicObject or similar, to provide as many
# available configuration keys as possible. Maybe.
class Figgy
  FileNotFound = Class.new(StandardError)

  # @yield [Figgy::Configuration] an object to set things up with
  # @return [Figgy] a Figgy instance using the configuration
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

  def inspect
    if @store.size > 0
      key_names = @store.keys.sort
      "#<Figgy (#{@store.size} keys): #{key_names.join(' ')}>"
    else
      "#<Figgy (empty)>"
    end
  end
end
