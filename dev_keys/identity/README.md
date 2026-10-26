# How to create pki with ca/crt/key?

## Requirements
- Package: easy-rsa

## Create PKI

Use `--algo=ec` to generate ECC key material, easy-rsa defaults to `secp384r1`, though you can set it via `--curve=`.
You can also configure these values in `./certs/pki/vars`

```bash
$ export EASYRSA=$(pwd)/certs
$ easyrsa --algo=ec init-pki
$ easyrsa --algo=ec --days=7300 build-ca
# Enter New CA Key Passphrase: hallo00 [Enter]
# Re-Enter New CA Key Passphrase: hallo00 [Enter]
# Common Name: [Enter]
$ easyrsa --algo=ec --subject-alt-name="DNS:hydra-DEV,IP.1:172.16.0.10,IP.2:10.42.0.70" gen-req hydra nopass
# Common Name: [Enter]
$ easyrsa --days=7300 --subject-alt-name="DNS:hydra-DEV,IP.1:172.16.0.10,IP.2:10.42.0.70" sign-req server hydra
$ ln -s certs/pki/ca.crt ca_identity_snakeoil.crt
$ ln -s certs/pki/issued/hydra.crt hydra_identity_snakeoil.crt
$ ln -s certs/pki/private/hydra.key hydra_identity_snakeoil.key

$ tree certs
certs
└── pki
    ├── ca.crt                                    <-- ca_identity_snakeoil.crt
    ├── ...
    ├── issued
    │   └── hydra.crt                             <-- hydra_identity_snakeoil.crt
    ├── openssl-easyrsa.cnf
    ├── private
    │   ├── ca.key
    │   └── hydra.key                             <-- hydra_identity_snakeoil.key
    ├── reqs
    │   └── hydra.req
    ├── revoked
    │   ├── certs_by_serial
    │   ├── private_by_serial
    │   └── reqs_by_serial
    ├── safessl-easyrsa.cnf
    ├── serial
    └── serial.old
```


