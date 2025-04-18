# frozen_string_literal: true

require 'better_batch/active_record/interface'

module BetterBatch
  module ActiveRecord
    module Model
      def better_batch
        Interface.new(self)
      end
    end
  end
end
