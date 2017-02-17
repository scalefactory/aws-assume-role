aws-assume-role
---------------

aws-assume-role is a utility intended for developer and operator environments
who need to use 2FA and role assumption to access AWS services.

aws-assume-role can store both AWS access keys and ephemeral session tokens in
OS credential vaults - Keychain on OSX and Seahorse on Gnome.

Why?
---

This keeps your credentials safe in the keystore, and exist as
environment variables for the duration and context of the executing command.
This helps prevent credential leaking and theft, and means they aren't stored on
disk as unencrypted files.

It allows easy credential management and role assumption with a 2FA/MFA device.

For more information on role assumption, see the AWS documentation.

Requirements
------------
*   Ruby ≥ 2.1
*   OS X KeyChain or GNOME Keyring

Install
-------

```sh
gem install aws_assume_role
```

### Platform notes

Gnome Keyring uses the [GirFFI](https://github.com/mvz/gir_ffi) bindings, which
require introspection bindings as well as Gnone Keyring, by installing one of the following packages:

``` sh
# Debian/Ubuntu
apt-get install gnome-keyring libgirepository1.0-dev

# Fedora
dnf install gobject-introspection-devel

# CentOS
yum install gobject-introspection-devel
```
Setup
-----
aws-assume-role works best if you also store permanent credentials in your keystore:

``` sh
> aws-assume-role configure
Enter the profile name to save into configuration
company-sso
Enter the AWS region you would like to default to:
eu-west-1
Enter the AWS Access Key ID to use for this profile:
1234567890010
Enter the AWS Secret Access Key to use for this profile:
abcdefghijklmnopqrstuvwzyx1
Profile `company-sso` saved to '/home/growthsmith/.aws/config'
```

### Configuring roles
Now that you've set up permanent credentials in your OS credential store, you can now
set up a role that you will assume in every day use:

``` sh
> aws-assume-role configure role -p company-dev --source-profile company-sso  \
--role-arn=arn:aws:iam::000000000001:role/ViewEC2 --role-session-name=growthsmith \
--mfa-serial automatic
```
`--mfa-serial automatic` will look up your default attached multi-factor device, but you can specify a specific ARN.

More options are available in the application help.
Use `> aws-assume-role --help ` for help at any time.

Running applications
--------------------

You can run another application using

``` sh
aws-assume-role run -p company-dev -- aws ec2 describe-instances --query \
"Reservations[*].Instances[*].PrivateIpAddress" --output=text
10.254.4.20
10.254.4.15
10.254.0.10
10.254.4.5
```

Because we've enabled MFA, aws-assume-role will ask for your MFA token:
```
Please provide an MFA token
000000
```


Deleting a profile
------------------
If a set of credentials key needs revoking, or the profile isn't relevant anymore:
``` sh
> aws-assume-role delete -p company-sso
Please type the name of the profile, i.e. company-sso , to continue deletion.
company-sso
Profile company-sso deleted
```

Migrating AWS CLI profiles
------------------
It's better to revoke the existing keys and generate new ones. We try to overwrite the plaintext configuration
file with random data, but this does not take care of ~/.aws/credentials and does not account for SSD wear
levelling or copy-on-write snapshots.
```
aws-assume-role migrate -p company-sso
Profile 'company-sso' migrated to keyring.
```

Exporting environment variables
-------------------------------
You can use a session token in your shell any supported application without using
`aws-assume-role`.

You can also remove environment variables after finishing using the reset command.

#### Bourne Shell and friends
``` sh
>  eval `./bin/aws-assume-role environment set -p company-dev`
>  eval `./bin/aws-assume-role environment reset`
```

#### fish
``` fish
> set creds (bin/aws-assume-role environment set -s fish -p company-dev); eval $creds; set -e creds
> set creds (bin/aws-assume-role environment reset -s fish); eval $creds; set -e creds
```

#### PowerShell
``` powershell
> aws-assume-role environment set -s powershell -p company-dev | invoke-expression
> aws-assume-role environment reset -s powershell | invoke-expression
```

Launch the AWS console
---------------------
Given that `aws-assume-role` has knowledge of your role ARNs via AWS CLI profiles, you can
get to the AWS console for that role/account using

``` sh
> aws-assume-role console -p company-sso
```

`aws-assume-role` will first attempt to log in and get a federated UI link, and
otherwise fall back to the "switch role" page.

Using inside Ruby
-----------------
To get a set of credentials via the OS credential store, or using console-based MFA, use
the following:
```
require "aws_assume_role"

AwsAssumeRole::DefaultProvider.new(options).resolve
```
where options is a hash with the following symbol keys:
*   `access_key_id`
*   `secret_access_key`
*   `session_token`
*   `persist_session`
*   `duration_seconds`
*   `role_arn`
*   `role_session_name`
*   `serial_number`
*   `source_profile`
*   `region`

`aws_assume_role` resolves credentials in almost the same way as the AWS SDK, i.e.:

```no-highlight
static credentials ⟶ environment variables ⟶ configured profiles role ⟶ assumption (look up source profile and check for 2FA)
```

Any of the above may get chained to do MFA or role assumption, or both,
in the following order:

```no-highlight
second factor ⟶  ecs/instance profile
```

These are the same as the AWS SDK equivalents whereever possible. The command line help will give an explanation of the rest.

### Monkeypatching the AWS SDK
You can also override the standard AWS SDK credential resolution system by including the following:
```
require "aws_assume_role/core_ext/aws-sdk/credential_provider_chain"
```

Using any standard AWS SDK for Ruby v2 client will then use aws_assume_role for credential resolution.


Please do not use this in production systems.

Other keyring backends
----------------------
`aws-assume-role` uses the Keyring gem for secure secret storage. By default, this will use OS X keycain
or GNOME Keyring. To load alternatives, set the following environment variables:

*   `AWS_ASSUME_ROLE_KEYRING_BACKEND`: Which backend to use, as the name of the Ruby class.
*   `AWS_ASSUME_ROLE_KEYRING_PLUGIN` : Name of a gem to load.

These are also available in Ruby as the `AwsAssumeRole.Config.backend_plugin` and
`AwsAssumeRole.Config.backend_plugin` attributes.

License
-------

This library and program is distributed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)

```no-highlight
Copyright 2017. The Scale Factory Ltd. All Rights Reserved.
Portions Copyright 2013. Amazon Web Services, Inc. All Rights Reserved.

licensed under the apache license, version 2.0 (the "license");
you may not use this file except in compliance with the license.
you may obtain a copy of the license at

    http://www.apache.org/licenses/license-2.0

unless required by applicable law or agreed to in writing, software
distributed under the license is distributed on an "as is" basis,
without warranties or conditions of any kind, either express or implied.
see the license for the specific language governing permissions and
limitations under the license.
