# frozen_string_literal: true

require "active_record"
class Post < ActiveRecord::Base
end
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Schema.define(version: 1) do
  create_table :posts do |t|
  end
end

require "order_cop"

module Rails
  class << self
    def root
      Pathname.new(File.expand_path(__FILE__).split("/")[0..-3].join("/"))
    end

    def env
      "test"
    end
  end
end

RSpec.describe OrderCop do
  before(:each) do
    OrderCop.setup(raise: true, enabled: true)
  end
  it "has a version number" do
    expect(OrderCop::VERSION).not_to be nil
  end

  it "raise by default" do
    expect(OrderCop.config.raise).to eq(true)
  end

  it "doesn't log by default" do
    expect(OrderCop.config.rails_logger).to eq(false)
  end

  it "doesn't raise when configured" do
    OrderCop.setup(raise: false)

    expect(OrderCop.config.raise).to eq(false)
  end

  it "is enabled before setup" do
    expect(OrderCop.config.enabled).to eq(true)
  end

  it "is enabled after setup" do
    OrderCop.setup(enabled: true)
    expect(OrderCop.config.enabled).to eq(true)
  end
  it "doesn't raise before apply" do
    expect do
      Post.all.to_a
    end.not_to raise_error
  end
  it "raise if Post are not ordered" do
    OrderCop.apply
    expect(OrderCop.raise?).to eq(true)
    expect do
      Post.all.to_a
    end.to raise_error(OrderCop::Error)
  end
  it "doesn't raise if Post are ordered" do
    OrderCop.apply
    expect do
      Post.order(:id).to_a
    end.not_to raise_error
  end
end
