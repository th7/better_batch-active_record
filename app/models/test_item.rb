require 'better_batch/active_record/model'

class TestItem < ApplicationRecord
  extend BetterBatch::ActiveRecord::Model
end
