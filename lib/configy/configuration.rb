class Configy
  class Configuration
    attr_reader :root, :overlays
    attr_accessor :always_reload, :preload

    def initialize
      self.root = Dir.pwd
      @overlays = []
      @always_reload = false
      @preload = false
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
