# aws-assume-role

This will get role credentials for you, managing 2FA devices, and set those
credentials in environments. It stores the fetched credentials in Gnome Keyring
or OSX Keychain so they are not readable from disk.

## Install

`gem install aws_assume_role`

### Platform notes

Gnome Keyring uses the [GirFFI](https://github.com/mvz/gir_ffi) bindings, which
requires the introspection bindings to be installed (as well as gnome-keyring).
`apt-get install gnome-keyring libgirepository1.0-dev` for Debian/Ubuntu.

## Config file

Create a config file, the default is `~/.aws/assume.yaml`

```yaml
---
default:
    set_environment: false
    # credentials come from .aws/credentials default profile or environment

scalefactory:
    # if this profile is passed don't set the environment credentials
    set_environment: false
    # load credentials from sf_sso profile in .aws/credentials
    profile: sf_sso


# These use the scalefactory profile above
xx_mgmt:
    parent: scalefactory
    set_environment: true
    type: assume_role
    region: eu-west-1
    role_arn: arn:aws:iam::123456789012:role/RoleNameHere

xx_test:
    parent: scalefactory
    set_environment: true
    type: assume_role
    role_arn: arn:aws:iam::123456789012:role/RoleNameHere

xx:
    type: list
    set_environment: true
    list:
     - name:       xx_test
       env_prefix: TEST_
     - name:       xx_mgmt
       env_prefix: MGMT_


# These use the default above
yy_mgmt:
   set_environment: true
   type: assume_role
   role_arn: arn:aws:iam::123456789012:role/RoleNameHere

yy_test:
   set_environment: true
   type: assume_role
   role_arn: arn:aws:iam::123456789012:role/RoleNameHere

xx:
   type: list
   set_environment: true
   list:
    - name:       xx_test
      env_prefix: TEST_
    - name:       xx_mgmt
      env_prefix: MGMT_


```

I have the following entry in `~/.aws/credentials`:

```
[sf_sso]
aws_access_key_id = 1234567890010
aws_secret_access_key = abcdefghijklmnopqrstuvwzyx1
region = eu-west-1
```


## How to use?

### In Environment variable

### in credentials file

This is protected by a MFA/2FA device.


### Environment Variables Set

If `region` is defined for an `assume_role` type the environment variable
`AWS_DEFAULT_REGION` will be set with that value, otherwise it will be left
blank.

`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` will all
be set.

If a type of `list` is called the environment variables will all be set with the
provided prefix, e.g.

```
MGMT_AWS_ACCESS_KEY_ID=122343534535435435
MGMT_AWS_DEFAULT_REGION=eu-west-1
MGMT_AWS_SECRET_ACCESS_KEY=+4324234234235454353535353535
MGMT_AWS_SESSION_TOKEN=F353453535345345345345345353534
TEST_AWS_ACCESS_KEY_ID=53454353453453453534
TEST_AWS_SECRET_ACCESS_KEY=3534534534534534534534
TEST_AWS_SESSION_TOKEN=5435345353453
```

If you use the `-v` or `--verbose` flag it will print out any AWS environment
variables set at the end of the action.

### Calling another application

You can call another application by passing a bare double dash followed by the
target command.

```
aws-assume-role --profile yy_mgmt -- aws ec2 describe-instances --query "Reservations[*].Instances[*].PrivateIpAddress" --output=text 
10.254.4.20
10.254.4.15
10.254.0.10
10.254.4.5
```
