# colonize-example-project
An example project using **[Colonize](https://github.com/craigmonson/colonize)**

This project intends to represent an example of an Enterprise architecture that consists of:

- VPC environments (i.e. nonprod & prod)
- Application environments (i.e. dev,test,stage,prod)
- Autoscaling EC2 instances across multi-az
- Aurora Database cluster across multi-az
- All subnetting, AZs, security ingress/egress, and other environmental information are variablized, so no base TF code needs modifications between environment


# Usage
Before running a command, make sure that you have your `AWS_ACCESS_KEY_ID` & 
`AWS_SECRET_ACCESS_KEY`, or `AWS_PROFILE` environment variable(s) set, for authentication.

## Building the VPC

From here, we want to build our VPC(s) up. This is done separately from the rest of the build, 
since we will use a different environment naming scheme. The `nonprod` VPC would hold the `dev`,
`test`, & `stage` type environments, for example

    $ cd vpc
    $ colonize plan --skip_remote --environment nonprod
    $ colonize apply --skip_remote --remote_state_after_apply

> **Note:** You may need to modify the bucket names for your own use-case. You would do this in 
the **vpc/main.tf**, **env/remote_setup.sh**, **app/env/vpc.tf**, & **app/env/security_group.tf**

Since the VPC template is creating the S3 bucket that stores the remote statefiles, we must use
the `skip_remote` flag. This instructs Colonize to not to pull the remote statefile, as it would
clearly faile because the bucket does not exist. Since we do want remote state management, when
we run apply, the `remote_state_after_apply` command it also passed in. This instructs Colonize to
update the remote state after the apply has run, thus storing the statefile in the S3 bucket.

After the first run, we should not need the `skip_remote` or `remote_state_after_apply` commands 
anymore.

## Building the Application

With the VPC built, we can start building our application. Due to [this feature request](https://github.com/craigmonson/colonize/issues/4) 
we **cannot** currently build the branch as a whole, or else we could simply run the following 
commands from the project root:

    $ colonize plan --environment dev
    $ colonize apply

This would crawl the directory structure based on the `make_order.txt` files and build each leaf.
Until this feature is complete, we will have to run each leaf manually. Start from the project
root:

    $ cd app/security_groups
    $ colonize plan --environment dev
    $ colonize apply

    $ cd ../database
    $ colonize plan --environment dev
    $ colonize apply

    $ cd ../instances
    $ colonize plan --environment dev
    $ colonize apply


> **NOTE**: Some of the `apply` commands could take some time and do not currently indicate 
status in real time, see **[feature request](https://github.com/craigmonson/colonize/issues/24)**.
> Even though it looks like the process could be hanging, it is excuting normally. This is mainly
> noticable with the database instances that can take over 5m each to launch


