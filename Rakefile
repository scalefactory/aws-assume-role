# frozen_string_literal: true

require "bundler/gem_tasks"
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

task :test => %i[no_pry rubocop spec] # rubocop:disable Style/HashSyntax

task :no_pry do
    files = Dir.glob("**/**").reject { |x| x.match(/^spec|Gemfile|coverage|\.gemspec$|Rakefile/) || File.directory?(x) }
    files.each do |file|
        raise "Use of pry found in #{file}." if File.read(file) =~ /"pry"/
    end
end
