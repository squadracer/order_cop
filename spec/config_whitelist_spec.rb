# frozen_string_literal: true

require "order_cop"

RSpec.describe "config.whitelist" do
  before(:each) do
    OrderCop.instance_variable_set(:@config, nil)
  end

  it "whitelist reindex" do
    OrderCop.apply
    expect do
      Post.reindex
    end.not_to raise_error
  end
  it "whitelist a new method" do
    OrderCop.config do |config|
      config.whitelist_methods = [:foobar]
    end
    expect(OrderCop.config.whitelist_methods).to eq([:foobar])
  end
end
