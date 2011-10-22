# figgy

Provides convenient access to configuration files in various formats, with
support for overriding the values based on environment, hostname, locale, or
any other arbitrary thing you happen to come up with.

## Travis-CI Build Status
[![Build Status](https://secure.travis-ci.org/pd/figgy.png)](http://travis-ci.org/pd/figgy)

## Documentation
[yardocs](http://rdoc.info/pd/figgy)

## Installation

Just like everything else these days. In your Gemfile:

    gem 'figgy'

## Overview

Set it up (say, in a Rails initializer):

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

Access it as a dottable, indifferent-access hash:

    AppConfig.foo.some_key
    AppConfig["foo"]["some_key"]
    AppConfig[:foo].some_key

## Thanks

This was written on [Enova Financial's](http://www.enovafinancial.com) dime/time.
