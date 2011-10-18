class Configy
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
      to_configy_hash(result)
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

    def deep_merge(a, b)
      a.merge(b) do |key, oldval, newval|
        oldval.respond_to?(:merge) && newval.respond_to?(:merge) ? deep_merge(oldval, newval) : newval
      end
    end
  end
end
