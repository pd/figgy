begin
  require 'coveralls'

  SimpleCov.formatters = [
    Coveralls::SimpleCov::Formatter,
    SimpleCov::Formatter::HTMLFormatter,
  ]

  SimpleCov.start
rescue LoadError
end
