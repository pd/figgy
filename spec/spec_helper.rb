require 'simplecov'

SimpleCov.start

require 'rspec'
require 'configy'
require 'aruba/api'
require 'heredoc_unindent'

RSpec.configure do |c|
  c.include Aruba::Api
  c.after { FileUtils.rm_rf(current_dir) }
end
