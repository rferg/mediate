# frozen_string_literal: true

module Mediate
  class RequestHandler
    def self.handles(request_class, mediator = Mediate.mediator)
      mediator.register_request_handler(self, request_class)
    end

    def handle(_request)
      raise NoMethodError, "handle must be implemented"
    end
  end
end
