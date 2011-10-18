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
      result
    end

    def all_key_names
      @config.overlay_dirs.reduce([]) { |acc, dir|
        files = Dir.chdir(dir) { Dir['*.yml'] }
        acc + files.map { |file| file.sub(/\.yml$/, '') }
      }.uniq
    end

    private

    def deep_merge(a, b)
      a.merge(b) do |key, oldval, newval|
        oldval.respond_to?(:merge) && newval.respond_to?(:merge) ? deep_merge(oldval, newval) : newval
      end
    end
  end
end
