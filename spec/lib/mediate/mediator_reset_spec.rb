# frozen_string_literal: true

RSpec.describe Mediate::Mediator do
  let(:mediator) { Class.new(Mediate::Mediator).instance }

  describe "#reset" do
    it "removes any request handlers" do
      mediator.register_request_handler(Stubs::RequestHandler, Stubs::Request)
      mediator.reset
      expect { mediator.dispatch(Stubs::Request.new) }.to raise_error(Mediate::Errors::NoHandlerError)
    end

    it "removes any notification handlers" do
      mediator.register_notification_handler(Stubs::Recording::NotifHandler, Stubs::Recording::Notif)
      mediator.reset
      notification = Stubs::Recording::Notif.new
      mediator.publish(notification)
      expect(notification.classes).to be_empty
    end
  end
end
