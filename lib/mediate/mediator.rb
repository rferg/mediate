# frozen_string_literal: true

require "singleton"

require_relative "errors/no_handler_error"
require_relative "error_handler"
require_relative "notification"
require_relative "notification_handler"
require_relative "postrequest_behavior"
require_relative "prerequest_behavior"
require_relative "request"
require_relative "request_handler"

module Mediate
  class Mediator
    include Singleton

    def initialize
      @request_handlers = {}
      @notification_handlers = {}
      @prerequest_behaviors = {}
      @postrequest_behaviors = {}
      @exception_handlers = {}
    end

    def dispatch(request)
      raise ArgumentError, "request cannot be nil" if request.nil?

      base_class = Mediate::Request
      request_handler = resolve_handler(@request_handlers, request.class, base_class)
      raise NoHandlerError, request.class if request_handler == NullHandler

      prerequest_handlers = collect_handlers(@prerequest_behaviors, request.class, base_class)
      postrequest_handlers = collect_handlers(@postrequest_behaviors, request.class, base_class)
      run_request_pipeline(request, prerequest_handlers, request_handler, postrequest_handlers)
    end

    def publish(notification)
      raise ArgumentError, "notification cannot be nil" if notification.nil?

      handler_classes = collect_handlers(@notification_handlers, notification.class, Mediate::Notification)
      handler_classes.each do |handler_class|
        handler_class.new.handle(notification)
      rescue StandardError => e
        handle_exception(e)
        # Don't break from loop, since we don't want a single notification handler to prevent others from
        # receiving notification.
      end
    end

    def register_request_handler(handler_class, request_class)
      validate_base_class(handler_class, Mediate::RequestHandler)
      validate_base_class(request_class, Mediate::Request)

      @request_handlers[request_class] = handler_class
    end

    def register_notification_handler(handler_class, notif_class)
      validate_base_class(handler_class, Mediate::NotificationHandler)
      validate_base_class(notif_class, Mediate::Notification, allow_base: true)

      append_to_hash_value(@notification_handlers, notif_class, handler_class)
    end

    def register_prerequest_behavior(behavior_class, request_class)
      validate_base_class(behavior_class, Mediate::PrerequestBehavior)
      validate_base_class(request_class, Mediate::Request, allow_base: true)

      append_to_hash_value(@prerequest_behaviors, request_class, behavior_class)
    end

    def register_postrequest_behavior(behavior_class, request_class)
      validate_base_class(behavior_class, Mediate::PostrequestBehavior)
      validate_base_class(request_class, Mediate::Request, allow_base: true)

      append_to_hash_value(@postrequest_behaviors, request_class, behavior_class)
    end

    def register_error_handler(handler_class, exception_class)
      validate_base_class(handler_class, Mediate::ErrorHandler)
      validate_base_class(exception_class, StandardError, allow_base: true)

      append_to_hash_value(@exception_handlers, exception_class, handler_class)
    end

    private

    def run_request_pipeline(request, pre_handlers, request_handler, post_handlers)
      result = nil
      pre_handlers.each { |handler_class| handler_class.new.handle(request) }
      result = request_handler.new.handle(request)
      post_handlers.each { |handler_class| handler_class.new.handle(request, result) }
      result
    rescue StandardError => e
      handle_exception(e)
      result
    end

    def append_to_hash_value(hash, key, value)
      hash[key] = hash.fetch(key, []) << value
    end

    def validate_base_class(given, expected_base, allow_base: false)
      raise ArgumentError, "class cannot be nil" if given.nil? || expected_base.nil?

      return if allow_base && given == expected_base

      raise ArgumentError, "#{given} does not inherit from #{expected_base}" unless given < expected_base
    end

    def handle_exception(exception)
      handler_classes = collect_handlers(@exception_handlers, exception.class, StandardError)
      handler_classes.each { |handler_class| handler_class.new.handle(exception) }
    end

    def resolve_handler(handlers_hash, request_class, base_class)
      value = handlers_hash[request_class]
      return value unless value.nil?
      return NullHandler if request_class >= base_class

      resolve_class_key(handlers_hash, request_class.superclass, base_class)
    end

    def collect_handlers(handlers_hash, request_class, base_class, collected = [])
      handlers = handlers_hash.fetch(request_class, [])
      updated_handlers = (collected || []) + handlers

      return updated_handlers if request_class > base_class

      collect_handlers(handlers_hash, request_class.superclass, base_class, updated_handlers)
    end

    class NullHandler; end
  end
end
