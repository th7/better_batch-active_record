# frozen_string_literal: true

require 'better_batch/query'
require 'better_batch/active_record/query'

module BetterBatch
  module ActiveRecord
    module Transform
      class << self
        def assert_inputs_ok!(data, unique_by:)
          data_keys = data.first.keys
          missing = Array(unique_by) - data_keys
          return if missing.empty?

          msg = "All unique_by columns must be in the given data, but #{missing.inspect} was missing from #{data_keys}."
          raise Error, msg
        end

        def slice_upsert(data, except:)
          case except
          when nil, []
            data
          else
            data.map { |datum| datum.except(*except) }
          end
        end

        def build_return(returning, rows, query)
          case returning
          when Symbol
            rows.map(&:first)
          when nil, []
            nil
          else
            hash_rows(query.returning.map(&:input), rows)
          end
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
end
