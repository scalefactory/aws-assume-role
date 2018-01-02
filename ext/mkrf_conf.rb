require "rubygems"
require "rubygems/command"
require "rubygems/dependency_installer"
begin
    Gem::Command.build_args = ARGV
rescue NoMethodError # rubocop:disable Lint/HandleExceptions
end

installer = Gem::DependencyInstaller.new

begin
    case Gem::Platform.local.os
    when "linux"
        installer.install "gir_ffi-gnome_keyring", Gem::Requirement.new("~> 0.0", ">= 0.0.3")
    when "darwin"
        installer.install "ruby-keychain", Gem::Requirement.new("~> 0.3", ">= 0.3.2")
    end
rescue => e # rubocop:disable Lint/RescueWithoutErrorClass
    puts e.backtrace
    exit(1)
end

f = File.open(File.join(File.dirname(__FILE__), "Rakefile"), "w") # create dummy rakefile to indicate success
f.write("task :default\n")
f.close
