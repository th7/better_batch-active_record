# frozen_string_literal: true

require 'rails_helper'
require 'spec_util'
# this is really an integration test for BetterBatch::ActiveRecord::Model
RSpec.describe TestItem do
  let(:spec_util) { SpecUtil.new(self) }
  let(:better_batch) { described_class.better_batch }
  let(:unique_by) { spec_util.unique_by }

  it 'has better_batch' do
    expect(better_batch).to be_a(BetterBatch::ActiveRecord::Query)
  end

  assert_saved = proc do
    let(:records) { described_class.all.order(unique_field: :asc) }
    it 'saves the expected records' do
      subject
      expect(spec_util.saved_inputs).to eq(spec_util.expected_saved)
    end

    it 'sets created_at' do
      subject
      expect(spec_util.saved_created_at).to all be_a(ActiveSupport::TimeWithZone)
    end

    it 'sets updated_at' do
      subject
      expect(spec_util.saved_updated_at).to all be_a(ActiveSupport::TimeWithZone)
    end
  end

  common_base_expectations = proc do
    context 'returning: "*"' do
      let(:returning) { '*' }

      it { is_expected.to eq(spec_util.saved_data) }
    end

    context 'returning: :id' do
      let(:returning) { :id }

      it { is_expected.to eq(spec_util.saved_records.pluck(:id)) }
    end

    context 'returning: [:id]' do
      let(:returning) { [:id] }

      it { is_expected.to eq(spec_util.saved_slice(*returning)) }
    end

    context 'returning: [:id, :data]' do
      let(:returning) { %i[id data] }

      it { is_expected.to eq(spec_util.saved_slice(*returning)) }
    end
  end

  describe '#upsert' do
    subject { better_batch.upsert(spec_util.data, unique_by:, returning:) }

    let(:returning) { :id }

    instance_exec(&common_base_expectations)

    instance_exec(&assert_saved)

    context 'returning: nil' do
      let(:returning) { nil }

      it 'saves the expected records' do
        expect { subject }.to change(described_class, :count).from(0).to(3)
      end

      it { is_expected.to be_nil }
    end

    context 'returning: []' do
      let(:returning) { [] }

      instance_exec(&assert_saved)

      it { is_expected.to be_nil }
    end

    context 'returning not specified' do
      subject { better_batch.upsert(spec_util.data, unique_by:) }

      it { is_expected.to be_nil }
    end
  end

  describe '#select' do
    subject { better_batch.select(spec_util.data, unique_by:, returning:) }

    before { spec_util.preload_default }

    instance_exec(&common_base_expectations)

    context 'returning: nil' do
      let(:returning) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error('Select query returning nothing is invalid.')
      end
    end

    context 'returning: []' do
      let(:returning) { [] }

      it 'raises an error' do
        expect { subject }.to raise_error('Select query returning nothing is invalid.')
      end
    end

    context 'with extraneous data' do # rubocop:disable RSpec/EmptyExampleGroup
      before { spec_util.add_to_inputs(child_records: :anything) }

      instance_exec(&common_base_expectations)
    end

    context 'string keys' do
      let(:returning) { '*' }

      before { spec_util.data.each(&:stringify_keys!) }

      it 'raises a descriptive error' do
        msg = 'All unique_by columns must be in the given data, ' \
              'but [:unique_field] was missing from ["unique_field", "data"].'
        expect { subject }.to raise_error(BetterBatch::ActiveRecord::Error, msg)
      end
    end
  end

  common_with_pk_expectations = proc do
    it { is_expected.to eq(spec_util.expected_with_pk) }
  end

  describe '#with_upserted_pk' do
    subject { better_batch.with_upserted_pk(spec_util.data, except:, unique_by:) }

    let(:except) { nil }

    instance_exec(&common_with_pk_expectations)
    instance_exec(&assert_saved)

    context 'except: :child_records' do # rubocop:disable RSpec/EmptyExampleGroup
      let(:except) { :child_records }

      before { spec_util.add_to_inputs(child_records: :anything) }

      instance_exec(&common_with_pk_expectations)
      instance_exec(&assert_saved)
    end

    context 'except: [:child_records]' do # rubocop:disable RSpec/EmptyExampleGroup
      let(:except) { [:child_records] }

      before { spec_util.add_to_inputs(child_records: :anything) }

      instance_exec(&common_with_pk_expectations)
      instance_exec(&assert_saved)
    end

    context 'except: is absent' do # rubocop:disable RSpec/EmptyExampleGroup
      subject { better_batch.with_upserted_pk(spec_util.data, unique_by:) }

      instance_exec(&common_with_pk_expectations)
      instance_exec(&assert_saved)
    end
  end

  describe '#with_selected_pk' do
    subject { better_batch.with_upserted_pk(spec_util.data, unique_by:) }

    before { spec_util.preload_default }

    instance_exec(&common_with_pk_expectations)

    context 'with extraneous data' do # rubocop:disable RSpec/EmptyExampleGroup
      subject { better_batch.with_selected_pk(spec_util.data, unique_by:) }

      before { spec_util.add_to_inputs(child_records: :anything) }

      instance_exec(&common_with_pk_expectations)
    end
  end

  common_set_pk_expectations = proc do
    it { is_expected.to be_nil }

    it 'adds ids to the input data' do
      expect { subject }.to change { spec_util.inputs_slice(:id) }
        .from([{}, {}, {}])
        .to(spec_util.lazy.saved_slice(:id))
    end
  end

  describe '#set_upserted_pk' do
    subject { better_batch.set_upserted_pk(spec_util.data, unique_by:, except:) }

    let(:except) { nil }

    instance_exec(&common_set_pk_expectations)
    instance_exec(&assert_saved)

    context 'except: :child_records' do # rubocop:disable RSpec/EmptyExampleGroup
      let(:except) { :child_records }

      before { spec_util.add_to_inputs(child_records: :anything) }

      instance_exec(&common_set_pk_expectations)
      instance_exec(&assert_saved)
    end

    context 'except: [:child_records]' do # rubocop:disable RSpec/EmptyExampleGroup
      let(:except) { [:child_records] }

      before { spec_util.add_to_inputs(child_records: :anything) }

      instance_exec(&common_set_pk_expectations)
      instance_exec(&assert_saved)
    end

    context 'except: is absent' do # rubocop:disable RSpec/EmptyExampleGroup
      subject { better_batch.set_upserted_pk(spec_util.data, unique_by:) }

      instance_exec(&common_set_pk_expectations)
      instance_exec(&assert_saved)
    end
  end

  describe '#set_selected_pk' do # rubocop:disable RSpec/EmptyExampleGroup
    subject { better_batch.set_upserted_pk(spec_util.data, unique_by:) }

    before { better_batch.upsert(spec_util.data, unique_by:) }

    instance_exec(&common_set_pk_expectations)
  end
end
