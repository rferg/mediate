# frozen_string_literal: true

RSpec.describe Mediate::ErrorHandlerState do
  let(:state) { Mediate::ErrorHandlerState.new }

  describe "#set_as_handled" do
    it "sets handled? to true" do
      state.set_as_handled
      expect(state.handled?).to be true
    end

    it "sets result" do
      expected = "test"
      state.set_as_handled(expected)
      expect(state.handled?).to be true
      expect(state.result).to be expected
    end

    it "overwrites result if called multiple times" do
      expected = 6
      state.set_as_handled(expected - 1)
      state.set_as_handled(expected)
      expect(state.handled?).to be true
      expect(state.result).to be expected
    end
  end

  describe "#handled?" do
    it "returns false if #set_as_handled has not been called" do
      expect(state.handled?).to be false
    end

    it "returns true if #set_as_handled has been called" do
      state.set_as_handled
      expect(state.handled?).to be true
    end
  end
end
