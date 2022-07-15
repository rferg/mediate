# frozen_string_literal: true

require "spec_helper"
require_relative "../stubs/basic"

module Stubs
  class ClassHandler < Mediate::RequestHandler
    def handle(request)
      request.classes << self
    end
  end

  class DerivedClassHandler < Stubs::ClassHandler; end

  class RaiseHandler < Stubs::ClassHandler
    def handle(request)
      request.classes << self
      raise "from:#{self}"
    end
  end

  class ClassesRequest < Stubs::Request
    attr_reader :classes, :exceptions

    def initialize(classes = [])
      @classes = classes
      @exceptions = []
      super()
    end
  end

  class DerivedClassesRequest < ClassesRequest; end

  class PreOneHandler < Mediate::PrerequestBehavior
    def handle(request)
      request.classes << self
    end
  end

  class PreTwoHandler < PreOneHandler; end
  class PreThreeHandler < PreOneHandler; end

  class PreRaiseHandler < Mediate::PrerequestBehavior
    def handle(request)
      request.classes << self
      raise "from:#{self}"
    end
  end

  class PostOneHandler < Mediate::PostrequestBehavior
    def handle(_request, result)
      result << self
    end
  end

  class PostTwoHandler < PostOneHandler; end

  class PostRaiseHandler < Mediate::PostrequestBehavior
    def handle(request, _result)
      request.classes << self
      raise "from:#{self}"
    end
  end

  class ErrorOneHandler < Mediate::ErrorHandler
    def handle(request, exception)
      request.classes << self
      request.exceptions << exception
    end
  end

  class ErrorTwoHandler < ErrorOneHandler; end

  class ErrorRaiseHandler < Mediate::ErrorHandler
    def handle(request, exception)
      request.classes << self
      request.exceptions << exception
      raise "from:#{self}"
    end
  end
end

RSpec.describe Mediate::Mediator do
  let(:mediator) { Class.new(Mediate::Mediator).instance }

  describe "#dispatch" do
    it "raises ArgumentError if request is nil" do
      expect { mediator.dispatch(nil) }.to raise_error(ArgumentError, "request cannot be nil")
    end
    context "with no request handler" do
      it "raises NoHandlerError if no handlers registered" do
        expect { mediator.dispatch(Stubs::Request.new) }
          .to raise_error(Mediate::Errors::NoHandlerError, /#{Stubs::Request}/)
      end

      it "raises NoHandlerError if some handlers registered, but not for request type" do
        mediator.register_request_handler(Stubs::RequestHandler, Stubs::OtherRequest)

        expect { mediator.dispatch(Stubs::Request.new) }
          .to raise_error(Mediate::Errors::NoHandlerError, /#{Stubs::Request}/)
      end

      it "raises NoHandlerError if pipeline behaviors registered, but no handler" do
        mediator.register_prerequest_behavior(Stubs::Prerequest, Stubs::Request)
        mediator.register_postrequest_behavior(Stubs::Postrequest, Stubs::Request)

        expect { mediator.dispatch(Stubs::Request.new) }
          .to raise_error(Mediate::Errors::NoHandlerError, /#{Stubs::Request}/)
      end
    end

    context "with pipeline returning successfully" do
      before do
        mediator.register_request_handler(Stubs::ClassHandler, Stubs::ClassesRequest)
      end

      it "returns from handler alone" do
        expected = [Stubs::ClassHandler]
        actual = mediator.dispatch(Stubs::ClassesRequest.new)
        expect(actual).to match_array(expected)
      end

      it "returns from pipeline with prerequest behaviors" do
        expected = [Stubs::PreTwoHandler, Stubs::PreOneHandler, Stubs::ClassHandler]
        mediator.register_prerequest_behavior(Stubs::PreOneHandler, Stubs::ClassesRequest)
        mediator.register_prerequest_behavior(Stubs::PreTwoHandler, Stubs::ClassesRequest)
        actual = mediator.dispatch(Stubs::ClassesRequest.new)
        expect(actual).to match_array(expected)
      end

      it "returns from pipeline with postrequest behaviors" do
        expected = [Stubs::ClassHandler, Stubs::PostTwoHandler, Stubs::PostOneHandler]
        mediator.register_postrequest_behavior(Stubs::PostOneHandler, Stubs::ClassesRequest)
        mediator.register_postrequest_behavior(Stubs::PostTwoHandler, Stubs::ClassesRequest)
        actual = mediator.dispatch(Stubs::ClassesRequest.new)
        expect(actual).to match_array(expected)
      end

      it "returns from pipeline with prerequest and postrequest behaviors" do
        expected = [Stubs::PreTwoHandler, Stubs::PreOneHandler, Stubs::ClassHandler,
                    Stubs::PostTwoHandler, Stubs::PostOneHandler]
        mediator.register_postrequest_behavior(Stubs::PostOneHandler, Stubs::ClassesRequest)
        mediator.register_postrequest_behavior(Stubs::PostTwoHandler, Stubs::ClassesRequest)
        mediator.register_prerequest_behavior(Stubs::PreOneHandler, Stubs::ClassesRequest)
        mediator.register_prerequest_behavior(Stubs::PreTwoHandler, Stubs::ClassesRequest)
        actual = mediator.dispatch(Stubs::ClassesRequest.new)
        expect(actual).to match_array(expected)
      end

      it "calls all and only behaviors registered for request class or its superclasses" do
        expected = [Stubs::PreTwoHandler, Stubs::PreThreeHandler, Stubs::ClassHandler, Stubs::PostTwoHandler]
        mediator.register_prerequest_behavior(Stubs::PreTwoHandler, Stubs::ClassesRequest)
        mediator.register_prerequest_behavior(Stubs::PreThreeHandler, Mediate::Request)
        mediator.register_postrequest_behavior(Stubs::PostTwoHandler, Mediate::Request)
        mediator.register_prerequest_behavior(Stubs::PreOneHandler, Stubs::OtherRequest)
        mediator.register_postrequest_behavior(Stubs::PostTwoHandler, Stubs::OtherRequest)
        actual = mediator.dispatch(Stubs::ClassesRequest.new)
        expect(actual).to match_array(expected)
      end

      it "uses last handler registered for request class" do
        expected = [Stubs::DerivedClassHandler]
        mediator.register_request_handler(Stubs::DerivedClassHandler, Stubs::ClassesRequest)
        actual = mediator.dispatch(Stubs::ClassesRequest.new)
        expect(actual).to match_array(expected)
      end

      it "uses handler registered for most derived request class" do
        expected = [Stubs::ClassHandler]
        # Stubs::ClassesRequest inherits from Stubs::Request
        mediator.register_request_handler(Stubs::RequestHandler, Stubs::Request)
        actual = mediator.dispatch(Stubs::ClassesRequest.new)
        expect(actual).to match_array(expected)
      end

      it "uses handler registered for request base class if one does not exist for request class" do
        expected = [Stubs::ClassHandler]
        # DerivedClassesRequest inherits from ClassesRequest (handler registered in before block)
        actual = mediator.dispatch(Stubs::DerivedClassesRequest.new)
        expect(actual).to match_array(expected)
      end
    end

    context "with exception in pipeline" do
      it "does not continue to handler if exception raised in prerequest behavior" do
        mediator.register_prerequest_behavior(Stubs::PreRaiseHandler, Stubs::ClassesRequest)
        mediator.register_request_handler(Stubs::ClassHandler, Stubs::ClassesRequest)
        mediator.register_error_handler(Stubs::ErrorOneHandler, StandardError, Stubs::ClassesRequest)
        expected = [Stubs::PreRaiseHandler, Stubs::ErrorOneHandler]
        request = Stubs::ClassesRequest.new
        result = mediator.dispatch(request)
        expect(result).to be_nil
        expect(request.classes).to match_array(expected)
      end

      it "does not continue to postrequest behavior if exception raised in handler" do
        mediator.register_request_handler(Stubs::RaiseHandler, Stubs::ClassesRequest)
        mediator.register_postrequest_behavior(Stubs::PostOneHandler, Stubs::ClassesRequest)
        mediator.register_error_handler(Stubs::ErrorOneHandler, StandardError, Stubs::ClassesRequest)
        mediator.register_error_handler(Stubs::ErrorTwoHandler, StandardError, Stubs::ClassesRequest)
        expected = [Stubs::RaiseHandler, Stubs::ErrorOneHandler, Stubs::ErrorTwoHandler]
        request = Stubs::ClassesRequest.new
        result = mediator.dispatch(request)
        expect(result).to be_nil
        expect(request.classes).to match_array(expected)
      end

      it "still returns result if postrequest behavior raises and no error handler does" do
        mediator.register_request_handler(Stubs::ClassHandler, Stubs::ClassesRequest)
        mediator.register_postrequest_behavior(Stubs::PostRaiseHandler, Stubs::ClassesRequest)
        mediator.register_error_handler(Stubs::ErrorOneHandler, StandardError, Stubs::ClassesRequest)
        expected = [Stubs::ClassHandler, Stubs::PostRaiseHandler, Stubs::ErrorOneHandler]
        actual = mediator.dispatch(Stubs::ClassesRequest.new)
        expect(actual).to match_array(expected)
      end

      it "raises if error handler raises" do
        mediator.register_request_handler(Stubs::RaiseHandler, Stubs::ClassesRequest)
        mediator.register_error_handler(Stubs::ErrorRaiseHandler, StandardError, Stubs::ClassesRequest)
        expected = [Stubs::RaiseHandler, Stubs::ErrorRaiseHandler]
        request = Stubs::ClassesRequest.new
        expect { mediator.dispatch(request) }.to raise_error
        expect(request.classes).to match_array(expected)
      end
    end
  end
end
