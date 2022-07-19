# frozen_string_literal: true

module Mediate
  #
  # @abstract override {#handle} to implement.
  #
  # Abstract base class of a handler of notifications.
  #
  class NotificationHandler
    #
    # Registers this handler for the given notification Class.
    #   The notification Class must have Mediate::Notification as a superclass.
    #
    # @param [Class] notif_class the Class of the notifications that get passed to this handler
    # @param [Mediate::Mediator] mediator the mediator instance to register the handler with
    #
    # @raise [ArgumentError] if notif_class does not inherit from Mediate::Notification
    #
    # @return [void]
    #
    def self.handles(notif_class = Mediate::Notification, mediator = Mediate.mediator)
      mediator.register_notification_handler(self, notif_class)
    end

    #
    # The method to implement that handles the notifications registered for this handler.
    #
    # @abstract
    #
    # @param [Mediate::Notification] _notification
    #
    # @return [void]
    #
    def handle(_notification)
      raise NoMethodError, "handle must be implemented"
    end
  end
end
