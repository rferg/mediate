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
end
