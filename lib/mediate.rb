# frozen_string_literal: true

require_relative "mediate/version"
require_relative "mediate/mediator"
require "singleton"

module Mediate
  def self.mediator
    Mediator.instance
  end
end
