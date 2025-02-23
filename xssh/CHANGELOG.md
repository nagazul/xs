# CHANGELOG

All notable changes to this project will be documented in this file.

## [3.0.0] - 2025-02-23
- **MOD**: rename assh to xssh

## [2.5.0] - 2024-10-23
- **FIX**: fix PS1 hostname for ,su
- **ADD**: custom command example via curl
- **ADD**: custom command example via sudo
- **ADD**: self propagating -R

## [2.4.1] - 2024-10-22
- **ADD**: multi-tenant XSILO sent via assh/.config-SILO.tlp instead of XDEBUG
  user
- **FIX**: fix PS1 when there is no XORIGIN
- **ADD**: added ,get support for ,su
- **ADD**: added -NOMOTD for cli

## [2.4.0] - 2024-10-21
- **ADD**: add short username and hostname(XORIGIN) support to ,su
- **MOD**: version bump
- **FIX**: fix PS1 when also using user@host
- **ADD**: display the PS1 using the assh hostname issued when connecting
  (usually smaller and more familiar)
- **FIX**: exclude wildcards from assh autocomplete
- **ADD**: minimal prompt customization
- **MOD**: Stop tracking .config.tpl
- **ADD**: conditional ssh/config limited by XDEBUG env

## [2.3.0] - 2024-10-19
- **FIX**: removed debug code
- **ADD**: added the dependency list
- **MOD**: version bump
- **ADD**: added ssh config template functionality
- **FIX**: fix .hosts functionality :)
- **ADD**: added simple .hosts functionality

## [2.2.0] - 2024-10-18
- **MOD**: move LocalHome to the end of the PATH

## [2.1.0] - 2024-10-17
- **MOD**: version bump
- **MOD**: ,got not ,copy
- **FIX**: cosmetic
- **ADD**: added ,cheat to README
- **ADD**: added ,cheat sheet command + ,ls0
- **FIX**: removed debug echos
- **ADD**: rebuilt the PATH handling to catch more combined ,su/assh cases

## [2.0.2] - 2024-10-16
- **ADD**: sudo without su
- **ADD**: add ,su <user> (default is root)
- **MOD**: moved ssh alias from .asshrc to .bashrc
- **ADD**: simple vs development setup
- **FIX**: fix typo
- **FIX**: cleanup
- **ADD**: exclude README from transfer
- **FIX**: corrected synced directories in README
- **MOD**: version bump
- **ADD**: setup instructions
- **FIX**: fix cli param handling

## [2.0.1] - 2024-10-15
- **ADD**: adding the actual ,su command
- **FIX**: added linebrake :(
- **FIX**: fix version alignment
- **ADD**: added sudo support with ,su
- **FIX**: fix version display, assh and ssh on different lines

## [2.0.0] - 2024-10-14
- **FIX**: fix timezone
- **ADD**: local version / github versionwq
- **ADD**: added dirty assh to version + develop env
- **ADD**: ControlMaster details
- **ADD**: added MasterControl by default + swaped encryption for speed of
  base64 ... encryption not needed here anyway
- **FIX**: atempt to kill rsync only if it was started in the first place
- **ADD**: also use lsof but only if the parameter is port number
- **ADD**: remove rsync daemon on exit
- **FIX**: removed -d as it blocks the execution in some situations
- **FIX**: only truncate file version if git version is not empty
- **FIX**: fix version
- **FIX**: host cleanup
- **ADD**: plain version, usable if git is not present
- **ADD**: construct version from file + git if present

## [1.1.0] - 2024-10-13
- **ADD**: added 'Key Features'
- **FIX**: README cleanup
- **ADD**: Initial

## [1.0.0] - 2024-10-12
- **ADD**: Initial commit
