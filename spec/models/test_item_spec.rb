# frozen_string_literal: true

require 'rails_helper'

# this is really an integration test for BetterBatch::ActiveRecord::Model
RSpec.describe TestItem do
  let(:better_batch) { described_class.better_batch }

  let(:data) do
    [
      { unique_field: 1, data: '1' },
      { unique_field: 2, data: '2' },
      { unique_field: 3, data: '3' }
    ]
  end
  let(:unique_by) { :unique_field }

  it 'has better_batch' do
    expect(better_batch).to be_a(BetterBatch::ActiveRecord::Query)
  end

  common_base_expectations = proc do
    context 'returning: "*"' do
      let(:returning) { '*' }

      it { is_expected.to eq(described_class.all.map(&:attributes).map(&:symbolize_keys)) }
    end

    context 'returning: :id' do
      let(:returning) { :id }

      it { is_expected.to eq(described_class.pluck(:id)) }
    end

    context 'returning: [:id]' do
      let(:returning) { [:id] }

      it { is_expected.to eq(described_class.pluck(:id).map { |id| { id: } }) }
    end

    context 'returning: [:id, :data]' do
      let(:returning) { %i[id data] }

      it { is_expected.to eq(described_class.pluck(:id, :data).map { |id, data| { id:, data: } }) }
    end
  end

  describe '#upsert' do
    subject { better_batch.upsert(data, unique_by:, returning:) }

    let(:returning) { :id }

    instance_exec(&common_base_expectations)

    it 'saves the expected records' do
      expect { subject }.to change(described_class, :count).from(0).to(3)
    end

    context 'returning: nil' do
      let(:returning) { nil }

      it 'saves the expected records' do
        expect { subject }.to change(described_class, :count).from(0).to(3)
      end

      it { is_expected.to be_nil }
    end
  end

  common_with_pk_expectations = proc do
    it { is_expected.to eq(data.zip(described_class.pluck(:id))) }
  end

  describe '#with_upserted_pk' do
    subject { better_batch.with_upserted_pk(data, unique_by:) }

    instance_exec(&common_with_pk_expectations)

    it 'saves the expected records' do
      expect { subject }.to change(described_class, :count).from(0).to(3)
    end
  end

  common_set_pk_expectations = proc do
    it { is_expected.to be_nil }

    it 'adds ids to the input data' do # rubocop:disable RSpec/MultipleExpectations
      ids_proc = proc { data.map { |d| d[:id] } }
      expect { subject }.to change(&ids_proc)
        .from([nil, nil, nil])
      # .to syntax eager evaluates and gets wrong result
      expect(ids_proc.call).to eq(described_class.pluck(:id))
    end
  end

  describe '#set_upserted_pk' do
    subject { better_batch.set_upserted_pk(data, unique_by:) }

    instance_exec(&common_set_pk_expectations)

    it 'saves the expected records' do
      expect { subject }.to change(described_class, :count).from(0).to(3)
    end
  end
end
