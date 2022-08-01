# frozen_string_literal: true

module Stubs
  class Request < Mediate::Request; end

  class OtherRequest < Mediate::Request; end

  class RequestHandler < Mediate::RequestHandler
    def handle(request); end
  end

  class Prerequest < Mediate::PrerequestBehavior
    def handle(request); end
  end

  class Postrequest < Mediate::PostrequestBehavior
    def handle(request, response); end
  end

  class Notif < Mediate::Notification; end

  class NotifHandler < Mediate::NotificationHandler
    def handle(notif); end
  end

  class ErrorHandler < Mediate::ErrorHandler
    def handle(request, error, statue); end
  end
end
