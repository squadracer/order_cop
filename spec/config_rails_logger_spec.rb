# frozen_string_literal: true

require "order_cop"

RSpec.describe "config.rails_logger" do
  before(:each) do
    OrderCop.instance_variable_set(:@config, nil)
  end

  it "log a error" do
    OrderCop.config(rails_logger: true, raise: false)
    OrderCop.apply

    expect(Rails.logger).to receive(:error).with(/Missing Order for :to_a/)
    expect(Rails.logger).to receive(:error).with(/lib\/order_cop.rb/)
    expect(Rails.logger).to receive(:error).with(/spec\/config_rails_logger_spec.rb/)

    Post.all.to_a
  end

  it "log without raising" do
    OrderCop.config(rails_logger: true, raise: false)
    OrderCop.apply

    expect do
      Post.all.to_a
    end.not_to raise_error
  end
end
