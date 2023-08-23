# frozen_string_literal: true

require "order_cop"

RSpec.describe OrderCop do
  before(:each) do
    OrderCop.instance_variable_set(:@config, nil)
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
    OrderCop.config(raise: false)

    expect(OrderCop.config.raise).to eq(false)
  end

  it "is enabled before config" do
    expect(OrderCop.disabled?).to eq(false)
    expect(OrderCop.config.enabled).to eq(true)
  end

  it "is enabled after config" do
    OrderCop.config(enabled: true)
    expect(OrderCop.config.enabled).to eq(true)
  end

  it "is enabled after block config" do
    OrderCop.config do |config|
      config.enabled = true
    end
    expect(OrderCop.config.enabled).to eq(true)
  end

  it "raise if Post are not ordered" do
    OrderCop.apply
    expect do
      Post.all.to_a
    end.to raise_error(OrderCop::Error)
  end

  [:each, :map, :find_each, :find_in_batches, :reject].each do |method|
    it "doesn't raise if Post are ordered with #{method}" do
      OrderCop.apply
      expect do
        Post.order(:id).send(method) { |post| post }.to_a
      end.to_not raise_error
    end

    it "raise if Post are not ordered with #{method}" do
      OrderCop.apply
      expect do
        Post.all.send(method) { |post| post }.to_a
      end.to raise_error(OrderCop::Error)
    end
  end

  it "doesn't raise if Post are ordered" do
    OrderCop.apply
    expect do
      Post.order(:id).to_a
    end.not_to raise_error
  end

  it "raise if post.comments are not ordered" do
    OrderCop.apply
    expect(OrderCop.config.raise).to eq(true)
    expect do
      Post.new.comments.to_a
    end.to raise_error(OrderCop::Error)
  end

  it "doesn't raise if post.comments are ordered" do
    OrderCop.apply
    expect do
      Post.new.comments.order(:id).to_a
    end.not_to raise_error
  end
end
