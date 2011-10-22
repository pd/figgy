class Figgy
  # The backing object for a {Figgy} instance.
  class Store
    def initialize(finder, config)
      @finder = finder
      @config = config
      @cache  = {}
    end

    # Retrieve the value for a key, expiring the cache and/or loading it
    # if necessary.
    #
    # @raise [Figgy::FileNotFound] if no config file could be found for +name+
    def get(key)
      key = key.to_s
      @cache.delete(key) if @config.always_reload?
      if @cache.key?(key)
        @cache[key]
      else
        @cache[key] = @finder.load(key)
      end
    end

    # @return [Array<String>] the list of currently loaded keys
    def keys
      @cache.keys
    end

    # @return [Integer] the current size of the cache
    def size
      @cache.size
    end
  end
end
