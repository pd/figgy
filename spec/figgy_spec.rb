require 'spec_helper'

describe Figgy do
  it "reads YAML config files" do
    write_config 'values', <<-YML
    foo: 1
    bar: 2
    YML

    expect(test_config.values).to eq({ "foo" => 1, "bar" => 2 })
  end

  it "raises an exception if the file can't be found" do
    expect { test_config.values }.to raise_error(Figgy::FileNotFound)
  end

  it "has a useful #inspect method" do
    write_config 'values', 'foo: 1'
    write_config 'wtf', 'bar: 2'

    config = test_config
    expect(config.inspect).to eq("#<Figgy (empty)>")

    config.values
    expect(config.inspect).to eq("#<Figgy (1 keys): values>")

    config.wtf
    expect(config.inspect).to eq("#<Figgy (2 keys): values wtf>")
  end

  context "multiple extensions" do
    it "supports .yaml" do
      write_config 'values.yaml', 'foo: 1'
      expect(test_config.values.foo).to eq(1)
    end

    it "supports .yml.erb and .yaml.erb" do
      write_config 'values.yml.erb', '<%= "foo" %>: <%= 1 %>'
      write_config 'values.yaml.erb', '<%= "foo" %>: <%= 2 %>'
      expect(test_config.values.foo).to eq(2)
    end

    it "supports .json" do
      write_config "values.json", '{ "json": true }'
      expect(test_config.values.json).to be true
    end

    it "loads in the order named" do
      write_config 'values.yml', 'foo: 1'
      write_config 'values.yaml', 'foo: 2'

      config = test_config do |config|
        config.define_handler('yml', 'yaml') { |body| YAML.load(body) }
      end
      expect(config.values.foo).to eq(2)
    end
  end

  context "hash contents" do
    it "makes the hash result dottable and indifferent" do
      write_config 'values', <<-YML
      outer:
        also: dottable
      YML

      config = test_config
      expect(config.values.outer).to eq({ "also" => "dottable" })
      expect(config.values["outer"]).to eq({ "also" => "dottable" })
      expect(config.values[:outer]).to eq({ "also" => "dottable" })
    end

    it "makes a hash inside the hash result dottable and indifferent" do
      write_config 'values', <<-YML
      outer:
        also: dottable
      YML

      config = test_config
      expect(config.values.outer.also).to eq("dottable")
      expect(config.values.outer["also"]).to eq("dottable")
      expect(config.values.outer[:also]).to eq("dottable")
    end

    it "makes a hash inside an array result dottable and indifferent" do
      write_config 'values', <<-YML
      outer:
        - in: an
          array: it is
        - still: a dottable hash
      YML

      config = test_config
      expect(config.values.outer.size).to eq(2)
      first, second = *config.values.outer

      expect(first).to eq({ "in" => "an", "array" => "it is" })
      expect(first[:in]).to eq("an")
      expect(first.array).to eq("it is")

      expect(second.still).to eq("a dottable hash")
      expect(second[:still]).to eq("a dottable hash")
      expect(second["still"]).to eq("a dottable hash")
    end

    it "supports dottable and indifferent setting" do
      write_config 'values', "number: 1"
      config = test_config
      config.values["number"] = 2
      expect(config.values.number).to eq(2)
      config.values[:number] = 3
      expect(config.values.number).to eq(3)
      config.values.number = 4
      expect(config.values.number).to eq(4)
    end

    it "answers respond_to? accurately for known keys" do
      write_config 'values', <<-YML
      outer:
        inner:
          still: a hash
      YML

      config = test_config
      expect(config).to respond_to(:values)
      expect(config).not_to respond_to(:unknown)

      expect(config.values).to respond_to(:outer)
      expect(config.values.outer).to respond_to(:inner)
      expect(config.values.outer.inner).to respond_to(:still)

      # Ensure plain ol' respond_to? still works, too.
      expect(config).to respond_to(:inspect)
      expect(config.values).to respond_to(:[])
    end

    it "supports indifferent hash notation on the top-level config object" do
      write_config 'values', "number: 1"
      config = test_config
      expect(config['values']).to eq(config.values)
      expect(config[:values]).to  eq(config.values)
    end

    context "performing basic hash operations" do
      let(:config) do
        write_config 'values', <<-YML
        with:
          one: 1
          two: 2
        without:
          two: 2
        another:
          three: 3
        altogether:
          one: 1
          two: 2
          three: 3
        YML
        test_config
      end

      it "can delete a key" do
        expect(config.values.with.delete(:one)).to eq(1)
        expect(config.values.with).to eq(config.values.without)
      end

      it "can look up values for a list of keys" do
        expect(config.values.with.values_at(:one,:two)).to eq([1,2])
      end

      it "can merge with another hash" do
        expect(config.values.with.merge(config.values.another)).to eq(config.values.altogether)
      end
    end
  end

  context 'oddities' do
    it "returns false for empty files (cf. YAML.load(''))" do
      write_config 'empty', ''
      expect(test_config.empty).to eq(false)
    end

    it "returns false for files containing a literal false" do
      write_config 'maybe', 'false'
      expect(test_config.maybe).to eq(false)
    end

    it "returns nil when explicitly set to that value in the YAML file" do
      write_config 'reason_to_do_this', nil.to_yaml
      expect(test_config.reason_to_do_this).to eq(nil)
    end

    it "prioritizes hash methods over keys in the YAML file" do
      write_config 'bad', { 'default' => 'something'}.to_yaml
      expect(test_config.bad.default).to eq(nil)
    end
  end

  context "multiple roots" do
    it "can be told to read from multiple directories" do
      write_config 'root1/values', 'foo: 1'
      write_config 'root2/values', 'bar: 2'

      config = test_config do |config|
        config.root = File.join(current_dir, 'root1')
        config.add_root File.join(current_dir, 'root2')
      end

      expect(config.values.foo).to eq(1)
      expect(config.values.bar).to eq(2)
    end

    it "supports overlays in each root" do
      write_config 'root1/values',      'foo: 1'
      write_config 'root1/prod/values', 'foo: 2'
      write_config 'root2/values',      'bar: 1'
      write_config 'root2/prod/values', 'bar: 2'

      config = test_config do |config|
        config.root = File.join(current_dir, 'root1')
        config.add_root File.join(current_dir, 'root2')
        config.define_overlay :environment, 'prod'
      end

      expect(config.values.foo).to eq(2)
      expect(config.values.bar).to eq(2)
    end

    it "reads from roots in *reverse* order of definition" do
      write_config 'root1/values', 'foo: 1'
      write_config 'root1/prod/values', 'foo: 2'
      write_config 'root2/prod/values', 'foo: 3'

      config = test_config do |config|
        config.root = File.join(current_dir, 'root1')
        config.add_root File.join(current_dir, 'root2')
        config.define_overlay :environment, 'prod'
      end

      expect(config.values.foo).to eq(2)
    end
  end

  context "overlays" do
    it "defaults to no overlay, thus reading directly from the config root" do
      write_config 'values', "foo: 1"
      expect(test_config.values).to eq({ "foo" => 1 })
    end

    it "interprets a nil overlay value as an indication to read from the config root" do
      write_config 'values', "foo: 1"
      config = test_config do |config|
        config.define_overlay :default, nil
      end
      expect(config.values).to eq({ "foo" => 1 })
    end

    it "allows the overlay's value to be the result of a block" do
      write_config 'prod/values', "foo: 1"
      config = test_config do |config|
        config.define_overlay(:environment) { 'prod' }
      end
      expect(config.values).to eq({ "foo" => 1 })
    end

    it "overwrites values if the config file does not define a hash" do
      write_config 'some_string', "foo bar baz"
      write_config 'prod/some_string', "foo bar baz quux"

      config = test_config do |config|
        config.define_overlay :default, nil
        config.define_overlay :environment, 'prod'
      end

      expect(config.some_string).to eq("foo bar baz quux")
    end

    it "deep merges hash contents from overlays" do
      write_config 'defaults/values', <<-YML
      foo:
        bar: 1
        baz: 2
      YML

      write_config 'prod/values', <<-YML
      foo:
        baz: 3
      quux: hi!
      YML

      config = test_config do |config|
        config.define_overlay :default, 'defaults'
        config.define_overlay :environment, 'prod'
      end

      expect(config.values).to eq({ "foo" => { "bar" => 1, "baz" => 3 }, "quux" => "hi!" })
    end

    it "can use both a nil overlay and an overlay with a value" do
      write_config 'values', "foo: 1\nbar: 2"
      write_config 'prod/values', "foo: 2"
      config = test_config do |config|
        config.define_overlay :default, nil
        config.define_overlay :environment, 'prod'
      end
      expect(config.values).to eq({ "foo" => 2, "bar" => 2 })
    end

    it "reads from overlays in order of definition" do
      write_config 'defaults/values', <<-YML
      foo: 1
      bar: 1
      baz: 1
      YML

      write_config 'prod/values', <<-YML
      bar: 2
      baz: 2
      YML

      write_config 'local/values', <<-YML
      baz: 3
      YML

      config = test_config do |config|
        config.define_overlay :default, 'defaults'
        config.define_overlay :environment, 'prod'
        config.define_overlay :local, 'local'
      end

      expect(config.values).to eq({ "foo" => 1, "bar" => 2, "baz" => 3 })
    end
  end

  context "combined overlays" do
    it "allows new overlays to be defined from the values of others" do
      write_config 'keys', "foo: 1"
      write_config 'prod/keys', "foo: 2"
      write_config 'prod_US/keys', "foo: 3"

      config = test_config do |config|
        config.define_overlay :default, nil
        config.define_overlay :environment, 'prod'
        config.define_overlay :country, 'US'
        config.define_combined_overlay :environment, :country
      end

      expect(config.keys).to eq({ "foo" => 3 })
    end
  end

  context "reloading" do
    it "can reload on each access when config.always_reload = true" do
      write_config 'values', 'foo: 1'
      config = test_config do |config|
        config.always_reload = true
      end
      expect(config.values).to eq({ "foo" => 1 })

      write_config 'values', 'foo: bar'
      expect(config.values).to eq({ "foo" => "bar" })
    end

    it "does not reload when config.always_reload = false" do
      write_config 'values', 'foo: 1'
      config = test_config do |config|
        config.always_reload = false
      end
      expect(config.values).to eq({ "foo" => 1 })

      write_config 'values', 'foo: bar'
      expect(config.values).to eq({ "foo" => 1 })
    end
  end

  context "preloading" do
    it "can preload all available configs when config.preload = true" do
      write_config 'values', 'foo: 1'
      write_config 'prod/values', 'foo: 2'
      write_config 'prod/prod_only', 'bar: baz'

      config = test_config do |config|
        config.define_overlay :default, nil
        config.define_overlay :environment, 'prod'
        config.preload = true
      end

      write_config 'prod/values', 'foo: 3'
      write_config 'prod_only', 'bar: quux'

      expect(config.values['foo']).to eq(2)
      expect(config.prod_only['bar']).to eq('baz')
    end

    it "still works with multiple extension support" do
      write_config 'values.yaml', 'foo: 1'
      write_config 'values.json', '{ "foo": 2 }'
      write_config 'prod/lonely.yml', 'only: yml'
      write_config 'local/json_values.json', '{ "json": true }'

      config = test_config do |config|
        config.define_overlay :default, nil
        config.define_overlay :environment, 'prod'
        config.define_overlay :local, 'local'
      end

      finder = config.instance_variable_get(:@finder)
      expect(finder.all_key_names).to eq(['values', 'lonely', 'json_values'])
    end

    it "still supports reloading when preloading is enabled" do
      write_config 'values', 'foo: 1'

      config = test_config do |config|
        config.preload = true
        config.always_reload = true
      end

      expect(config.values['foo']).to eq(1)

      write_config 'values', 'foo: 2'
      expect(config.values['foo']).to eq(2)
    end
  end

  context "freezing" do
    it "leaves results unfrozen by default" do
      write_config 'values', "foo: '1'"
      expect(test_config.values.foo).not_to be_frozen
    end

    it "freezes the results when config.freeze = true" do
      write_config 'values', "foo: '1'"
      config = test_config do |config|
        config.freeze = true
      end
      expect(config.values).to be_frozen
    end

    it "freezes all the way down" do
      write_config 'values', <<-YML
      outer:
        key: value
        array:
          - some string
          - another string
          - and: an inner hash
      YML

      config = test_config do |config|
        config.freeze = true
      end

      expect { config.values.outer.array[2]['and'] = 'foo' }.to raise_error(/can't modify frozen/)
      assert_deeply_frozen(config.values)
    end

    def assert_deeply_frozen(obj)
      expect(obj).to be_frozen
      case obj
      when Hash then obj.each { |k, v| assert_deeply_frozen(k); assert_deeply_frozen(v) }
      when Array then obj.each { |v| assert_deeply_frozen(v) }
      end
    end
  end
end
