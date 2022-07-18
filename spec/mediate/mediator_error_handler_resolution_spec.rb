# frozen_string_literal: true

require "spec_helper"
require_relative "../stubs/basic"
require_relative "../stubs/recording"

module ErrorResolutionSpec
  class SuperTestError < StandardError; end
  class TestError < SuperTestError; end

  class RequestHandler < Stubs::Recording::RequestHandler
    def handle(request)
      super(request)
      raise TestError, "from:#{self}"
    end
  end

  class NotifHandler < Stubs::Recording::NotifHandler
    def handle(notif)
      super(notif)
      raise TestError, "from:#{self}"
    end
  end
end

RSpec.describe Mediate::Mediator do
  let(:mediator) { Class.new(Mediate::Mediator).instance }

  def register_error_handler(error, sendable, expected_handlers)
    handler = Stubs::Recording::ErrorOneHandler
    mediator.register_error_handler(handler, error, sendable)
    expected_handlers << handler
  end

  context "when error raised" do
    describe "#dispatch" do
      let(:expected) { [ErrorResolutionSpec::RequestHandler] }

      def call_and_assert
        request = Stubs::Recording::DerivedRequest.new
        mediator.dispatch(request)
        expect(request.classes).to match_array(expected)
      end

      before do
        mediator.register_request_handler(expected[0], Stubs::Recording::DerivedRequest)
      end

      it "uses error handler registered for any error and any Request" do
        register_error_handler(StandardError, Mediate::Request, expected)
        call_and_assert
      end

      it "uses error handler registered for specific error and any Request" do
        register_error_handler(ErrorResolutionSpec::TestError, Mediate::Request, expected)
        call_and_assert
      end

      it "uses error handler registered for base class of raised error and any Request" do
        register_error_handler(ErrorResolutionSpec::SuperTestError, Mediate::Request, expected)
        call_and_assert
      end

      it "uses error handler registered for any error and specific Request" do
        register_error_handler(StandardError, Stubs::Recording::DerivedRequest, expected)
        call_and_assert
      end

      it "uses error handler registered for any error and base class of registered Request" do
        register_error_handler(StandardError, Stubs::Recording::Request, expected)
        call_and_assert
      end

      it "uses error handler registered for specific error and specific Request" do
        register_error_handler(ErrorResolutionSpec::TestError, Stubs::Recording::DerivedRequest, expected)
        call_and_assert
      end

      it "uses error handler registered for specific error and base class of registered Request" do
        register_error_handler(ErrorResolutionSpec::TestError, Stubs::Recording::Request, expected)
        call_and_assert
      end

      it "uses error handler registered for base class of registered error and specific Request" do
        register_error_handler(ErrorResolutionSpec::SuperTestError, Stubs::Recording::DerivedRequest, expected)
        call_and_assert
      end

      it "uses error handler registered for base class of registered error and base class of registered Request" do
        register_error_handler(ErrorResolutionSpec::SuperTestError, Stubs::Recording::Request, expected)
        call_and_assert
      end
    end

    describe "#publish" do
      let(:expected) { [ErrorResolutionSpec::NotifHandler] }

      def call_and_assert
        notif = Stubs::Recording::DerivedNotif.new
        mediator.publish(notif)
        expect(notif.classes).to match_array(expected)
      end

      before do
        mediator.register_notification_handler(expected[0], Mediate::Notification)
      end

      it "uses error handler registered for any error and any Notification" do
        register_error_handler(StandardError, Mediate::Notification, expected)
        call_and_assert
      end

      it "uses error handler registered for specific error and any Notification" do
        register_error_handler(ErrorResolutionSpec::TestError, Mediate::Notification, expected)
        call_and_assert
      end

      it "uses error handler registered for base class of raised error and any Notification" do
        register_error_handler(ErrorResolutionSpec::SuperTestError, Mediate::Notification, expected)
        call_and_assert
      end

      it "uses error handler registered for any error and specific Notification" do
        register_error_handler(StandardError, Stubs::Recording::DerivedNotif, expected)
        call_and_assert
      end

      it "uses error handler registered for any error and base class of registered Notification" do
        register_error_handler(StandardError, Stubs::Recording::Notif, expected)
        call_and_assert
      end

      it "uses error handler registered for specific error and specific Notification" do
        register_error_handler(ErrorResolutionSpec::TestError, Stubs::Recording::DerivedNotif, expected)
        call_and_assert
      end

      it "uses error handler registered for specific error and base class of registered Notificationuest" do
        register_error_handler(ErrorResolutionSpec::TestError, Stubs::Recording::Notif, expected)
        call_and_assert
      end

      it "uses error handler registered for base class of registered error and specific Notification" do
        register_error_handler(ErrorResolutionSpec::SuperTestError, Stubs::Recording::DerivedNotif, expected)
        call_and_assert
      end

      it "uses error handler registered for base class of registered error and base class of registered Notification" do
        register_error_handler(ErrorResolutionSpec::SuperTestError, Stubs::Recording::Notif, expected)
        call_and_assert
      end
    end
  end
end
