# frozen_string_literal: true

require_relative "mediate/version"
require_relative "mediate/mediator"
require "singleton"

#
# Namespace containing a simple implementation of the mediator pattern.
#
module Mediate
  #
  # Get the current mediator instance.  This will be a singleton
  # throughout the lifetime of the program.
  #
  # @return [Mediate::Mediator] the current mediator instance
  #
  def self.mediator
    Mediator.instance
  end

  #
  # Sends a request to the registered handler, passing to any applicable pipeline behaviors.
  #
  # @param [Mediate::Request] request
  #
  # @return the response returned from the Mediate::RequestHandler
  #
  # @raise [ArgumentError] if request is nil
  # @raise [Mediate::Errors::NoHandlerError] if no handlers have been registered for the given request's type
  #
  def self.dispatch(request)
    mediator.dispatch(request)
  end

  #
  # Sends a notification to all register handlers for the given notification's type.
  #
  # @param [Mediate::Notification] notification
  #
  # @return [void]
  #
  def self.publish(notification)
    mediator.publish(notification)
  end
end
