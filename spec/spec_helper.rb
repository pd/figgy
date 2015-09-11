require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  Coveralls::SimpleCov::Formatter,
  SimpleCov::Formatter::HTMLFormatter,
]

SimpleCov.start

require 'rspec'
require 'figgy'
require 'heredoc_unindent'

module Figgy::SpecHelpers
  def current_dir
    File.join(Dir.getwd, 'tmp')
  end

  def test_config
    Figgy.build do |config|
      config.root = current_dir
      yield config if block_given?
    end
  end

  def write_config(filename, contents)
    filename = "#{filename}.yml" unless filename =~ /\./
    full_filename = File.join(current_dir, filename)

    FileUtils.mkdir_p(File.dirname(full_filename))

    file = File.new(full_filename, "w+")
    file.write(contents)
    file.close
  end
end

RSpec.configure do |c|
  c.include Figgy::SpecHelpers

  c.after { FileUtils.rm_rf(current_dir) }
end
