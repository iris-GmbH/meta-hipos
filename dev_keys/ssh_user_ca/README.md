# CA keypair for client certificate based SSH

Private key is used to sign the users ssh key, public key is installed on the device to validate client certificates.

Create CA:

```
$ ssh-keygen -q -t ed25519 -f ./ca_ssh_user_snakeoil -N "" -C ""
```