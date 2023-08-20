# frozen_string_literal: true

require "order_cop"

RSpec.describe "OrderCop::apply" do
  before(:each) do
    OrderCop.instance_variable_set(:@config, nil)
  end
  it "doesn't raise before apply" do
    expect do
      Post.all.to_a
    end.not_to raise_error
  end
end
