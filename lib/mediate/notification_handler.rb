# frozen_string_literal: true

module Mediate
  class NotificationHandler
    def self.handles(notif_class = Mediate::Notification, mediator = Mediate.mediator)
      mediator.register_notification_handler(self, notif_class)
    end

    def handle(_notification)
      raise NoMethodError, "handle must be implemented"
    end
  end
end
