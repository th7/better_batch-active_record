# frozen_string_literal: true

require 'better_batch/query'

module BetterBatch
  module ActiveRecord
    class Query
      def initialize(model)
        @model = model
      end

      def upsert(data, unique_by:, except: nil, returning: nil)
        upsert_data = slice_upsert(data, except:)
        query = build_query(upsert_data, unique_by:, returning:)
        result = exec_query(:upsert, query, upsert_data)
        build_return(returning, result.rows, query)
      end

      def with_upserted_pk(data, unique_by:, except: nil)
        upserted = upsert(data, unique_by:, except:, returning: primary_key)
        data.zip(upserted)
      end

      def set_upserted_pk(data, unique_by:)
        with_upserted_pk(data, unique_by:).each do |row, pk|
          row[primary_key] = pk
        end
        nil
      end

      def select(data, unique_by:, returning:)
        assert_inputs_ok!(data, unique_by:)
        select_data = data.map { |datum| datum.slice(*unique_by) }
        query = build_query(select_data, unique_by:, returning:)
        result = exec_query(:select, query, select_data)
        build_return(returning, result.rows, query)
      end

      def build_return(returning, rows, query)
        case returning
        when Symbol
          rows.map(&:first)
        when nil, []
          nil
        else
          hash_rows(query.returning, rows)
        end
      end

      def with_selected_pk(data, unique_by:)
        data.zip(select(data, unique_by:, returning: primary_key))
      end

      def set_selected_pk(data, unique_by:)
        with_upserted_pk(data, unique_by:).each do |row, pk|
          row[primary_key] = pk
        end
        nil
      end

      private

      attr_reader :model

      def slice_upsert(data, except:)
        case except
        when nil, []
          data
        else
          data.map { |datum| datum.except(*except) }
        end
      end

      def assert_inputs_ok!(data, unique_by:)
        data_keys = data.first.keys
        missing = Array(unique_by) - data_keys
        return if missing.empty?

        msg = "All unique_by columns must be in the given data, but #{missing.inspect} was missing from #{data_keys}."
        raise Error, msg
      end

      def build_query(data, unique_by:, returning:)
        BetterBatch::Query.new(table_name:, primary_key:, input_columns: data.first.keys,
                               column_types:, unique_columns: unique_by, now_on_insert:,
                               now_on_update:, returning:)
      end

      def exec_query(type, query, data)
        db_exec(query.public_send(type), JSON.generate(data))
      end

      def db_exec(sql, json_data)
        model.connection.exec_query(sql, nil, [json_data])
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
        :created_at if column_types.key?(:created_at)
      end

      def updated_at_if_present
        :updated_at if column_types.key?(:updated_at)
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
