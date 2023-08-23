# OrderCop

order_cop is a gem to help developpers add order on their database query when they iterate on the list.

## Why

When you iterate on a list, you may want to add an order on the list to be sure that the list is always ordered the same way.

Most of the time if you iterate in a view you will add an order on the query, but if you iterate in a controller or in a service you may not want to add the order. The gem help you with the config option :only_view.

## Installation

```bash

bundle add order_cop --group test,development

```

## Configuration

```bash

rails g order_cop:install

```

This will generate a file in config/initializers/order_cop.rb

```ruby
if defined?(OrderCop)
  OrderCop.config do |config|
    # Enable or disable OrderCop (defaults to true)
    # config.enabled = true

    # Raise an error when a query is not ordered (defaults to true)
    # config.raise = true

    # Log missing order queries to Rails.logger (defaults to false)
    # config.rails_logger = false

    # Only raise if the query is in a view (defaults to false)
    # config.only_view = false

    # Whitelist methods that don't need to be ordered (defaults to <%= OrderCop.config.whitelist_methods %>)
    # config.whitelist_methods = []

    # Whitelist views that don't need to be ordered (defaults to <%= OrderCop.config.view_paths %>)
    # config.view_paths = []
  end
end
```


## Usage

Mainly you want to run your test suite, it will raise on each missing order

## Development

```bash
git clone git@github.com:squadrace/order_cop.git
cd order_cop
bundle install
rake spec
```

If test pass, you are good to go.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/squadracer/order_cop.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
