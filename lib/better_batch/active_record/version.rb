# frozen_string_literal: true

module BetterBatch
  module ActiveRecord
    # this gem is developed/tested inside a rails app
    # and Rails really wants this file to define this constant
    # and trying to prevent it from autoloading was a struggle
    # so, as usual, the right thing to do is bend to Rails' will
    module Version; end
    VERSION = '1.0.2'
  end
end
