# frozen_string_literal: true

module Mediate
  #
  # @abstract override {#handle} to implement.
  #
  # Abstract base class of a handler of requests.  Each request type should have only one
  # handler.
  #
  class RequestHandler
    #
    # Registers this handler for the given request Class.
    #   The request Class must have Mediate::Request as a superclass.
    #
    # @param [Class] request_class the Class of the requests that get passed to this handler
    # @param [Mediate::Mediator] mediator the mediator instance to register the handler with
    #
    # @raise [ArgumentError] if request_class does not inherit from Mediate::Request
    #
    # @return [void]
    #
    def self.handles(request_class, mediator = Mediate.mediator)
      mediator.register_request_handler(self, request_class)
    end

    #
    # The method to implement that handles the request of the type registered
    # for this handler. Whatever this method returns will be returned to the sender of the request.
    #
    # @abstract
    #
    # @param [Mediate::Request] _request
    #
    # @return the result of handling the request
    #
    def handle(_request)
      raise NoMethodError, "handle must be implemented"
    end
  end
end
