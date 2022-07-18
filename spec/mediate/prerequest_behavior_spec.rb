# frozen_string_literal

require_relative "../stubs/basic"

RSpec.describe Mediate::PrerequestBehavior do
  describe "#handles" do
    it "should call register_prerequest_behavior on Mediator" do
      mediator = instance_double("Mediate::Mediator")
      request_class = Stubs::Request
      expect(mediator).to receive(:register_prerequest_behavior).with(Mediate::PrerequestBehavior, request_class)
      Mediate::PrerequestBehavior.handles(request_class, mediator)
    end
  end

  describe "#handle" do
    it "raises NoMethodError" do
      expect { Mediate::PrerequestBehavior.handle(nil) }.to raise_error(NoMethodError)
    end
  end
end
