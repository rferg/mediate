# frozen_string_literal: true

module Mediate
  #
  # The base class of a request that can be dispatched to the mediator, which
  # returns a response from its handler.
  #
  class Request
    IMPLICIT_HANDLER_CLASS_NAME = "Handler"

    #
    # Registers a handler for this Request type using the given lambda as the handle method.
    #
    # @param [Lambda] lmbda the block that will handle the request
    # @param [Mediate::Mediator] mediator the instance to register the handler on
    #
    # @raises [ArgumentError] if no lambda is given
    # @raises [RequestHandlerAlreadyExistsError] if handler already defined for this class
    #
    # @example When a request of this type is dispatched, the handle_with lambda will run
    #   class MyRequest < Mediate::Request
    #     handle_with lambda do |request|
    #       ## do something with request...
    #     end
    #   end
    def self.handle_with(lmbda, mediator = Mediate.mediator)
      raise ArgumentError, "expected lambda to be passed to #handle_with." if lmbda.nil?

      handler_class = define_handler(lmbda)
      undefine_implicit_handler # remove any previous definition (this will do nothing if it doesn't exist)
      const_set(IMPLICIT_HANDLER_CLASS_NAME, handler_class)
      mediator.register_request_handler(handler_class, self)
    end

    #
    # If an implicit handler is defined for this Request using the #handle_with method,
    # this will return an instance of it. Use this for testing the handler.
    #
    # @return [Mediate::RequestHandler] the implicit handler class for this Request
    #
    # @raise [RuntimeError] if no implicit handler is defined
    #
    # @example Create an instance and call #handle on it to test it
    #   handler = MyRequest.create_implicit_handler
    #   result = handler.handle(MyRequest.new)
    def self.create_implicit_handler
      raise "Implicit handler is not defined." unless implicit_handler_defined?

      const_get(IMPLICIT_HANDLER_CLASS_NAME).new
    end

    def self.undefine_implicit_handler
      return unless implicit_handler_defined?

      remove_const(IMPLICIT_HANDLER_CLASS_NAME)
    end

    def self.define_handler(lmbda)
      Class.new(RequestHandler) do
        define_method(:handle, lmbda)
      end
    end

    def self.implicit_handler_defined?
      const_defined?(IMPLICIT_HANDLER_CLASS_NAME, false) # do not check ancestors
    end

    private_constant :IMPLICIT_HANDLER_CLASS_NAME
    private_class_method :define_handler, :implicit_handler_defined?
  end
end
