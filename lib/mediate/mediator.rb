# frozen_string_literal: true

require "set"
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
    REQUEST_BASE = Mediate::Request
    NOTIF_BASE = Mediate::Notification

    def initialize
      @request_handlers = {}
      @notification_handlers = {}
      @prerequest_behaviors = {}
      @postrequest_behaviors = {}
      @exception_handlers = {}
    end

    def dispatch(request)
      raise ArgumentError, "request cannot be nil" if request.nil?

      request_handler = resolve_handler(@request_handlers, request.class, REQUEST_BASE)
      raise Errors::NoHandlerError, request.class if request_handler == NullHandler

      prerequest_handlers = collect_by_inheritance(@prerequest_behaviors, request.class, REQUEST_BASE)
      postrequest_handlers = collect_by_inheritance(@postrequest_behaviors, request.class, REQUEST_BASE)
      run_request_pipeline(request, prerequest_handlers, request_handler, postrequest_handlers)
    end

    def publish(notification)
      raise ArgumentError, "notification cannot be nil" if notification.nil?

      handler_classes = collect_by_inheritance(@notification_handlers, notification.class, NOTIF_BASE)
      handler_classes.each do |handler_class|
        handler_class.new.handle(notification)
      rescue StandardError => e
        handle_exception(notification, e, NOTIF_BASE)
        # Don't break from loop, since we don't want a single notification handler to prevent others from
        # receiving notification.
      end
    end

    def register_request_handler(handler_class, request_class)
      validate_base_class(handler_class, Mediate::RequestHandler)
      validate_base_class(request_class, REQUEST_BASE)
      @request_handlers[request_class] = handler_class
    end

    def register_notification_handler(handler_class, notif_class)
      validate_base_class(handler_class, Mediate::NotificationHandler)
      validate_base_class(notif_class, NOTIF_BASE, allow_base: true)
      append_to_hash_value(@notification_handlers, notif_class, handler_class)
    end

    def register_prerequest_behavior(behavior_class, request_class)
      validate_base_class(behavior_class, Mediate::PrerequestBehavior)
      validate_base_class(request_class, REQUEST_BASE, allow_base: true)
      append_to_hash_value(@prerequest_behaviors, request_class, behavior_class)
    end

    def register_postrequest_behavior(behavior_class, request_class)
      validate_base_class(behavior_class, Mediate::PostrequestBehavior)
      validate_base_class(request_class, REQUEST_BASE, allow_base: true)
      append_to_hash_value(@postrequest_behaviors, request_class, behavior_class)
    end

    def register_error_handler(handler_class, exception_class, dispatch_class)
      if dispatch_class <= NOTIF_BASE
        register_error_handler_for_dispatch(handler_class, exception_class, dispatch_class, NOTIF_BASE)
      else
        register_error_handler_for_dispatch(handler_class, exception_class, dispatch_class, REQUEST_BASE)
      end
    end

    private

    def register_error_handler_for_dispatch(handler_class, exception_class, dispatch_class, dispatch_base_class)
      validate_base_class(handler_class, Mediate::ErrorHandler)
      validate_base_class(exception_class, StandardError, allow_base: true)
      validate_base_class(dispatch_class, dispatch_base_class, allow_base: true)
      @exception_handlers[exception_class] = {} unless @exception_handlers.key?(exception_class)
      append_to_hash_value(@exception_handlers[exception_class], dispatch_class, handler_class)
    end

    def run_request_pipeline(request, pre_handlers, request_handler, post_handlers)
      result = nil
      pre_handlers.each { |handler_class| handler_class.new.handle(request) }
      result = request_handler.new.handle(request)
      post_handlers.each { |handler_class| handler_class.new.handle(request, result) }
      result
    rescue StandardError => e
      handle_exception(request, e, REQUEST_BASE)
      result
    end

    def append_to_hash_value(hash, key, value)
      hash[key] = hash.fetch(key, Set.new) << value
    end

    def validate_base_class(given, expected_base, allow_base: false)
      raise ArgumentError, "class cannot be nil" if given.nil? || expected_base.nil?

      return if allow_base && given == expected_base

      raise ArgumentError, "#{given} does not inherit from #{expected_base}" unless given < expected_base
    end

    def handle_exception(dispatched, exception, dispatch_base_class)
      exception_to_dispatched_maps = collect_by_inheritance(@exception_handlers, exception.class, StandardError)
      handler_classes = exception_to_dispatched_maps.reduce(Set.new) do |memo, curr|
        collect_by_inheritance(curr, dispatched.class, dispatch_base_class, memo)
      end
      handler_classes.each { |handler_class| handler_class.new.handle(dispatched, exception) }
    end

    def resolve_handler(handlers_hash, request_class, base_class)
      value = handlers_hash[request_class]
      return value unless value.nil?
      return NullHandler if request_class >= base_class

      resolve_handler(handlers_hash, request_class.superclass, base_class)
    end

    def collect_by_inheritance(hash, key_class, base_class, collected = Set.new)
      values = hash.fetch(key_class, Set.new)
      # Wrap values in Set and flatten to account for case when values is not a Set itself.
      # This may break if values is nested Sets, although we don't have that case yet.
      new_collected = (collected || Set.new) | Set[values].flatten
      return new_collected if key_class > base_class

      collect_by_inheritance(hash, key_class.superclass, base_class, new_collected)
    end

    class NullHandler; end
  end
end
