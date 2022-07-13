# frozen_string_literal: true

require "spec_helper"

module Stubs
  class Request < Mediate::Request; end

  class RequestHandler < Mediate::RequestHandler
    def handle(request); end
  end

  class Prerequest < Mediate::PrerequestBehavior
    def handle(request); end
  end

  class Postrequest < Mediate::PostrequestBehavior
    def handle(request, response); end
  end

  class Notif < Mediate::Notification; end

  class NotifHandler < Mediate::NotificationHandler
    def handle(notif); end
  end

  class ErrorHandler < Mediate::ErrorHandler
    def handle(error); end
  end
end

RSpec.describe Mediate::Mediator do
  let(:mediator) { Class.new(Mediate::Mediator).instance }

  describe "#register_request_handler" do
    it "raises ArgumentError if handler class does not inherit from Mediate::RequestHandler" do
      bad_classes = [Array, Numeric, Mediate::RequestHandler, Mediate::NotificationHandler, nil]
      bad_classes.each do |bad_class|
        expect { mediator.register_request_handler(bad_class, Stubs::Request) }
          .to raise_error(ArgumentError, /#{bad_class}/)
      end
    end

    it "raises ArgumentError if request class does not inherit from Mediate::Request" do
      bad_classes = [Array, Numeric, Mediate::Request, nil]
      bad_classes.each do |bad_class|
        expect { mediator.register_request_handler(Stubs::RequestHandler, bad_class) }
          .to raise_error(ArgumentError, /#{bad_class}/)
      end
    end
  end

  describe "#register_notification_handler" do
    it "raises ArgumentError if handler class does not inherit from Mediate::NotificationHandler" do
      bad_classes = [Array, Numeric, Mediate::NotificationHandler, Mediate::RequestHandler, nil]
      bad_classes.each do |bad_class|
        expect { mediator.register_notification_handler(bad_class, Stubs::Notif) }
          .to raise_error(ArgumentError, /#{bad_class}/)
      end
    end

    it "raises ArgumentError if notification class does not inherit from Mediate::Notification" do
      bad_classes = [Array, Numeric, Mediate::Notification, nil]
      bad_classes.each do |bad_class|
        expect { mediator.register_notification_handler(Stubs::NotifHandler, bad_class) }
          .to raise_error(ArgumentError, /#{bad_class}/)
      end
    end
  end

  describe "#register_prerequest_handler" do
    it "raises ArgumentError if handler class does not inherit from Mediate::PrerequestBehavior" do
      bad_classes = [Array, Numeric, Mediate::PrerequestBehavior, Mediate::PostrequestBehavior, nil]
      bad_classes.each do |bad_class|
        expect { mediator.register_prerequest_behavior(bad_class) }.to raise_error(ArgumentError, /#{bad_class}/)
      end
    end

    it "raises ArgumentError if request class does not inherit from Mediate::Request" do
      bad_classes = [Array, Numeric, Mediate::Request]
      bad_classes.each do |bad_class|
        expect { mediator.register_prerequest_behavior(Stubs::Prerequest, bad_class) }
          .to raise_error(ArgumentError, /#{bad_class}/)
      end
    end
  end

  describe "#register_postrequest_handler" do
    it "raises ArgumentError if handler class does not inherit from Mediate::PostrequestBehavior" do
      bad_classes = [Array, Numeric, Mediate::PrerequestBehavior, Mediate::PostrequestBehavior, nil]
      bad_classes.each do |bad_class|
        expect { mediator.register_postrequest_behavior(bad_class) }.to raise_error(ArgumentError, /#{bad_class}/)
      end
    end

    it "raises ArgumentError if request class does not inherit from Mediate::Request" do
      bad_classes = [Array, Numeric, Mediate::Request]
      bad_classes.each do |bad_class|
        expect { mediator.register_postrequest_behavior(Stubs::Postrequest, bad_class) }
          .to raise_error(ArgumentError, /#{bad_class}/)
      end
    end
  end

  describe "#register_error_handler" do
    it "raises ArgumentError if handler class does not inherit from Mediate::ErrorHandler" do
      bad_classes = [Array, Numeric, Mediate::PrerequestBehavior, Mediate::ErrorHandler, nil]
      bad_classes.each do |bad_class|
        expect { mediator.register_error_handler(bad_class) }.to raise_error(ArgumentError, /#{bad_class}/)
      end
    end

    it "raises ArgumentError if given exception class does not inherit from StandardError" do
      bad_classes = [Array, Numeric, Mediate::Request, Exception]
      bad_classes.each do |bad_class|
        expect { mediator.register_error_handler(Stubs::ErrorHandler, bad_class) }
          .to raise_error(ArgumentError, /#{bad_class}/)
      end
    end
  end
end
