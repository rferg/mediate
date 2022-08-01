# frozen_string_literal: true

module Mediate
  #
  # Represents the result of handling an exception
  #
  class ErrorHandlerState
    attr_reader :result

    #
    # Sets the state as handled with the given result. Subsequent error handlers will be skipped and, if
    #   the exception was thrown while handling a Mediate::Request, this result will be returned.
    #
    # @param result if the exception was thrown as part of handling a Mediate::Request, this will be returned
    #
    # @return [Boolean] true
    #
    def set_as_handled(result = nil)
      @result = result
      @handled = true
    end

    #
    # Indicates whether the current exception has been handled and the result should be returned (if applicable).
    #
    # @return [Boolean] whether the current exception has been handled
    #
    def handled?
      !!@handled
    end
  end
end
