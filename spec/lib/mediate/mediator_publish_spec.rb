# frozen_string_literal: true

RSpec.describe Mediate::Mediator do
  let(:mediator) { Class.new(Mediate::Mediator).instance }

  describe "#publish" do
    it "raises ArgumentError if given nil" do
      expect { mediator.publish(nil) }.to raise_error(ArgumentError, "notification cannot be nil")
    end

    it "does not raise if no handlers registered for notificiation" do
      notification = Stubs::Recording::Notif.new
      mediator.publish(notification)
      expect(notification.classes).to be_empty
      expect(notification.exceptions).to be_empty
    end

    it "passes notification to all and only handlers registered for that notification type or its superclasses" do
      notification = Stubs::Recording::DerivedNotif.new
      expected = [Stubs::Recording::DerivedNotifHandler, Stubs::Recording::NotifHandler,
                  Stubs::Recording::AnotherNotifHandler]
      mediator.register_notification_handler(Stubs::Recording::NotifHandler, notification.class.superclass)
      mediator.register_notification_handler(Stubs::Recording::DerivedNotifHandler, notification.class)
      mediator.register_notification_handler(Stubs::Recording::AnotherNotifHandler, Mediate::Notification)
      mediator.register_notification_handler(Stubs::Recording::OtherNotifHandler, Stubs::Recording::OtherNotif)
      mediator.publish(notification)
      expect(notification.classes).to match_array(expected)
    end

    it "uses all and only handlers registered in multiple threads for that notification type or its superclasses" do
      notif_class = Stubs::Recording::DerivedNotif
      expected = [Stubs::Recording::DerivedNotifHandler, Stubs::Recording::NotifHandler,
                  Stubs::Recording::AnotherNotifHandler]
      threads = []
      threads << Thread.new do
        mediator.register_notification_handler(Stubs::Recording::NotifHandler, notif_class.superclass)
      end
      threads << Thread.new do
        mediator.register_notification_handler(Stubs::Recording::DerivedNotifHandler, notif_class)
      end
      threads << Thread.new do
        mediator.register_notification_handler(Stubs::Recording::AnotherNotifHandler, Mediate::Notification)
      end
      threads << Thread.new do
        mediator.register_notification_handler(Stubs::Recording::OtherNotifHandler, Stubs::Recording::OtherNotif)
      end
      threads.map(&:join)
      5.times.map do
        Thread.new do
          notification = notif_class.new
          mediator.publish(notification)
          expect(notification.classes).to match_array(expected)
        end
      end.map(&:join)
    end

    it "calls handler only once if it was registered multiple times" do
      notification = Stubs::Recording::Notif.new
      expected = [Stubs::Recording::NotifHandler]
      3.times do
        mediator.register_notification_handler(Stubs::Recording::NotifHandler, notification.class)
      end
      mediator.publish(notification)
      expect(notification.classes).to match_array(expected)
    end

    it "calls handler only once if it was registered for different applicable Notification types" do
      notification = Stubs::Recording::Notif.new
      expected = [Stubs::Recording::NotifHandler]
      mediator.register_notification_handler(Stubs::Recording::NotifHandler, notification.class)
      mediator.register_notification_handler(Stubs::Recording::NotifHandler, notification.class.superclass)
      mediator.publish(notification)
      expect(notification.classes).to match_array(expected)
    end

    it "calls all handlers (and any applicable error handlers) if one raises" do
      notification = Stubs::Recording::Notif.new
      expected = [Stubs::Recording::NotifHandler, Stubs::Recording::RaiseNotifHandler,
                  Stubs::Recording::ErrorOneHandler, Stubs::Recording::OtherNotifHandler]
      mediator.register_error_handler(Stubs::Recording::ErrorOneHandler, StandardError, notification.class)
      mediator.register_notification_handler(Stubs::Recording::NotifHandler, notification.class)
      mediator.register_notification_handler(Stubs::Recording::RaiseNotifHandler, notification.class.superclass)
      mediator.register_notification_handler(Stubs::Recording::OtherNotifHandler, Mediate::Notification)
      mediator.publish(notification)
      expect(notification.classes).to match_array(expected)
      expect(notification.exceptions.length).to be(1)
      expect(notification.exceptions[0].message).to match(/#{Stubs::Recording::RaiseNotifHandler}/)
    end

    it "calls all handlers (and any applicable error handlers) if multiple raise" do
      notification = Stubs::Recording::Notif.new
      expected = [Stubs::Recording::NotifHandler, Stubs::Recording::RaiseNotifHandler,
                  Stubs::Recording::ErrorOneHandler, Stubs::Recording::OtherRaiseNotifHandler,
                  Stubs::Recording::ErrorOneHandler]
      mediator.register_error_handler(Stubs::Recording::ErrorOneHandler, StandardError, notification.class)
      mediator.register_notification_handler(Stubs::Recording::NotifHandler, notification.class)
      mediator.register_notification_handler(Stubs::Recording::RaiseNotifHandler, notification.class.superclass)
      mediator.register_notification_handler(Stubs::Recording::OtherRaiseNotifHandler, Mediate::Notification)
      mediator.publish(notification)
      expect(notification.classes).to match_array(expected)
      expect(notification.exceptions.length).to be(2)
      expect(notification.exceptions[0].message).to match(/#{Stubs::Recording::RaiseNotifHandler}/)
      expect(notification.exceptions[1].message).to match(/#{Stubs::Recording::OtherRaiseNotifHandler}/)
    end
  end
end
