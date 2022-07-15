# frozen_string_literal: true

module Mediate
  module Errors
    class NoHandlerError < StandardError
      def initialize(request_class)
        super("No handler for #{request_class}. Call handles(#{request_class}) on a RequestHandler to register.")
      end
    end
  end
end
