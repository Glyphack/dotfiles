## Dotfiles

My personal dotfiles to install and configure software I use.

## Installation

On a new Mac:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Glyphack/dotfiles/master/scripts/install.sh)"
```

On a current Mac:

```bash
./scripts/setup.sh
```

## Secrets

I store secrets in apple key chain.

```
security add-generic-password -a "myaccount" -s "myservice" -w "mysecret"
```
