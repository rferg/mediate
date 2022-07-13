# frozen_string_literal: true

require "spec_helper"

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
end
