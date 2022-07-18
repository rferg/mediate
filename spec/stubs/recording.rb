# frozen_string_literal: true

require_relative "basic"

module Stubs
  module Recording
    class RequestHandler < Mediate::RequestHandler
      def handle(request)
        request.classes << self
      end
    end

    class DerivedRequestHandler < RequestHandler; end

    class RaiseHandler < RequestHandler
      def handle(request)
        request.classes << self
        raise "from:#{self}"
      end
    end

    class Request < Stubs::Request
      attr_reader :classes, :exceptions

      def initialize(classes = [])
        @classes = classes
        @exceptions = []
        super()
      end
    end

    class DerivedRequest < Request; end

    class Notif < Stubs::Notif
      attr_reader :classes, :exceptions

      def initialize(classes = [])
        @classes = classes
        @exceptions = []
        super()
      end
    end

    class DerivedNotif < Notif; end

    class NotifHandler < Mediate::NotificationHandler
      def handle(notif)
        notif.classes << self
      end
    end

    class DerivedNotifHandler < NotifHandler; end

    class RaiseNotifHandler < NotifHandler
      def handle(notif)
        notif.classes << self
        raise "from:#{self}"
      end
    end

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
end
