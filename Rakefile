# frozen_string_literal: true

require "aws_assume_role/version"
require "bundler/gem_tasks"
require "yaml"

task default: :test

begin
    require "rspec/core/rake_task"
    RSpec::Core::RakeTask.new(:spec)
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

begin
    require "rubocop/rake_task"
    RuboCop::RakeTask.new(:rubocop)
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

task test: %i[no_pry rubocop spec]

DISTRIBUTIONS = [
    "universal-linux",
    "universal-freebsd",
    "universal-darwin",
    "universal-openbsd",
].freeze

CREDENTIALS = {
    rubygems_api_key: ENV.fetch("API_KEY", "null"),
}.freeze

task :setup_credentials do
    FileUtils.mkdir_p(File.expand_path("~/.gem"))
    File.write(File.expand_path("~/.gem/credentials"), CREDENTIALS.to_yaml)
end

task publish: %i[build build_generic] do
    Dir.glob("#{File.dirname(__FILE__)}/pkg/*.gem") do |g|
        sh "gem push #{g}"
    end
end

namespace :build_arch do
    DISTRIBUTIONS.each do |arch|
        desc "build binary gem for #{arch}"
        task arch do
            sh "cd #{File.dirname(__FILE__)} && PLATFORM=#{arch} gem build aws_assume_role.gemspec"
            FileUtils.mkdir_p(File.join(File.dirname(__FILE__), "pkg"))
            sh "cd #{File.dirname(__FILE__)} && mv *.gem pkg/"
        end
    end
end

task build: DISTRIBUTIONS.map { |d| "build_arch:#{d}" }

task :build_generic do
    sh "cd #{File.dirname(__FILE__)} && GENERIC_GEM=true gem build aws_assume_role.gemspec"
    FileUtils.mkdir_p(File.join(File.dirname(__FILE__), "pkg"))
    sh "cd #{File.dirname(__FILE__)} && mv *.gem pkg/"
end

task :no_pry do
    files = Dir.glob("**/**").reject { |x| x.match(/^spec|Gemfile|coverage|\.gemspec$|Rakefile|vendor/) || File.directory?(x) }
    files.each do |file|
        raise "Use of pry found in #{file}." if File.read(file) =~ /"pry"/
    end
end
