# frozen_string_literal: true

RSpec.describe Mediate do
  it "has a version number" do
    expect(Mediate::VERSION).not_to be nil
  end

  describe "#mediator" do
    it "returns mediator instance" do
      mediator = Mediate.mediator

      expect(mediator).to be_truthy
      expect(mediator).to be_instance_of(Mediate::Mediator)
    end

    it "returns the same instance from multiple calls" do
      mediator1 = Mediate.mediator
      mediator2 = Mediate.mediator
      mediator3 = Mediate.mediator

      expect(mediator1).to be(mediator2)
      expect(mediator2).to be(mediator3)
    end
  end

  describe "#dispatch" do
    it "passes request to mediator instance and returns response" do
      request = Stubs::Request.new
      expected = "test_response"
      mediator = double("mediator")
      allow(Mediate).to receive(:mediator).and_return(mediator)
      expect(mediator).to receive(:dispatch).with(request).and_return(expected)
      actual = Mediate.dispatch(request)
      expect(actual).to be(expected)
    end
  end

  describe "#publish" do
    it "passes notification to mediator instance" do
      notification = Stubs::Notif.new
      mediator = double("mediator")
      allow(Mediate).to receive(:mediator).and_return(mediator)
      expect(mediator).to receive(:publish).with(notification)
      Mediate.publish(notification)
    end
  end
end
