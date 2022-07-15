# frozen_string_literal: true

module Mediate
  class ErrorHandler
    def self.handles(exception_class = StandardError, dispatchable_class = Mediate::Request)
      Mediate.mediator.register_error_handler(self, exception_class, dispatchable_class)
    end

    def handle(_dispatched, _exception)
      raise NoMethodError, "handle must be implemented"
    end
  end
end
