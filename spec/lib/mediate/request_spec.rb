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

  class AnotherRequest < Mediate::Request
    attr_reader :value

    def initialize(value)
      @value = value
      super()
    end
  end

  class SubRequest < TestRequest
    attr_reader :first, :second
  end
end

RSpec.describe Mediate::Request do
  let(:mediator) { Class.new(Mediate::Mediator).instance }

  after(:each) do
    RequestSpec::TestRequest.undefine_implicit_handler
    RequestSpec::AnotherRequest.undefine_implicit_handler
    RequestSpec::SubRequest.undefine_implicit_handler
  end

  describe "#handle_with" do
    it "registers a handler that runs the given lambda on the request" do
      a = "abc"
      b = "_xyz"
      expected = a + b
      RequestSpec::TestRequest.handle_with(->(r) { r.first + r.second }, mediator)
      actual = mediator.dispatch(RequestSpec::TestRequest.new(a, b))
      expect(actual).to eq(expected)
    end

    it "creates a RequestHandler class that can be created with #create_implicit_handler" do
      a = "abc"
      b = "_xyz"
      expected = a + b
      RequestSpec::TestRequest.handle_with(->(r) { r.first + r.second }, mediator)
      request = RequestSpec::TestRequest.new(a, b)
      actual = RequestSpec::TestRequest.create_implicit_handler.handle(request)
      expect(actual).to eq(expected)
    end

    it "registers distinct handlers for distinct request classes" do
      test_request = RequestSpec::TestRequest.new("a", "b")
      test_request_expected = test_request.first + test_request.second
      another_test_request = RequestSpec::AnotherRequest.new("z")
      another_test_request_expected = another_test_request.value
      RequestSpec::TestRequest.handle_with(->(r) { r.first + r.second }, mediator)
      RequestSpec::AnotherRequest.handle_with(->(r) { r.value }, mediator)
      test_request_actual = RequestSpec::TestRequest.create_implicit_handler.handle(test_request)
      another_test_request_actual = RequestSpec::AnotherRequest.create_implicit_handler.handle(another_test_request)
      expect(test_request_actual).to eq(test_request_expected)
      expect(another_test_request_actual).to eq(another_test_request_expected)
    end

    it "registers distinct handlers for request superclass and subclass" do
      test_request = RequestSpec::TestRequest.new("a", "b")
      test_request_expected = test_request.first + test_request.second
      sub_test_request = RequestSpec::SubRequest.new(5, 4)
      sub_test_request_expected = sub_test_request.first - sub_test_request.second
      RequestSpec::TestRequest.handle_with(->(r) { r.first + r.second }, mediator)
      RequestSpec::SubRequest.handle_with(->(r) { r.first - r.second }, mediator)
      test_request_actual = RequestSpec::TestRequest.create_implicit_handler.handle(test_request)
      sub_test_request_actual = RequestSpec::SubRequest.create_implicit_handler.handle(sub_test_request)
      expect(test_request_actual).to eq(test_request_expected)
      expect(sub_test_request_actual).to eq(sub_test_request_expected)
    end

    it "raises ArgumentError if no lambda given" do
      expect { RequestSpec::TestRequest.handle_with(nil, mediator) }.to raise_error(ArgumentError, /expected lambda/)
    end

    it "raises if implicit handler is already defined" do
      RequestSpec::TestRequest.handle_with(->(_r) { 1 }, mediator)
      expect { RequestSpec::TestRequest.handle_with(->(_r) { 1 }, mediator) }
        .to raise_error(Mediate::Errors::RequestHandlerAlreadyExistsError)
    end

    it "raises if handler already registered for request class" do
      mediator.register_request_handler(Stubs::RequestHandler, RequestSpec::TestRequest)
      expect { RequestSpec::TestRequest.handle_with(->(_r) { 1 }, mediator) }
        .to raise_error(Mediate::Errors::RequestHandlerAlreadyExistsError)
    end

    it "registers only for that request class" do
      RequestSpec::TestRequest.handle_with(->(_r) { 1 }, mediator)
      expect { mediator.dispatch(Stubs::Request.new) }.to raise_error(Mediate::Errors::NoHandlerError)
    end
  end

  describe "#create_implicit_handler" do
    it "raises if handler class is not defined" do
      expect { RequestSpec::TestRequest.create_implicit_handler }.to raise_error(/handler is not defined/)
    end

    it "returns instance of implicit handler class" do
      RequestSpec::TestRequest.handle_with(->(_r) { 1 }, mediator)
      actual = RequestSpec::TestRequest.create_implicit_handler
      expect(actual).to be_truthy
      expect(actual).to be_a(Mediate::RequestHandler)
      expect(actual).to respond_to(:handle)
    end
  end
end
