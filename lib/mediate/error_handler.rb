# frozen_string_literal: true

module Mediate
  class ErrorHandler
    def self.handles(exception_class = StandardError)
      Mediate.mediator.register_error_handler(self, exception_class)
    end

    def handle(_exception)
      raise NoMethodError, "handle must be implemented"
    end
  end
end
