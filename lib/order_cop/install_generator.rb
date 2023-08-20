# frozen_string_literal: true

require "rails/generators"

module OrderCop
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("../../templates", __FILE__)
    desc "Install OrderCop in your Ruby on Rails application"

    def add_initializer
      template "order_cop.rb.erb", "config/initializers/order_cop.rb"
    end
  end
end
