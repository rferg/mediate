# frozen_string_literal: true

module Mediate
  #
  # @abstract override {#handle} to implement
  #
  # Abstract base class of a pipeline behavior that processes a request after the RequestHandler finishes.
  #
  class PostrequestBehavior
    #
    # Registers this behavior to handle requests of the given type.
    #
    # @param [Class] request_class the type of requests to handle (should inherit from Mediate::Request)
    # @param [Mediate::Mediator] mediator the Mediator instance to register to
    #
    # @return [void]
    #
    # @raise [ArgumentError] if request_class does not inherit from Mediate::Request
    #
    def self.handles(request_class = Mediate::Request, mediator = Mediate.mediator)
      mediator.register_postrequest_behavior(self, request_class)
    end

    #
    # @abstract
    #
    # The method that handles the request and the result that the handler returned.
    #
    # @param [Mediate::Request] _request
    # @param _result what was returned by the RequestHandler
    #
    # @return [void]
    #
    def handle(_request, _result)
      raise NoMethodError, "handle must be implemented"
    end
  end
end
