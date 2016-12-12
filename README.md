# aws-assume-role
[![Code Climate](https://codeclimate.com/github/scalefactory/aws-assume-role/badges/gpa.svg)](https://codeclimate.com/github/scalefactory/aws-assume-role)

This will get role credentials for you, managing 2FA devices, and set those
credentials in environment variables then execute a provided command. It stores
the fetched credentials in Gnome Keyring or OSX Keychain so they are not
readable from disk.

### Why?

This keeps your credentials safe in the keystore, and they are set as
environment variables for the duration and context of the executing command.
This helps prevent credential leaking and theft, and means they aren't stored on
disk as unencrypted files.

It allows easy credential management and roll assumption with a 2FA/MFA device.

For security and account management purposes we don't want to be managing users
in multiple accounts, just centrally then allowing them to assume roles in
other accounts.

###

Assumptions:

- You have a parent/master account which you authenticate against with a 2FA
  device.
- You then assume a role in another account.

This is easy to achieve in a web console, but you probably want to use tools
like Terraform of AWS Cli. This makes using those tools easy, without having to
constantly fetch and manage credentials for assumed roles, or provide
users/access keys for each account.

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




## How to use?

You need a key and secret for each `basic` role (a `parent`). You can set this
in the environment variable or in the `~/.aws/credentials` file.

It is recommended that you set this in the environment variable, the first time
aws-assume-role runs it will place these values in the keystore so they are
safe.

### Add the basic/profile credentials to keystore

You can add the credentials that the system will use to assume roles to the
keystore. This is the recommended way of using `aws-assume-role`.

To add(or update) credentials use:

```shell
$ aws-assume-role --profile scalefactory --add
Enter your AWS_ACCESS_KEY_ID: 
1234567890010
Enter your AWS_SECRET_ACCESS_KEY: 
abcdefghijklmnopqrstuvwzyx1
Enter a AWS Region:
eu-west-1

```

### In Environment variable

```
export AWS_ACCESS_KEY_ID=1234567890010
export AWS_SECRET_ACCESS_KEY=abcdefghijklmnopqrstuvwzyx1
export AWS_DEFAULT_REGION=eu-west-1
```

Then run the `aws-assume-role` command.

### in credentials file

I have the following entry in `~/.aws/credentials`:

```
[sf_sso]
aws_access_key_id = 1234567890010
aws_secret_access_key = abcdefghijklmnopqrstuvwzyx1
region = eu-west-1
```

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


## Deleting keystore values

Maybe you have a new keypair?

```
aws-assume-role --profile yy_mgmt --delete
aws-assume-role --profile scalefactory --delete
```
