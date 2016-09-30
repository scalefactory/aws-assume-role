#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../lib/', __FILE__) 

require 'aws_assume_role'

#profile = AWSAssumeRole::Profile::Basic.new()
#puts profile.sts_client.get_caller_identity.inspect
#puts profile.session().inspect

test_profiles_yaml = <<EOF
---
default:
    set_environment: false
    # credentials come from .aws/credentials or environment
    mfa_arn: arn:aws:iam::754021874844:mfa/jtopper

mgmt:
    set_environment: true
    type: assume_role
    role_arn: arn:aws:iam::339253004131:role/TerraformUser 

test:
    set_environment: true
    type: assume_role
    role_arn: arn:aws:iam::542043528869:role/TerraformUser 

tf_test:
    type: list
    list:
     - name:       test
       env_prefix: TEST_
     - name:       mgmt
       env_prefix: MGMT_

EOF

AWSAssumeRole::Profile.log.level = Logger::WARN

AWSAssumeRole::Profile.parse_config(test_profiles_yaml)

p = AWSAssumeRole::Profile.get_by_name('tf_test')
p.use

system('env | grep "AWS" | sort')

foo = AWSAssumeRole::Profile.get_by_name('mgmt')
puts foo.role_credentials.to_json
