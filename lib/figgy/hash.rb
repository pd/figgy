class Figgy
  # Stolen from Thor::CoreExt::HashWithIndifferentAccess
  # It's smaller and more grokkable than ActiveSupport's.
  class Hash < ::Hash
    def initialize(hash = {})
      super()
      hash.each do |key, value|
        self[convert_key(key)] = value
      end
    end

    def [](key)
      super(convert_key(key))
    end

    def []=(key, value)
      super(convert_key(key), value)
    end

    def delete(key)
      super(convert_key(key))
    end

    def values_at(*indices)
      indices.collect { |key| self[convert_key(key)] }
    end

    def merge(other)
      dup.merge!(other)
    end

    def merge!(other)
      other.each do |key, value|
        self[convert_key(key)] = value
      end
      self
    end

    def respond_to?(m, *)
      super || key?(convert_key(m))
    end if RUBY_VERSION == "1.8.7"

    def respond_to_missing?(m, *)
      key?(convert_key(m)) || super
    end

    protected

    def convert_key(key)
      key.is_a?(Symbol) ? key.to_s : key
    end

    def method_missing(m, *args, &block)
      if m.to_s.end_with? "="
        self[m.to_s.chop] = args.shift
      else
        self[m]
      end
    end
  end
end
