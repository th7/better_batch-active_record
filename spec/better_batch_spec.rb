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
  let(:returning) { nil }

  it 'has better_batch' do
    expect(better_batch).to be_a(BetterBatch::ActiveRecord::Query)
  end

  describe '.upsert' do
    subject { better_batch.upsert(data, unique_by:, returning:) }
    it 'saves the expected records' do
      expect { subject }.to change { TestItem.count }.from(0).to(3)
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
      it { is_expected.to eq(TestItem.pluck(:id).map { |id| { id: } }) }
    end
  end
end
