class Figgy
  class Configuration
    # The directories in which to search for configuration files
    attr_reader :roots

    # The list of defined overlays
    attr_reader :overlays

    # Whether to reload a configuration file each time it is accessed
    attr_accessor :always_reload

    # Whether to load all configuration files upon creation
    # @note This does not prevent +:always_reload+ from working.
    attr_accessor :preload

    # Whether to freeze all loaded objects. Useful in production environments.
    attr_accessor :freeze

    # Constructs a new {Figgy::Configuration Figgy::Configuration} instance.
    #
    # By default, uses a +root+ of the current directory, and defines handlers
    # for +.yml+, +.yaml+, +.yml.erb+, +.yaml.erb+, and +.json+.
    def initialize
      @roots    = [Dir.pwd]
      @handlers = []
      @overlays = []
      @always_reload = false
      @preload = false
      @freeze = false

      define_handler 'yml', 'yaml' do |contents|
        YAML.load(contents)
      end

      define_handler 'yml.erb', 'yaml.erb' do |contents|
        erb = ERB.new(contents).result
        YAML.load(erb)
      end

      define_handler 'json' do |contents|
        JSON.parse(contents)
      end
    end

    def root=(path)
      @roots = [File.expand_path(path)]
    end

    def add_root(path)
      @roots.unshift File.expand_path(path)
    end

    # @see #always_reload=
    def always_reload?
      !!@always_reload
    end

    # @see #preload=
    def preload?
      !!@preload
    end

    # @see #freeze=
    def freeze?
      !!@freeze
    end

    # Adds an overlay named +name+, found at +value+.
    #
    # If a block is given, yields to the block to determine +value+.
    #
    # @param name an internal name for the overlay
    # @param value the value of the overlay
    # @example An environment overlay
    #   config.define_overlay(:environment) { Rails.env }
    def define_overlay(name, value = nil)
      value = yield if block_given?
      @overlays << [name, value]
    end

    # Adds an overlay using the combined values of other overlays.
    #
    # @example Searches for files in 'production_US'
    #   config.define_overlay :environment, 'production'
    #   config.define_overlay :country, 'US'
    #   config.define_combined_overlay :environment, :country
    def define_combined_overlay(*names)
      combined_name = names.join("_").to_sym
      value = names.map { |name| overlay_value(name) }.join("_")
      @overlays << [combined_name, value]
    end

    # @return [Array<String>] the list of directories to search for config files
    def overlay_dirs
      return @roots if @overlays.empty?
      overlay_values.map { |overlay|
        @roots.map { |root| overlay ? File.join(root, overlay) : root }
      }.flatten.uniq
    end

    # Adds a new handler for files with any extension in +extensions+.
    #
    # @example Adding an XML handler
    #   config.define_handler 'xml' do |body|
    #     Hash.from_xml(body)
    #   end
    def define_handler(*extensions, &block)
      @handlers += extensions.map { |ext| [ext, block] }
    end

    # Adds a new handler for files with any extension in +extensions+ or replaces existing ones.
    #
    # @example Adding an XML handler
    #   config.define_handler 'xml' do |body|
    #     Hash.from_xml(body)
    #   end
    def set_handler(*extensions, &block)
      @handlers = @handlers.select { |ext, _| extensions.exclude?(ext) }
      @handlers += extensions.map { |ext| [ext, block] }
    end

    # @return [Array<String>] the list of recognized extensions
    def extensions
      @handlers.map { |ext, handler| ext }
    end

    # @return [Proc] the handler for a given filename
    def handler_for(filename)
      match = @handlers.find { |ext, handler| filename =~ /\.#{ext}$/ }
      match && match.last
    end

    private

    def overlay_value(name)
      overlay = @overlays.find { |n, v| name == n }
      raise "No such overlay: #{name.inspect}" unless overlay
      overlay.last
    end

    def overlay_values
      @overlays.map(&:last)
    end
  end
end
