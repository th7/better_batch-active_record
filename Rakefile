# frozen_string_literal: true

require 'English'
require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
RuboCop::RakeTask.new

require_relative 'config/application'
Rails.application.load_tasks

task default: %i[spec rubocop]

module Tasks
  class << self
    include Rake::DSL

    def install
      install_release_this
      install_update_gemfiles
    end

    private

    def install_release_this
      namespace :release do
        desc 'release if current version is later than last published version'
        task :this do
          release_this
        end
      end
    end

    def release_this
      assert_correct_branch!
      if current_version > published_version
        assert_ci!
        # from bundler, asserts working directory is clean
        Rake::Task['release'].invoke
      end
      assert_version_sane!
    end

    def install_update_gemfiles
      desc 'Update files in gemfiles/ to match Gemfile + variations to test and to use latest variations to test'
      task :update_gemfiles do
        update_gemfiles
      end
    end

    def update_gemfiles
      update_gemfile('Gemfile')
      %w[7 8].each do |major_version|
        gemfile = "gemfiles/activerecord-#{major_version}.Gemfile"
        File.open('Gemfile', 'r') do |f1|
          File.open(gemfile, 'w') do |f2|
            copy_gemfile(f1, f2, major_version)
          end
        end
        update_gemfile(gemfile)
      end
    end

    def update_gemfile(gemfile)
      sh({ 'BUNDLE_GEMFILE' => gemfile }, 'bundle', 'lock', '--add-platform=x86_64-linux')
      sh({ 'BUNDLE_GEMFILE' => gemfile }, 'bundle', 'update', 'activerecord')
      sh({ 'BUNDLE_GEMFILE' => gemfile }, 'bundle', 'update', 'better_batch')
      sh({ 'BUNDLE_GEMFILE' => gemfile }, 'bundle', 'install')
    end

    def copy_gemfile(original, copy, major_version)
      original.each_line do |line|
        if line.start_with?('gemspec')
          copy.write("gemspec path: '..'\n\n")
        else
          copy.write(line)
        end
      end
      copy.write("\ngem 'activerecord', '~> #{major_version}'\n")
    end

    def fetch_latest_version(gem, version = nil)
      all_version_arg = (version && "--all --version '#{version}'") || ''
      raw = shr("gem search --remote #{all_version_arg} --exact #{gem}")
      versions = raw.match(/\((.+)\)/)[1].split(', ').map { |v| Gem::Version.new(v) }
      versions.max
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
