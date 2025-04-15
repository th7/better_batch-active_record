# frozen_string_literal: true

require 'better_batch/active_record/query'

module BetterBatch
  module ActiveRecord
    module Model
      def better_batch
        Query.new(self)
      end
    end
  end
end
