require 'spec_helper'

describe Configy do
  def write_config(filename, contents)
    write_file("#{filename}.yml", contents.unindent)
  end

  it "reads YAML config files" do
    write_config 'defaults/magic_numbers', <<-YML
    bar: 12
    baz: 17
    YML

    config = Configy.build do |config|
      config.root = current_dir
      config.define_overlay :default, 'defaults'
    end

    config.magic_numbers.should == { "bar" => 12, "baz" => 17 }
  end

  it "handles overlays" do
    write_config 'defaults/magic_numbers', <<-YML
    foo: 17
    YML

    write_config 'prod/magic_numbers', <<-YML
    foo: 19
    YML

    config = Configy.build do |config|
      config.root = current_dir
      config.define_overlay :default, 'defaults'
      config.define_overlay :environment, 'prod'
    end

    config.magic_numbers.should == { "foo" => 19 }
  end
end

describe Configy do
  it "doesn't merge unmergeables"
  it "deep merges"
  it "blows up if it can't find a file"
  it "loads in order of overlay definition"
  it "works with nil overlay"
  it "works with nil + another overlay"

  it "should support reloading on each access"
  it "should support temporal reloading"
  it "should support pre-loading"
  it "should support not reloading"

  it "should support freezing the contents"
  it "should support NOT freezing the contents"
end
