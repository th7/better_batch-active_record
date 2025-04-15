require 'better_batch/query'

module BetterBatch
  module ActiveRecord
    class Query
      def initialize(model)
        @model = model
      end

      def upsert(data, unique_by:, returning:)
        query = build_query(data, unique_by:, returning:)
        result = exec_upsert(query, data)
        case returning
        when Symbol
          result.rows.map(&:first)
        when nil
          nil
        else
          hash_rows(query.returning, result.rows)
        end
      end

      def with_upserted_pk(data, unique_by:)
        query = build_query(data, unique_by:, returning: primary_key)
        data.zip(exec_upsert(query, data).rows.map(&:first))
      end

      def set_upserted_pk(data, unique_by:)
        with_upserted_pk(data, unique_by:).each do |row, pk|
          row[primary_key] = pk
        end
        nil
      end

      def select(data, unique_by:, returning:)
        query = build_query(data, unique_by:, returning:)
        result = exec_select(query, data)
        case returning
        when Symbol
          result.rows.map(&:first)
        when nil
          nil
        else
          hash_rows(query.returning, result.rows)
        end
      end

      def with_selected_pk(data, unique_by:)
        query = build_query(data, unique_by:, returning: primary_key)
        data.zip(exec_select(query, data).rows.map(&:first))
      end

      def set_selected_pk(data, unique_by:)
        with_upserted_pk(data, unique_by:).each do |row, pk|
          row[primary_key] = pk
        end
        nil
      end

      private

      attr_reader :model

      def build_query(data, unique_by:, returning:)
        array_data = data.to_a
        unique_columns = Array(unique_by)
        input_columns = array_data.first.keys
        returning = Array(returning)
        BetterBatch::Query.new(table_name:, primary_key:, input_columns:, column_types:, unique_columns:, now_on_insert:, now_on_update:, returning:)
      end

      def exec_upsert(query, data)
        begin
          sql = query.upsert
        rescue
          raise query.inspect
        end
        json_data = JSON.generate(data)
        begin
          model.connection.exec_query(sql, nil, [json_data])
        rescue
          raise [query.inspect, query.upsert_formatted].join("\n")
        end
      end

      def exec_select(query, data)
        begin
          sql = query.select
        rescue
          raise query.inspect
        end
        json_data = JSON.generate(data)
        begin
          model.connection.exec_query(sql, nil, [json_data])
        rescue
          raise [query.inspect, query.select_formatted].join("\n")
        end
      end

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
        :created_at if column_types.has_key?(:created_at)
      end

      def updated_at_if_present
        :updated_at if column_types.has_key?(:updated_at)
      end

      def hash_rows(returning, rows)
        # avoid building an entire new hash (which would rehash keys) for each row
        # we only need to sub in the values
        indexes = returning.each_with_index.to_h.freeze
        rows.map do |row|
          indexes.transform_values { |index| row[index] }
        end
      end
    end
  end
end
