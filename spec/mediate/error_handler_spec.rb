# frozen_string_literal

require_relative "../stubs/basic"

RSpec.describe Mediate::ErrorHandler do
  describe "#handles" do
    it "should call register_error_handler on Mediator" do
      mediator = instance_double("Mediate::Mediator")
      request_class = Stubs::Request
      error_class = NoMemoryError
      expect(mediator).to receive(:register_error_handler).with(Mediate::ErrorHandler, error_class, request_class)
      Mediate::ErrorHandler.handles(error_class, request_class, mediator)
    end
  end

  describe "#handle" do
    it "raises NoMethodError" do
      expect { Mediate::ErrorHandler.handle(nil, nil) }.to raise_error(NoMethodError)
    end
  end
end
