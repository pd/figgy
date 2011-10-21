class Figgy
  class Finder
    def initialize(config)
      @config = config
    end

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
      deep_freeze(to_configy_hash(result))
    end

    def files_for(name)
      Dir[*file_globs(name)]
    end

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

    def to_configy_hash(obj)
      case obj
      when ::Hash
        obj.each_pair { |k, v| obj[k] = to_configy_hash(v) }
        Figgy::Hash.new(obj)
      when Array
        obj.map { |v| to_configy_hash(v) }
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
