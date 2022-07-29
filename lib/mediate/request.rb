# frozen_string_literal: true

module Mediate
  #
  # The base class of a request that can be dispatched to the mediator, which
  # returns a response from its handler.
  #
  class Request
    IMPLICIT_HANDLER_CLASS_NAME = "Handler"

    #
    # Registers a handler for this Request type using the given block as the handle method.
    #
    # @param [Mediate::Mediator] mediator the instance to register the handler on
    # @param [Proc] &proc the block that will handle the request
    #
    # @raises [ArgumentError] if no block is given
    #
    # @example When a request of this type is dispatched, the handle_with block will run
    #   class MyRequest < Mediate::Request
    #     handle_with do |request|
    #       ## do something with request...
    #     end
    #   end
    def self.handle_with(mediator = Mediator.mediator, &proc)
      raise ArgumentError, "expected block to be passed to #handle_with." unless proc

      if implicit_handler_defined?
        raise "#{name}::#{IMPLICIT_HANDLER_CLASS_NAME} is already defined. Cannot create implicit handler."
      end

      handler_class = define_handler(proc)
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

    def self.define_handler(proc)
      Class.new(RequestHandler) do
        @@handle_proc = proc # rubocop:disable Style/ClassVars
        def handle(request)
          @@handle_proc.call(request)
        end
      end
    end

    def self.implicit_handler_defined?
      const_defined?(IMPLICIT_HANDLER_CLASS_NAME)
    end

    private_constant :IMPLICIT_HANDLER_CLASS_NAME
    private_class_method :define_handler, :implicit_handler_defined?
  end
end
