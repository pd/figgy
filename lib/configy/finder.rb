class Configy
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

      raise(Configy::FileNotFound, "Can't find config files for key: #{name.inspect}") unless result
      deep_freeze(to_configy_hash(result))
    end

    def files_for(name)
      @config.overlay_dirs.reduce([]) { |acc, dir|
        next acc unless File.directory?(dir)
        exts = @config.extensions.map { |ext| "*.#{ext}" }
        files = Dir.chdir(dir) do
          Dir[*exts].map { |dir| File.expand_path(dir) }
        end
        acc + files
      }
    end

    def all_key_names
      @config.overlay_dirs.reduce([]) { |acc, dir|
        files = Dir.chdir(dir) { Dir['*.yml'] }
        acc + files.map { |file| file.sub(/\.yml$/, '') }
      }.uniq
    end

    private

    def to_configy_hash(obj)
      case obj
      when ::Hash
        obj.each_pair { |k, v| obj[k] = to_configy_hash(v) }
        Configy::Hash.new(obj)
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
