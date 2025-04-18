# frozen_string_literal: true

class SpecUtil
  DEFAULT_DATA = [
    { unique_field: 1, data: '1' }.freeze,
    { unique_field: 2, data: '2' }.freeze,
    { unique_field: 3, data: '3' }.freeze
  ].freeze

  def initialize(spec)
    @spec = spec
  end

  def default_data
    DEFAULT_DATA
  end

  def data
    @data ||= DEFAULT_DATA.dup.map(&:dup)
  end

  def saved_data
    saved_records.map(&:attributes).map(&:symbolize_keys)
  end

  def saved_inputs
    keys = data.first.keys
    saved_data.map { |datum| datum.slice(*keys) }
  end

  def expected_saved
    if (spec_except = from_spec(:except))
      data.map { |datum| datum.except(*spec_except) }
    else
      data
    end
  end

  def saved_pluck(*)
    saved_records.pluck(*)
  end

  def saved_slice(*)
    saved_data.map { |datum| datum.slice(*) }
  end

  def expected_with_pk
    data.zip(saved_records.pluck(:id))
  end

  def expected_set_pk
    data.zip(saved_records.pluck(:id)).map do |datum, id|
      duped = datum.dup
      duped[:id] = id
      duped
    end
  end

  def saved_records
    @saved_records ||= spec.described_class.all.order(unique_field: :asc)
  end

  def preload_default
    spec.better_batch.upsert(default_data, unique_by:)
  end

  def add_to_inputs(**)
    data.each { |datum| datum.merge!(**) }
  end

  def unique_by
    :unique_field
  end

  def saved_created_at
    saved_records.map(&:created_at)
  end

  def saved_updated_at
    saved_records.map(&:updated_at)
  end

  def inputs_slice(*)
    data.map { |datum| datum.slice(*) }
  end

  def lazy
    @lazy ||= Lazy.new(self)
  end

  def mem_block
    proc { |item| yielded << item }
  end

  def yielded
    @yielded ||= []
  end

  private

  attr_reader :spec

  def from_spec(thing)
    spec.respond_to?(thing) && spec.send(thing)
  end

  # this is a bit clever (which is a bad word)
  # but it lets us refer to data lazily
  # in expect {}.to change {} style specs
  # instead of having the expectations evaluated eagerly
  class Lazy
    def initialize(spec_util)
      @spec_util = spec_util
    end

    def method_missing(meth, ...)
      LazyEq.new { @spec_util.public_send(meth, ...) }
    end

    def respond_to_missing?(meth)
      @spec_util.respond_to?(meth)
    end
  end

  class LazyEq
    def initialize(&block)
      @block = block
    end

    def ==(other)
      called == other
    end

    def inspect
      "#<SpecUtil::LazyEq @called=#{@called.inspect}>"
    end

    private

    def called
      @called ||= @block.call
    end
  end
end
