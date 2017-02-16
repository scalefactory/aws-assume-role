require_relative "includes"

class AwsAssumeRole::Cli::Actions::ListProfiles < AwsAssumeRole::Cli::Actions::AbstractAction
    CommandSchema = proc do
    end

    def act_on(_options)
        AwsAssumeRole.shared_config.profiles.each { |p| puts p }
    end
end
