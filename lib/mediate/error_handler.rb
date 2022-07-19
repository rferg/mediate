# frozen_string_literal: true

module Mediate
  #
  # @abstract override {#handle} to implement.
  #
  # An abstract base class that handles exceptions raised by request handlers, behaviors, or notification handlers.
  #
  class ErrorHandler
    #
    # Registers this to handle exceptions of type exception_class when raised while handling requests or notifications
    #   of type dispatched_class.
    #
    # @param [StandardError] exception_class the type of exceptions that this should handle
    # @param [Class] dispatched_class the request or notification type
    #  (should inherit from Mediate::Request or Mediate::Notification)
    # @param [Mediate::Mediator] mediator the Mediator instance to register on
    #
    # @return [void]
    #
    # @raise [ArgumentError] if exception_class is not a StandardError
    #   or dispatched_class is not a Request or Notification
    def self.handles(exception_class = StandardError, dispatched_class = Mediate::Request, mediator = Mediate.mediator)
      mediator.register_error_handler(self, exception_class, dispatched_class)
    end

    #
    # The method to implement to handle exceptions.
    #
    # @abstract
    #
    # @param [Mediate::Request, Mediate::Notification] _dispatched the request or notification that was been handled
    # @param [StandardError] _exception the exception that was raised
    #
    # @return [void]
    #
    def handle(_dispatched, _exception)
      raise NoMethodError, "handle must be implemented"
    end
  end
end
