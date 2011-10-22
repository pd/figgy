class Figgy
  class Finder
    def initialize(config)
      @config = config
    end

    # Searches for files defining the configuration key +name+, merging each
    # instance found with the previous. In this way, the overlay configuration
    # at +production/foo.yml+ can override values in +foo.yml+.
    #
    # If the contents of the file were a Hash, Figgy will translate it into
    # a {Figgy::Hash Figgy::Hash} and perform deep-merging for all overlays. This
    # allows you to override only a single key deep within the configuration, and to
    # access it using dot-notation, symbol keys or string keys.
    #
    # @param [String] name the configuration file to load
    # @return Whatever was in the config file loaded
    # @raise [Figgy::FileNotFound] if no config file could be found for +name+
    def load(name)
      result = files_for(name).reduce(nil) do |result, file|
        object = @config.handler_for(file).call(File.read(file))
        if result && result.respond_to?(:merge)
          deep_merge(result, object)
        else
          object
        end
      end

      raise(Figgy::FileNotFound, "Can't find config files for key: #{name.inspect}") unless result
      deep_freeze(to_figgy_hash(result))
    end

    # @param [String] name the configuration key to search for
    # @return [Array<String>] the paths to all files to load for configuration key +name+
    def files_for(name)
      Dir[*file_globs(name)]
    end

    # @return [Array<String>] the names of all unique configuration keys
    def all_key_names
      Dir[*file_globs].map { |file| File.basename(file).sub(/\..+$/, '') }.uniq
    end

    private

    def file_globs(name = '*')
      globs = extension_globs(name)
      @config.overlay_dirs.map { |dir|
        globs.map { |glob| File.join(dir, glob) }
      }.flatten
    end

    def extension_globs(name = '*')
      @config.extensions.map { |ext| "#{name}.#{ext}" }
    end

    def to_figgy_hash(obj)
      case obj
      when ::Hash
        obj.each_pair { |k, v| obj[k] = to_figgy_hash(v) }
        Figgy::Hash.new(obj)
      when Array
        obj.map { |v| to_figgy_hash(v) }
      else
        obj
      end
    end

    def deep_freeze(obj)
      return obj unless @config.freeze?
      case obj
      when ::Hash
        obj.each_pair { |k, v| obj[deep_freeze(k)] = deep_freeze(v) }
      when Array
        obj.map! { |v| deep_freeze(v) }
      end
      obj.freeze
    end

    def deep_merge(a, b)
      a.merge(b) do |key, oldval, newval|
        oldval.respond_to?(:merge) && newval.respond_to?(:merge) ? deep_merge(oldval, newval) : newval
      end
    end
  end
end
