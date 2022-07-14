# frozen_string_literal: true

module Mediate
  class PrerequestBehavior
    def self.handles(request_class = Mediate::Request, mediator = Mediate.mediator)
      mediator.register_prerequest_behavior(self, request_class)
    end

    def handle(_request)
      raise NoMethodError, "handle must be implemented"
    end
  end
end
