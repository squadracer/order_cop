# frozen_string_literal: true

require "order_cop"

RSpec.describe "config.only_view" do
  before(:each) do
    OrderCop.instance_variable_set(:@config, nil)
  end
  context "when config.only_view is true" do
    before(:each) do
      OrderCop.config(only_view: true)
      OrderCop.apply
    end

    it "doesn't raise if we are not in a view" do
      expect do
        Post.all.to_a
      end.not_to raise_error
    end

    it "raise if we are in a view" do
      template = ERB.new <<-EOF
        <%= Post.all.to_a %>
      EOF
      expect do
        template.result(binding)
      end.to raise_error OrderCop::Error
    end
  end
end
