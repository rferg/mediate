# frozen_string_literal: true

module Mediate
  class PostrequestBehavior
    def self.handles(request_class)
      Mediate.mediator.register_postrequest_behavior(self, request_class)
    end

    def handle(_request, _result)
      raise NoMethodError, "handle must be implemented"
    end
  end
end
