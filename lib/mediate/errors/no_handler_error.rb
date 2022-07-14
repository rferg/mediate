# frozen_string_literal: true

module Mediate
  module Errors
    class NoHandlerError < StandardError
      def initialize(request_class)
        super("Did not find handler for #{request_class}. Did you forget to register one?")
      end
    end
  end
end
