# frozen_string_literal: true

require_relative "order_cop/version"
require "active_record"
require "active_support"
require "rails"
require "ostruct"
require "binding_of_caller"

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup
module OrderCop
  module OrderCopMixin
    # patch all methods which iterate over the collection and return several records
    #  we don't patch `first` and `last`, take or others because they return a single record)
    #  we don't patch sort because it specifically doesn't need an order
    #  we don't patch select as it's a query method

    def each(...)
      detect_missing_order(:each) if order_values.empty?
      super(...)
    end

    def to_a
      detect_missing_order(:to_a) if order_values.empty?
      super
    end

    def map(...)
      detect_missing_order(:map) if order_values.empty?
      super(...)
    end

    def find_each(...)
      detect_missing_order(:find_each) if order_values.empty?
      super(...)
    end

    def find_in_batches(...)
      detect_missing_order(:find_in_batches) if order_values.empty?
      super(...)
    end

    def reject(...)
      detect_missing_order(:reject) if order_values.empty?
      super(...)
    end

    def reject!(&block)
      detect_missing_order(:reject!) if order_values.empty?
      super(&block)
    end

    private

    def stack_is_whitelisted?
      1.upto(binding.frame_count).each do |i|
        lbinding = binding.of_caller(i)
        lmethod = lbinding.eval("__method__")
        next if lmethod.nil?
        puts "lmethod: #{lmethod}" if OrderCop.debug?
        if OrderCop::WHITELIST.include?(lmethod)
          puts "#{lmethod} is whitelisted, ignoring" if OrderCop.debug?
          return true
        end
      end
      false
    end

    def detect_missing_order(method)
      return if OrderCop.disabled?
      puts "missing order, detect if allowed" if OrderCop.debug?
      puts "stack size: #{binding.frame_count}" if OrderCop.debug?

      return if stack_is_whitelisted?

      level = 1.upto(binding.frame_count).find do |i|
        lbinding = binding.of_caller(i)
        location = lbinding.source_location[0]
        location.include?(Rails.root.to_s) && !location.include?(Rails.root.join("config").to_s)
      end

      if level
        location = binding.of_caller(level - 1).source_location
        file_path = location.first.gsub(Rails.root.to_s, "")
        line_number = location.last
        msg = "Missing Order for :#{method} at #{file_path}:#{line_number}"
      else
        msg = "Missing Order for :#{method}"
      end

      if OrderCop.rails_logger?
        Rails.logger.error order_cop_red("Missing order for #{method}")
        caller.each do |line|
          Rails.logger.error order_cop_red("  #{line}") if line.include?(Rails.root.to_s)
        end
      end
      if OrderCop.raise?
        raise OrderCop::Error.new(msg)
      end
    end

    def order_cop_red(msg)
      ActiveSupport::LogSubscriber.new.send(:color, msg, :red)
    end
  end

  class Error < StandardError; end

  WHITELIST = %i[sum any? none? inspect method_missing not load_target reindex attachment attachments attributes_table with_current_arbre_element].freeze

  def self.disable(&block)
    old_enabled = @enabled
    @enabled = false
    yield
  ensure
    @enabled = old_enabled
  end

  def self.disabled?
    @enabled == false
  end

  def self.enabled?
    @enabled != false
  end

  def self.patch_active_record(app)
    ActiveRecord::Base.descendants.each do |model|
      model.const_get(:ActiveRecord_Associations_CollectionProxy).class_eval do
        prepend OrderCopMixin
      end
      model.const_get(:ActiveRecord_Relation).class_eval do
        prepend OrderCopMixin
      end
      model.const_get(:ActiveRecord_AssociationRelation).class_eval do
        prepend OrderCopMixin
      end
    end
  end

  def self.rails_logger?
    config.rails_logger
  end

  def self.raise?
    config.raise
  end

  def self.debug?
    config.debug
  end

  def self.config(**options)
    @config ||= OpenStruct.new(rails_logger: false, raise: true, enabled: true, debug: false)
    options.each do |k, v|
      @config[k] = v
    end
    @enabled = @config.enabled
    @config
  end

  def self.setup(**options)
    config(**options)
  end

  def self.apply(app = Rails.application)
    patch_active_record(app) if enabled?
  end

  if defined?(Rails::Railtie)
    class OrderCopRailtie < Rails::Railtie
      initializer "ordercop.patch" do |app|
        return if OrderCop.disabled?

        app.config.to_prepare do
          app&.eager_load!

          OrderCop.apply(app)
        end
      end
    end
  end
end

ActiveSupport::Reloader.to_prepare do
  OrderCop.apply(Rails.application)
end
