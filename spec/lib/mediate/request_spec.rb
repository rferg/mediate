# frozen_string_literal: true

module RequestSpec
  class TestRequest < Mediate::Request
    attr_reader :first, :second

    def initialize(first, second)
      @first = first
      @second = second
      super()
    end
  end
end

RSpec.describe Mediate::Request do
  let(:mediator) { Class.new(Mediate::Mediator).instance }

  after(:each) do
    RequestSpec::TestRequest.undefine_implicit_handler
  end

  describe "#handle_with" do
    it "registers a handler that runs the given block on the request" do
      a = "abc"
      b = "_xyz"
      expected = a + b
      RequestSpec::TestRequest.handle_with(mediator) { |r| r.first + r.second }
      actual = mediator.dispatch(RequestSpec::TestRequest.new(a, b))
      expect(actual).to eq(expected)
    end

    it "creates a RequestHandler class that can be created with #create_implicit_handler" do
      a = "abc"
      b = "_xyz"
      expected = a + b
      RequestSpec::TestRequest.handle_with(mediator) { |r| r.first + r.second }
      request = RequestSpec::TestRequest.new(a, b)
      actual = RequestSpec::TestRequest.create_implicit_handler.handle(request)
      expect(actual).to eq(expected)
    end

    it "raises ArgumentError if no block given" do
      expect { RequestSpec::TestRequest.handle_with(mediator) }.to raise_error(ArgumentError, /expected block/)
    end

    it "raises if implicit handler is already defined" do
      RequestSpec::TestRequest.handle_with(mediator) { |_r| 1 }
      expect { RequestSpec::TestRequest.handle_with(mediator) { |_r| 1 } }.to raise_error(/already defined/)
    end

    it "raises if handler already registered for request class" do
      mediator.register_request_handler(Stubs::RequestHandler, RequestSpec::TestRequest)
      expect { RequestSpec::TestRequest.handle_with(mediator) { |_r| 1 } }
        .to raise_error(Mediate::Errors::RequestHandlerAlreadyExistsError)
    end

    it "registers only for that request class" do
      RequestSpec::TestRequest.handle_with(mediator) { |_r| 1 }
      expect { mediator.dispatch(Stubs::Request.new) }.to raise_error(Mediate::Errors::NoHandlerError)
    end
  end

  describe "#create_implicit_handler" do
    it "raises if handler class is not defined" do
      expect { RequestSpec::TestRequest.create_implicit_handler }.to raise_error(/handler is not defined/)
    end

    it "returns instance of implicit handler class" do
      RequestSpec::TestRequest.handle_with(mediator) { |_r| 1 }
      actual = RequestSpec::TestRequest.create_implicit_handler
      expect(actual).to be_truthy
      expect(actual).to be_a(Mediate::RequestHandler)
      expect(actual).to respond_to(:handle)
    end
  end
end
