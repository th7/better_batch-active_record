# frozen_string_literal: true

require 'better_batch/query'

module BetterBatch
  module ActiveRecord
    class Query
      def initialize(model)
        @model = model
      end

      def build(data, unique_by:, returning:)
        BetterBatch::Query.new(table_name:, primary_key:, input_columns: data.first.keys,
                               column_types:, unique_columns: unique_by, now_on_insert:,
                               now_on_update:, returning:)
      end

      private

      attr_reader :model

      def table_name
        @table_name ||= model.table_name
      end

      def primary_key
        model.primary_key.to_sym
      end

      def column_types
        @column_types ||= model.columns.to_h { |c| [c.name.to_sym, c.sql_type] }
      end

      def now_on_insert
        [created_at_if_present, updated_at_if_present].compact
      end

      def now_on_update
        updated_at_if_present
      end

      def created_at_if_present
        :created_at if column_types.key?(:created_at)
      end

      def updated_at_if_present
        :updated_at if column_types.key?(:updated_at)
      end
    end
  end
end
