# frozen_string_literal: true

module Mediate
  #
  # Namespace that contains custom Mediate errors.
  #
  module Errors
    #
    # Indicates that a Mediate::Request was sent to the Mediator, but no Mediate::RequestHandler
    #   was registered to handle it.
    #
    class NoHandlerError < StandardError
      def initialize(request_class)
        super("No handler for #{request_class}. Call handles(#{request_class}) on a RequestHandler to register.")
      end
    end
  end
end
