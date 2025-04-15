require 'rails_helper'

RSpec.describe TestItem do
  let(:better_batch) { described_class.better_batch }

  let(:data) do
    [
      { unique_field: 1, data: '1' },
      { unique_field: 2, data: '2' },
      { unique_field: 3, data: '3' },
    ]
  end
  let(:unique_by) { :unique_field }

  it 'has better_batch' do
    expect(better_batch).to be_a(BetterBatch::ActiveRecord::Query)
  end

  common_base_expectations = proc do
    context 'returning: "*"' do
      let(:returning) { '*' }
      it { is_expected.to eq(TestItem.all.map(&:attributes).map(&:symbolize_keys)) }
    end

    context 'returning: :id' do
      let(:returning) { :id }
      it { is_expected.to eq(TestItem.pluck(:id)) }
    end

    context 'returning: [:id]' do
      let(:returning) { [:id] }
      it { is_expected.to eq(TestItem.pluck(:id).map { |id| { id: } }) }
    end

    context 'returning: [:id, :data]' do
      let(:returning) { [:id, :data] }
      it { is_expected.to eq(TestItem.pluck(:id, :data).map { |id, data| { id:, data: } }) }
    end
  end

  describe '#upsert' do
    subject { better_batch.upsert(data, unique_by:, returning:) }

    instance_exec(&common_base_expectations)

    context 'returning: nil' do
      let(:returning) { nil }
      it 'saves the expected records' do
        expect { subject }.to change { TestItem.count }.from(0).to(3)
      end
      it { is_expected.to eq(nil) }
    end
  end

  describe '#select' do
    subject { better_batch.select(data, unique_by:, returning:) }
    before { better_batch.upsert(data, unique_by:, returning: nil) }
    instance_exec(&common_base_expectations)
  end

  common_with_pk_expectations = proc do
    it { is_expected.to eq(data.zip(TestItem.pluck(:id))) }
  end

  describe '#with_upserted_pk' do
    subject { better_batch.with_upserted_pk(data, unique_by:) }

    instance_exec(&common_with_pk_expectations)

    it 'saves the expected records' do
      expect { subject }.to change { TestItem.count }.from(0).to(3)
    end
  end

  describe '#with_selected_pk' do
    subject { better_batch.with_upserted_pk(data, unique_by:) }
    before { better_batch.upsert(data, unique_by:, returning: nil) }
    instance_exec(&common_with_pk_expectations)
  end

  common_set_pk_expectations = proc do
    it { is_expected.to eq(nil) }
    it 'adds ids to the input data' do
      ids_proc = proc { data.map { |d| d[:id] } }
      expect { subject }.to change(&ids_proc)
        .from([nil, nil, nil])
      # .to syntax eager evaluates and gets wrong result
      expect(ids_proc.call).to eq(TestItem.pluck(:id))
    end
  end

  describe '#set_upserted_pk' do
    subject { better_batch.set_upserted_pk(data, unique_by:) }

    instance_exec(&common_set_pk_expectations)

    it 'saves the expected records' do
      expect { subject }.to change { TestItem.count }.from(0).to(3)
    end
  end

  describe '#set_selected_pk' do
    subject { better_batch.set_selected_pk(data, unique_by:) }
    before { better_batch.upsert(data, unique_by:, returning: nil) }
    instance_exec(&common_set_pk_expectations)
  end
end
