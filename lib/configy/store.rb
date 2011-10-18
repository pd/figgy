class Configy
  class Store
    def initialize(finder, config)
      @finder = finder
      @config = config
      @cache  = {}
    end

    def get(key)
      key = key.to_s
      @cache.delete(key) if @config.always_reload?
      if @cache.key?(key)
        @cache[key]
      else
        @cache[key] = @finder.load(key)
      end
    end
  end
end
