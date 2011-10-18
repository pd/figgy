require 'simplecov'

SimpleCov.start

require 'rspec'
require 'configy'
require 'aruba/api'
require 'heredoc_unindent'

module Configy::SpecHelpers
  def test_config
    Configy.build do |config|
      config.root = current_dir
      yield config if block_given?
    end
  end

  def write_config(filename, contents)
    filename = "#{filename}.yml" unless filename =~ /\./
    write_file(filename, contents.unindent)
  end
end

RSpec.configure do |c|
  c.include Aruba::Api
  c.include Configy::SpecHelpers

  c.after { FileUtils.rm_rf(current_dir) }
end
