# HttpScanner

[![Build Status](https://travis-ci.org/bsdavidson/http_scanner.svg?branch=master)](https://travis-ci.org/bsdavidson/http_scanner)

A small Ruby gem that will scan your local network for running HTTP services and return an array IP addresses.

Documentation is [available on RubyDoc.info](http://www.rubydoc.info/github/bsdavidson/http_scanner/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'http_scanner'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install http_scanner

## Usage

```ruby
require 'http_scanner'

scanner = HttpScanner.new
ip_addresses = scanner.scan('SomeText')   # Look for pages containing SomeText
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/bsdavidson/http_scanner/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
