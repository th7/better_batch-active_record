# frozen_string_literal: true

# this file will be skipped by normal spec runs
# it's just here for reference/information
# use `rspec spec/benchmarks.rb` to re-verify the assertions

require 'benchmark'

module Runner
  NUMS = 1.upto(1_000).to_a.freeze
  NUMS_ENUM = NUMS.to_enum
  REPS = 10_000
  TOLERANCE = 0.2
  # slower, faster, expected multiple
  CASES = [
    [:lazy_zip, :zip, 4],
    [:lazy_zip_enums, :zip_enums, 1.25],
    [:zip_reiterate, :zip_block, 2.6]
  ].map(&:freeze).freeze

  class << self
    def cases
      CASES.map do |a_case|
        margin = (a_case.last * TOLERANCE).round(3)
        a_case + [margin]
      end
    end

    def result(key)
      results[key] ||= run(&method(key))
    end

    def multiple(key_a, key_b)
      result(key_a) / result(key_b)
    end

    private

    def results
      @results ||= {}
    end

    def run(&block)
      Benchmark.realtime { REPS.times { block.call } }
    end

    def lazy_zip
      NUMS.to_enum.lazy.zip(NUMS).force
    end

    def zip
      NUMS.zip(NUMS)
    end

    def lazy_zip_enums
      NUMS_ENUM.lazy.zip(NUMS_ENUM).force
    end

    def zip_enums
      NUMS_ENUM.zip(NUMS_ENUM)
    end

    def zip_reiterate
      NUMS.zip(NUMS).each { |a, b| } # rubocop:disable Lint/EmptyBlock
    end

    def zip_block
      NUMS.zip(NUMS) { |a, b| } # rubocop:disable Lint/EmptyBlock
    end
  end
end

RSpec.describe 'benchmarks' do # rubocop:disable RSpec/DescribeClass
  Runner.cases.each do |slower, faster, expected, margin|
    it "#{faster} is #{expected}x faster than #{slower}" do
      expect(Runner.multiple(slower, faster).round(3)).to be_within(margin).of(expected)
    end
  end
end
