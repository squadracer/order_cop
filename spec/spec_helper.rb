# frozen_string_literal: true

require "order_cop"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require "active_record"

ActiveRecord::Migration.verbose = false

class Post < ActiveRecord::Base
  has_many :comments
  def self.reindex
    all.to_a
  end
end

class Comment < ActiveRecord::Base
  belongs_to :post
end

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define(version: 1) do
  create_table :posts do |t|
  end

  create_table :comments do |t|
    t.references :post
  end
end
