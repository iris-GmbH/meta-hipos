# CA keypair for client certificate based SSH

Private key is used to sign the users ssh key, public key is installed on the device to validate client certificates.

Create CA:

```
$ ssh-keygen -q -t ed25519 -f ./ca_ssh_user_snakeoil -N "" -C ""
```

## Sign user / local ssh keys with this CA

First generate your own ssh key if you don't already have a keypair

```
ssh-keygen -q -t ed25519 -f ~/.ssh/my_hydra_client_key
```

Then, use the snakeoil CA private key to sign your key

```
# Read principal from target
root@localhost:~# cat /etc/ssh/hydra-principals/root ; echo
hydra:v1:account:root:group:rma-devices

# Sign key with this principal (replace -1h/+12h with desired validity)
ssh-keygen -q -s ./ca_ssh_user_snakeoil -I "hydra" -n "hydra:v1:account:root:group:rma-devices" -V "-1h:+12h" ~/.ssh/my_hydra_client_key.pub

# If ssh-keygen complains about permission:
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# ...then set mode 0600 to the private key file (git does not track group/other permissions)
chmod 0600 ./ca_ssh_user_snakeoil
```

Modern OpenSSH will automatically use the resulting `my_hydra_client_key-cert.pub` when you select the `my_hydra_client_key` identity with `-i`. So, to connect, simply run:

```
ssh root@172.16.XX.XX -i ~/.ssh/my_hydra_client_key

# to explicitly present the cert to the server, add it via a second -i
ssh root@172.16.XX.XX -i ~/.ssh/my_hydra_client_key -i ~/.ssh/my_hydra_client_key-cert.pub
```
