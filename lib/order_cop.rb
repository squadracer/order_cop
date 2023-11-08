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
  class OrderCopConfig
    def initialize
      @enabled = true
      @raise = true
      @debug = false
      @rails_logger = false
      @whitelist_methods = %i[sum any? none? inspect method_missing not load_target reindex attachment attachments attributes_table with_current_arbre_element]
      @only_view = false
      @view_paths = [
        /app\/views/,
        /app\/helpers/,
        /\.erb/,
        /\.haml/,
        /\.slim/,
        /\(erb\)/
      ].freeze
    end
    attr_accessor :enabled, :raise, :debug, :rails_logger, :whitelist_methods, :only_view, :view_paths
  end

  def self.config(**options, &block)
    @config ||= OrderCopConfig.new
    options.each do |key, value|
      @config.send("#{key}=", value)
    end
    yield @config if block
    @config
  end

  def self.disabled?
    !config.enabled
  end

  def self.enabled?
    config.enabled
  end

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

    private

    def stack_is_whitelisted?
      1.upto(binding.frame_count).each do |i|
        lbinding = binding.of_caller(i)
        lmethod = lbinding.eval("__method__")
        next if lmethod.nil?
        puts "lmethod: #{lmethod}" if OrderCop.config.debug
        if OrderCop.config.whitelist_methods.include?(lmethod)
          puts "#{lmethod} is whitelisted, ignoring" if OrderCop.config.debug
          return true
        end
      end
      false
    end

    def stack_in_view?
      1.upto(binding.frame_count).each do |i|
        lbinding = binding.of_caller(i)
        location = lbinding.source_location[0]
        puts "location: #{location}" if OrderCop.config.debug
        if OrderCop.config.view_paths.any? { location.match(_1) }
          puts "#{location} is in view" if OrderCop.config.debug
          return true
        end
      end
      false
    end

    def detect_missing_order(method)
      return if OrderCop.disabled?
      puts "missing order, detect if allowed" if OrderCop.config.debug
      puts "stack size: #{binding.frame_count}" if OrderCop.config.debug

      return if stack_is_whitelisted?
      return if OrderCop.config.only_view && !stack_in_view?

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

      red = ->(msg) { ActiveSupport::LogSubscriber.new.send(:color, msg, :red) }

      if OrderCop.config.rails_logger
        Rails.logger.error red.call(msg)
        caller.each do |line|
          Rails.logger.error red.call("  #{line}") if line.include?(Rails.root.to_s) && !line.include?((Rails.root + "vendor").to_s)
        end
      end
      if OrderCop.config.raise
        raise OrderCop::Error.new(msg)
      end
    end
  end

  class Error < StandardError; end

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

  def self.apply(app = Rails.application)
    patch_active_record(app) if enabled?
  end

  if defined?(Rails::Railtie)
    require_relative "order_cop/install_generator"

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
