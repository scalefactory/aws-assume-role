#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path("../lib/", __FILE__)

require "aws_assume_role"

test_profiles_yaml = <<EOF
---
default:
    set_environment: false
    # credentials come from .aws/credentials or environment

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

AWSAssumeRole::Profile.logger.level = Logger::DEBUG
AWSAssumeRole::Profile.parse_config(test_profiles_yaml)

p = AWSAssumeRole::Profile.get_by_name("tf_test")
p.use

system('env | grep "AWS" | sort')
