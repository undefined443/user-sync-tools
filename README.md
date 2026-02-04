# User Sync Tools

A collection of scripts for synchronizing users and SSH public keys between Linux systems.

## Scripts

| Script              | Description                                  |
| ------------------- | -------------------------------------------- |
| `export-users.sh`   | Export regular users to passwd file          |
| `import-users.sh`   | Import users from passwd file                |
| `export-pubkeys.sh` | Export SSH public keys from user directories |
| `import-pubkeys.sh` | Deploy SSH public keys to user directories   |
| `gen-ldap.sh`       | Generate LDIF for LDAP user provisioning     |

## Usage

### Sync Users

1. Export users on source node:

   ```sh
   ./export-users.sh
   ```

2. Copy `passwd` file to target node, then import:

   ```sh
   ./import-users.sh
   ```

### Sync SSH Keys

1. Export public keys on source node:

   ```sh
   ./export-pubkeys.sh
   ```

2. Copy `pubkeys/` directory to target node, then import:

   ```sh
   ./import-pubkeys.sh
   ```

### Generate LDIF for LDAP

Generate LDIF file from exported users and keys:

```sh
./gen-ldap.sh "dc=example,dc=com"
```

With custom paths:

```sh
./gen-ldap.sh "dc=example,dc=com" ./passwd ./pubkeys ./users.ldif
```

Import into OpenLDAP:

```sh
ldapadd -x -D "cn=admin,dc=example,dc=com" -W -f users.ldif
```

## Requirements

- Bash
- sudo privileges (for import scripts)
- OpenLDAP with openssh-lpk schema (for gen-ldap.sh sshPublicKey support)
