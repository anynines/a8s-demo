# Demo Bash Script

This script performs a very simple application use case from the cold deployment to simulating a data loss as well as recovering from it.

The script covers:

* creates a PostgreSQL service instance
* loads data from a .sql file
* executes an SQL command using the `--sql` option
* creates a service binding
* installs a simple PG demo app
* deletes all data from the service instance
* restors data from the service instance
* reads data from the service instance

## Usage

1. Create a cluster with an `a8s` stack: `a9s create cluster a8s`
2. Run the script: `bash demo.bash`