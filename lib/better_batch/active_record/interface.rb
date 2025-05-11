# frozen_string_literal: true

require 'better_batch/query'
require 'better_batch/active_record/query'
require 'better_batch/active_record/transform'

module BetterBatch
  module ActiveRecord
    class Interface
      def initialize(model)
        @builder = Query.new(model)
        @model = model
      end

      def upsert(data, unique_by:, except: nil, returning: nil)
        upsert_data = Transform.slice_upsert(data, except:)
        query = builder.build(upsert_data, unique_by:, returning:)
        result = exec_query(:upsert, query, upsert_data)
        Transform.build_return(returning, result.rows, query)
      end

      def with_upserted_pk(data, unique_by:, except: nil, &)
        upserted = upsert(data, unique_by:, except:, returning: primary_key)
        if block_given?
          data.zip(upserted, &)
        else
          data.zip(upserted)
        end
      end

      def set_upserted_pk(data, unique_by:, except: nil)
        if block_given?
          with_upserted_pk(data, unique_by:, except:) do |row, pk|
            row[primary_key] = pk
            yield row
          end
        else
          set_upserted_pk_map(data, unique_by:, except:)
        end
      end

      def select(data, unique_by:, returning:)
        Transform.assert_inputs_ok!(data, unique_by:)
        select_data = data.map { |datum| datum.slice(*unique_by) }
        query = builder.build(select_data, unique_by:, returning:)
        result = exec_query(:select, query, select_data)
        Transform.build_return(returning, result.rows, query)
      end

      def with_selected_pk(data, unique_by:, &)
        selected = select(data, unique_by:, returning: primary_key)
        if block_given?
          data.zip(selected, &)
        else
          data.zip(selected)
        end
      end

      def set_selected_pk(data, unique_by:)
        if block_given?
          with_selected_pk(data, unique_by:) do |row, pk|
            row[primary_key] = pk
            yield row
          end
        else
          set_selected_pk_map(data, unique_by:)
        end
      end

      private

      attr_reader :model, :builder

      def set_upserted_pk_map(data, unique_by:, except: nil)
        with_upserted_pk(data, unique_by:, except:).map do |row, pk|
          row[primary_key] = pk
          row
        end
      end

      def set_selected_pk_map(data, unique_by:)
        with_selected_pk(data, unique_by:).map do |row, pk|
          row[primary_key] = pk
          row
        end
      end

      def exec_query(type, query, data)
        db_exec(query.public_send(type), JSON.generate(data))
      end

      def db_exec(sql, json_data)
        model.connection_pool.with_connection do |conn|
          conn.exec_query(sql, nil, [json_data])
        end
      end

      def primary_key
        model.primary_key.to_sym
      end
    end
  end
end
