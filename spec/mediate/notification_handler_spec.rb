# frozen_string_literal: true

require_relative "../stubs/basic"

RSpec.describe Mediate::NotificationHandler do
  describe "#handles" do
    it "calls register_notification_handler on Mediator" do
      mediator = instance_double("Mediate::Mediator")
      notif_class = Stubs::Notif
      expect(mediator).to receive(:register_notification_handler).with(Mediate::NotificationHandler, notif_class)
      Mediate::NotificationHandler.handles(notif_class, mediator)
    end
  end

  describe "#handle" do
    it "raises NoMethodError" do
      expect { Mediate::NotificationHandler.handle(nil) }.to raise_error(NoMethodError)
    end
  end
end
