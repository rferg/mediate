# frozen_string_literal: true

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
        mediator.register_request_handler(Stubs::Recording::RequestHandler, Stubs::Recording::Request)
      end

      it "returns from handler alone" do
        expected = [Stubs::Recording::RequestHandler]
        actual = mediator.dispatch(Stubs::Recording::Request.new)
        expect(actual).to match_array(expected)
      end

      it "returns from pipeline with prerequest behaviors" do
        expected = [Stubs::Recording::PreTwoHandler, Stubs::Recording::PreOneHandler, Stubs::Recording::RequestHandler]
        mediator.register_prerequest_behavior(Stubs::Recording::PreOneHandler, Stubs::Recording::Request)
        mediator.register_prerequest_behavior(Stubs::Recording::PreTwoHandler, Stubs::Recording::Request)
        actual = mediator.dispatch(Stubs::Recording::Request.new)
        expect(actual).to match_array(expected)
      end

      it "returns from pipeline with postrequest behaviors" do
        expected = [Stubs::Recording::RequestHandler, Stubs::Recording::PostTwoHandler,
                    Stubs::Recording::PostOneHandler]
        mediator.register_postrequest_behavior(Stubs::Recording::PostOneHandler, Stubs::Recording::Request)
        mediator.register_postrequest_behavior(Stubs::Recording::PostTwoHandler, Stubs::Recording::Request)
        actual = mediator.dispatch(Stubs::Recording::Request.new)
        expect(actual).to match_array(expected)
      end

      it "returns from pipeline with prerequest and postrequest behaviors" do
        expected = [Stubs::Recording::PreTwoHandler, Stubs::Recording::PreOneHandler, Stubs::Recording::RequestHandler,
                    Stubs::Recording::PostTwoHandler, Stubs::Recording::PostOneHandler]
        mediator.register_postrequest_behavior(Stubs::Recording::PostOneHandler, Stubs::Recording::Request)
        mediator.register_postrequest_behavior(Stubs::Recording::PostTwoHandler, Stubs::Recording::Request)
        mediator.register_prerequest_behavior(Stubs::Recording::PreOneHandler, Stubs::Recording::Request)
        mediator.register_prerequest_behavior(Stubs::Recording::PreTwoHandler, Stubs::Recording::Request)
        actual = mediator.dispatch(Stubs::Recording::Request.new)
        expect(actual).to match_array(expected)
      end

      it "calls all and only behaviors registered for request class or its superclasses" do
        expected = [Stubs::Recording::PreTwoHandler, Stubs::Recording::PreThreeHandler,
                    Stubs::Recording::RequestHandler, Stubs::Recording::PostTwoHandler]
        mediator.register_prerequest_behavior(Stubs::Recording::PreTwoHandler, Stubs::Recording::Request)
        mediator.register_prerequest_behavior(Stubs::Recording::PreThreeHandler, Mediate::Request)
        mediator.register_postrequest_behavior(Stubs::Recording::PostTwoHandler, Mediate::Request)
        mediator.register_prerequest_behavior(Stubs::Recording::PreOneHandler, Stubs::OtherRequest)
        mediator.register_postrequest_behavior(Stubs::Recording::PostTwoHandler, Stubs::OtherRequest)
        actual = mediator.dispatch(Stubs::Recording::Request.new)
        expect(actual).to match_array(expected)
      end

      it "uses correct handler and behaviors registered in different threads" do
        expected = [Stubs::Recording::PreTwoHandler, Stubs::Recording::PreThreeHandler,
                    Stubs::Recording::RequestHandler, Stubs::Recording::PostTwoHandler]
        threads = []
        threads << Thread.new do
          mediator.register_prerequest_behavior(Stubs::Recording::PreTwoHandler, Stubs::Recording::Request)
        end
        threads << Thread.new do
          mediator.register_prerequest_behavior(Stubs::Recording::PreThreeHandler, Mediate::Request)
        end
        threads << Thread.new do
          mediator.register_postrequest_behavior(Stubs::Recording::PostTwoHandler, Mediate::Request)
        end
        threads << Thread.new do
          mediator.register_prerequest_behavior(Stubs::Recording::PreOneHandler, Stubs::OtherRequest)
        end
        threads << Thread.new do
          mediator.register_postrequest_behavior(Stubs::Recording::PostTwoHandler, Stubs::OtherRequest)
        end
        threads.map(&:join)
        5.times.map do
          Thread.new do
            actual = mediator.dispatch(Stubs::Recording::Request.new)
            expect(actual).to match_array(expected)
          end
        end.map(&:join)
      end

      it "uses handler registered for most derived request class" do
        expected = [Stubs::Recording::RequestHandler]
        # Stubs::Recording::Request inherits from Stubs::Request
        mediator.register_request_handler(Stubs::RequestHandler, Stubs::Request)
        actual = mediator.dispatch(Stubs::Recording::Request.new)
        expect(actual).to match_array(expected)
      end

      it "uses handler registered for request base class if one does not exist for request class" do
        expected = [Stubs::Recording::RequestHandler]
        # DerivedRequest inherits from Request (handler registered in before block)
        actual = mediator.dispatch(Stubs::Recording::DerivedRequest.new)
        expect(actual).to match_array(expected)
      end
    end

    context "with exception in pipeline" do
      it "does not continue to handler if exception raised in prerequest behavior" do
        mediator.register_prerequest_behavior(Stubs::Recording::PreRaiseHandler, Stubs::Recording::Request)
        mediator.register_request_handler(Stubs::Recording::RequestHandler, Stubs::Recording::Request)
        mediator.register_error_handler(Stubs::Recording::ErrorOneHandler, StandardError,
                                        Stubs::Recording::Request)
        expected = [Stubs::Recording::PreRaiseHandler, Stubs::Recording::ErrorOneHandler]
        request = Stubs::Recording::Request.new
        result = mediator.dispatch(request)
        expect(result).to be_nil
        expect(request.classes).to match_array(expected)
      end

      it "does not continue to postrequest behavior if exception raised in handler" do
        mediator.register_request_handler(Stubs::Recording::RaiseHandler, Stubs::Recording::Request)
        mediator.register_postrequest_behavior(Stubs::Recording::PostOneHandler, Stubs::Recording::Request)
        mediator.register_error_handler(Stubs::Recording::ErrorOneHandler, StandardError,
                                        Stubs::Recording::Request)
        mediator.register_error_handler(Stubs::Recording::ErrorTwoHandler, StandardError,
                                        Stubs::Recording::Request)
        expected = [Stubs::Recording::RaiseHandler, Stubs::Recording::ErrorOneHandler,
                    Stubs::Recording::ErrorTwoHandler]
        request = Stubs::Recording::Request.new
        result = mediator.dispatch(request)
        expect(result).to be_nil
        expect(request.classes).to match_array(expected)
      end

      it "raises if error handler raises" do
        mediator.register_request_handler(Stubs::Recording::RaiseHandler, Stubs::Recording::Request)
        mediator.register_error_handler(Stubs::Recording::ErrorRaiseHandler, StandardError,
                                        Stubs::Recording::Request)
        expected = [Stubs::Recording::RaiseHandler, Stubs::Recording::ErrorRaiseHandler]
        request = Stubs::Recording::Request.new
        expect { mediator.dispatch(request) }.to raise_error(RuntimeError)
        expect(request.classes).to match_array(expected)
      end

      it "returns early with result if error handler sets state as handled" do
        expected_result = "test_result"
        error_handler = Stubs::Recording::ErrorResolveHandlerDefiner.define(expected_result)
        mediator.register_request_handler(Stubs::Recording::RaiseHandler, Stubs::Recording::Request)
        # Since request class is higher in inheritance chain, this should always run last
        mediator.register_error_handler(Stubs::Recording::ErrorOneHandler, StandardError, Mediate::Request)
        mediator.register_error_handler(error_handler, StandardError, Stubs::Recording::Request)
        expected_classes = [Stubs::Recording::RaiseHandler, error_handler]
        request = Stubs::Recording::Request.new
        result = mediator.dispatch(request)
        expect(result).to be(expected_result)
        expect(request.classes).to match_array(expected_classes)
      end
    end
  end
end
