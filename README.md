Nim Version Manager
===================

## 0tt0matic installation
```curl https://raw.githubusercontent.com/ekarlso/nimvm/master/scripts/install.sh | sh```

## Manual installation

```
mkdir -p ~/.nimvm/bin
wget -o ~/.nimvm/bin/nim-vm https://raw.githubusercontent.com/ekarlso/nimvm/master/bin/nim-vm
chmod +x ~/.nimvm/bin/nim-vm
```

Then add `~/.nimvm/bin` to your PATH such that it is the source for your `nim` invocations.

## Examples of usage

```
nim-vm install v0.10.2 # installs latest release
nim-vm install devel   # installs current version in development
nim-vm install v0.9.6  # installs the old verision
nim-vm active          # shows which version is used
nim-vm list            # lists all installed versions
nim-vm use v0.10.2     # switches to latest release
nim-vm use devel       # switches to the development version
nim-vm update          # updates the development version from development repo
```

You can also set the env variable `$NIM_REPO_LOCATION` which then acts as version `repo`

```
nim-vm use repo        # uses "your own" repo
nim-vm rebuild repo    # rebuilds your own repo
nim-vm use devel       # switches to the devel repo
nim-vm use repo        # swichtes back to your personal repo
```

### Modifications

The script does define some common -d flags to the koch build. You may want to change these for your needs
