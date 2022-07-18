# frozen_string_literal: true

require_relative "../stubs/basic"

RSpec.describe Mediate::RequestHandler do
  describe "#handles" do
    it "calls register_request_handler on Mediator" do
      mediator = instance_double("Mediate::Mediator")
      request_class = Stubs::Request
      expect(mediator).to receive(:register_request_handler).with(Mediate::RequestHandler, request_class)
      Mediate::RequestHandler.handles(request_class, mediator)
    end
  end

  describe "#handle" do
    it "raises NoMethodError" do
      expect { Mediate::RequestHandler.handle(nil) }.to raise_error(NoMethodError)
    end
  end
end
