# figgy

[![Gem Version](https://badge.fury.io/rb/figgy.svg)](http://badge.fury.io/rb/figgy)
[![Build Status](https://secure.travis-ci.org/pd/figgy.svg)](http://travis-ci.org/pd/figgy)
[![Dependency Status](https://gemnasium.com/pd/figgy.svg)](https://gemnasium.com/pd/figgy)
[![Code Climate](https://codeclimate.com/github/pd/figgy.png)](https://codeclimate.com/github/pd/figgy)
[![Coverage Status](https://img.shields.io/coveralls/pd/figgy.svg)](https://coveralls.io/r/pd/figgy?branch=master)

Provides convenient access to configuration files in various formats, with
support for overriding the values based on environment, hostname, locale, or
any other arbitrary thing you happen to come up with.

## Documentation
[yardocs](http://rdoc.info/github/pd/figgy/master/frames)

## Installation

Just like everything else these days. In your Gemfile:

~~~ruby
gem 'figgy'
~~~

## Overview

Set it up (say, in a Rails initializer):

~~~ruby
AppConfig = Figgy.build do |config|
  config.root = Rails.root.join('etc')

  # config.foo is read from etc/foo.yml
  config.define_overlay :default, nil

  # config.foo is then updated with values from etc/production/foo.yml
  config.define_overlay(:environment) { Rails.env }

  # Maybe you need to load XML files?
  config.define_handler 'xml' do |contents|
    Hash.from_xml(contents)
  end
end
~~~

Access it as a dottable, indifferent-access hash:

~~~ruby
AppConfig.foo.some_key
AppConfig["foo"]["some_key"]
AppConfig[:foo].some_key
~~~

Multiple root directories may be specified, so that configuration files live in
more than one place (say, in gems):

~~~ruby
AppConfig = Figgy.build do |config|
  config.root = Rails.root.join('etc')
  config.add_root Rails.root.join('vendor/etc')
end
~~~

Precedence of root directories is in reverse order of definition, such that the
root directory added first (typically the one immediately within the application)
has highest precedence. In this way, defaults can be inherited from libraries,
but then overridden when necessary within the application.

## Caveats

Because the objects exposed by figgy are often hashes, all of the instance methods
of Hash (and, of course, Enumerable) are available along the chain. But note that
this means you can not use key names such as `size` or `each` with the dottable
access style:

~~~ruby
AppConfig.price.bulk   #=> 100.00
AppConfig.price.each   #=> attempts to invoke Hash#each
AppConfig.price[:each] #=> 50.00
~~~

## Thanks

This was written on [Enova's](http://www.enova.com) dime/time.
