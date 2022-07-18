# frozen_string_literal: true

RSpec.describe Mediate::PostrequestBehavior do
  describe "#handles" do
    it "calls register_postrequest_behavior on Mediator" do
      mediator = instance_double("Mediate::Mediator")
      request_class = Stubs::Request
      expect(mediator).to receive(:register_postrequest_behavior).with(Mediate::PostrequestBehavior, request_class)
      Mediate::PostrequestBehavior.handles(request_class, mediator)
    end
  end

  describe "#handle" do
    it "raises NoMethodError" do
      expect { Mediate::PostrequestBehavior.handle(nil) }.to raise_error(NoMethodError)
    end
  end
end
