# frozen_string_literal: true

module Mediate
  #
  # Namespace that contains custom Mediate errors.
  #
  module Errors
    #
    # Indicates that a Mediate::RequestHandler was already registered for the given request_class.
    #
    class RequestHandlerAlreadyExistsError < StandardError
      def initialize(request_class, registered_handler_class, attempted_handler_class)
        super("Attempted to register #{attempted_handler_class} to handle #{request_class},\
          but #{registered_handler_class} is already registered to handle #{request_class}.\
          This is probably a mistake, as only one handler should be registered per request type.")
      end
    end
  end
end
