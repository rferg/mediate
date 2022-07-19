# frozen_string_literal: true

module Mediate
  #
  # @abstract override {#handle} to implement
  #
  # Abstract base class of a pipeline behavior that processes a request before it's given to the handler.
  #
  class PrerequestBehavior
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
      mediator.register_prerequest_behavior(self, request_class)
    end

    #
    # @abstract
    #
    # The method that handles the request.
    #
    # @param [Mediate::Request] _request
    #
    # @return [void]
    #
    def handle(_request)
      raise NoMethodError, "handle must be implemented"
    end
  end
end
