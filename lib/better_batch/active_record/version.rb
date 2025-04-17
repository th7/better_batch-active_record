# frozen_string_literal: true

module BetterBatch
  module ActiveRecord
    # this gem is developed/tested inside a rails app
    # and Rails really wants this file to define this constant
    # and trying to prevent it from autoloading was a struggle
    # so, I just did what Rails wanted
    # because Rails is love, Rails is life, Rails is everything
    module Version; end

    VERSION = '1.0.3'
  end
end
