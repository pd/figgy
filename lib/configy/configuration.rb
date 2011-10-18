class Configy
  class Configuration
    attr_reader :root, :overlays
    attr_accessor :always_reload, :preload, :freeze

    def initialize
      self.root = Dir.pwd
      @handlers = []
      @overlays = []
      @always_reload = false
      @preload = false
      @freeze = false

      define_handler 'yml', 'yaml' do |contents|
        YAML.load(contents)
      end
    end

    def root=(path)
      @root = File.expand_path(path)
    end

    def always_reload?
      !!@always_reload
    end

    def preload?
      !!@preload
    end

    def freeze?
      !!@freeze
    end

    def define_overlay(name, value = nil)
      value = yield if block_given?
      @overlays << [name, value]
    end

    def define_combined_overlay(*names)
      combined_name = names.join("_").to_sym
      value = names.map { |name| overlay_value(name) }.join("_")
      @overlays << [combined_name, value]
    end

    def overlay_dirs
      return [@root] if @overlays.empty?
      overlay_values.map { |v| v ? File.join(@root, v) : @root }.uniq
    end

    def define_handler(*extensions, &block)
      @handlers += extensions.map { |ext| [ext, block] }
    end

    def extensions
      @handlers.map { |ext, handler| ext }
    end

    def handler_for(filename)
      extension = File.extname(filename).sub(/^\./, '')
      match = @handlers.find { |ext, handler| extension == ext }
      match && match.last
    end

    private

    def overlay_value(name)
      overlay = @overlays.find { |n, v| name == n }
      raise "No such overlay: #{name.inspect}" unless overlay
      overlay.last
    end

    def overlay_values
      @overlays.map &:last
    end
  end
end
