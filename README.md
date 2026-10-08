<h1 align="center">Setup OpenLDAP</h1>

<p align="center">Start an OpenLDAP test server in your GitHub Actions workflow.</p>

<p align="center">
    <a href="https://github.com/DirectoryTree/Setup-OpenLDAP/blob/main/LICENSE"><img src="https://img.shields.io/github/license/DirectoryTree/Setup-OpenLDAP?style=flat-square" alt="License"></a>
</p>

<p align="center">
    <a href="#usage">Usage</a>
    <span> · </span>
    <a href="#inputs">Inputs</a>
    <span> · </span>
    <a href="#prepopulating-data">Prepopulating Data</a>
</p>

---

## Usage

This Docker action starts a [dinkel/openldap](https://github.com/dinkel/docker-openldap) container and publishes LDAP on port `389`. Use a Linux runner with Docker, such as `ubuntu-latest`.

The following workflow starts the server, waits for it to accept connections, and searches the directory:

```yaml
name: LDAP Tests

on: [push, pull_request]

jobs:
  ldap:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up OpenLDAP
        uses: DirectoryTree/Setup-OpenLDAP@v1.0.0
        with:
          adminPassword: secret
          domain: local.com

      - name: Install LDAP client
        run: sudo apt-get update && sudo apt-get install -y ldap-utils

      - name: Wait for OpenLDAP
        run: |
          for attempt in {1..30}; do
            if ldapwhoami -x -H ldap://127.0.0.1:389 -D 'cn=admin,dc=local,dc=com' -w secret; then
              exit 0
            fi
            sleep 1
          done
          exit 1

      - name: Search the directory
        run: ldapsearch -x -H ldap://127.0.0.1:389 -D 'cn=admin,dc=local,dc=com' -w secret -b 'dc=local,dc=com'
```

With the default inputs, subsequent steps on the runner can connect using:

| Setting | Value |
| --- | --- |
| Host | `127.0.0.1` |
| Port | `389` |
| Base DN | `dc=local,dc=com` |
| Admin DN | `cn=admin,dc=local,dc=com` |
| Admin password | `secret` |

The server starts in the background. Wait for LDAP to accept connections before running your tests, as shown above.

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `adminPassword` | `secret` | Password for the directory administrator. |
| `domain` | `local.com` | Domain used to generate the directory's base DN. |
| `prepopulate` | Empty | Path, relative to the checked-out repository, to a directory containing LDIF files to import. |

For example, `domain: example.com` creates a base DN of `dc=example,dc=com` and an administrator DN of `cn=admin,dc=example,dc=com`.

## Prepopulating Data

Check out your repository before using `prepopulate`, then provide the directory containing your LDIF fixtures:

```yaml
- uses: actions/checkout@v4

- name: Set up OpenLDAP with fixtures
  uses: DirectoryTree/Setup-OpenLDAP@v1.0.0
  with:
    adminPassword: secret
    domain: local.com
    prepopulate: tests/fixtures/ldap
```

The directory is mounted at `/etc/ldap.dist/prepopulate` in the OpenLDAP container. The image imports LDIF files in alphabetical order during its first startup. Use distinguished names that match the configured domain.

The entrypoint resolves the fixture path under `GITHUB_WORKSPACE` and starts a separate container through Docker. The resolved directory must exist on the Docker host as well; check the workspace path mapping if your LDIF files are not imported.
