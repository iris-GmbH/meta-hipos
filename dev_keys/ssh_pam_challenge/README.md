# Keypair for SSH PAM challenge

Private key is used to sign the ssh challenge, public key is installed on the device to check the entered response.

Create keypair (currently, only ED25519 is supported by the pam module):

```
# to generate private key
$ openssl genpkey -algorithm ed25519 -out ssh_pam_snakeoil.key

# to generate public key
$ openssl pkey -in ssh_pam_snakeoil.key -pubout -out ssh_pam_snakeoil.pub
```

## Signing challenges

To sign a SSH PAM challenge, use the provided script in this directory:

```
echo "UEFN..." | ./sign_pam_challenge.sh
```

Copy the whole output (`vault:v1:...`) into the SSH login prompt
