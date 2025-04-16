# frozen_string_literal: true

require 'English'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec:multi rubocop]

module Tasks
  class << self
    include Rake::DSL

    def install
      install_release_if
      install_spec_multi
    end

    private

    def install_release_if # rubocop:disable Metrics/MethodLength
      namespace :release do
        desc 'release if current version is later than last published version'
        task if: :default do
          release_if
        end
      end
    end

    def release_if
      assert_correct_branch!
      if current_version > published_version
        assert_ci!
        # from bundler, asserts working directory is clean
        Rake::Task['release'].invoke
      end
      assert_version_sane!
    end

    def install_spec_multi
      namespace :spec do
        task :multi do
          spec_multi
        end
      end
    end

    def spec_multi
      ['7', '8'].each do |major_version|
        sh('bundle', 'remove', 'activerecord')
      end
    end

    def fetch_latest_version(gem, version = nil)
      all_version_arg = version && "--all --version '#{version}'" || ''
      raw = shr("gem search --remote #{all_version_arg} --exact #{gem}")
      versions = raw.match(/\((.+)\)/)[1].split(', ').map { |v| Gem::Version.new(v) }
      versions.sort.last
    end

    def published_version
      @published_version ||= build_published_version
    end

    def build_published_version
      raw = shr('gem search --remote --exact better_batch-active_record')
      Gem::Version.new(raw.split('(').last.sub(')', ''))
    end

    def current_version
      @current_version ||= Gem::Version.new(BetterBatch::ActiveRecord::VERSION)
    end

    def assert_version_sane!
      return unless current_version < published_version

      raise "BetterBatch::VERSION (#{current_version}) " \
            "is less than the current published (#{published_version}). " \
            'Was it edited incorrectly?'
    end

    def current_branch
      @current_branch ||= shr('git rev-parse --abbrev-ref HEAD').chomp
    end

    def default_branch
      @default_branch ||= shr('git remote show origin').match(/HEAD branch: (\S+)$/)[1]
    end

    def assert_correct_branch!
      return unless current_branch != default_branch

      raise "On branch (#{current_branch}) instead of default #{default_branch}."
    end

    def assert_ci!
      raise 'Not in CI.' unless ENV['CI'] == 'true'
    end

    def shr(cmd)
      puts cmd
      result = `#{cmd}`
      raise cmd unless $CHILD_STATUS == 0

      result
    end
  end
end

Tasks.install
