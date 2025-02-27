# XSSH - Xtended SSH
**Automated, Self-Propagating Shell Enhancements for Every SSH Session**

XSSH extends your local shell environment to remote SSH sessions, applying
your local scripts and shell configs without the need for remote modifications.

## Key Features

- **Local Environment Replication**  
  Bring your `.bashrc`, and other local shell configs and scripts into
  remote sessions automatically. Enjoy the familiarity of your local setup,
  no matter which server you connect to.

- **Zero Remote Changes**  
  Keep remote servers clean and secure. XSSH doesn’t modify remote
  configurations or scripts, making it lightweight and unobtrusive.

- **Zero or Easy Setup**  
  XSSH is designed for simplicity. Configuration files are straightforward,
  allowing you to set up quickly and with minimal effort.

- **100% bash**  
  Written entirely in Bash for maximum portability across different systems
  and terminals.


## Usage

### Simple Setup

For a simple setup you could run this in your terminal:
```
git clone ... ~/.xssh.d
```

Add this to your `.bashrc`:
```
export LH="${LH:-$(eval echo ${HOME}/.xssh.d)}"
. "$LH/.xshrc" || echo "[xssh] file not found"
```

### Development Setup
For development you could add this instead:
```
export LH="${LH:-$(eval echo ${HOME}/.xssh.d)}"
. "$LH/.xsshrc" || echo "[xssh] file not found"

export XD=1                         # develop flag
export LU="${LU:-$(eval echo ~)}"
XF=$(ls -d $LU/.xssh*/.xsshrc 2>/dev/null | sort | tail -n 1)
[[ -f $XF ]] && . "$XF" || true
```

This will load the last alpabetically ordered `~/.xssh*/.xsshrc`.  
You probably don't need more than one but it's sometimes usefull.  
The develop flag now only refreshes XSSH version on PROMPT_COMMAND, for now.
  
**Automatic Transfer to Server**  
   When you connect to a server, the contents of `~/.xssh*` are automatically  
   copied, including the XSSH script, allowing you to use XSSH directly from  
   that server to other servers.  

### Using XSSH
XSSH behaves just like SSH but with added convenience and functionality:  

- **Standard Connection**  
  Connect to a server as you would with SSH:  
  `xssh user@host`

- **Cascading Connections**  
  Once connected, you can use XSSH from the server to connect to another server:  
  `xssh user@host2`

- **Quick Access to Commands**  
  Any executable scripts in the `bin` subdirectory are automatically available.  
  I use filenames prefixed by `,` for easy lookup with `,<tab><tab>`  

    `,help`  
    `,cheat`  

- **Reverse Port Forwarding with Copying**  
  Using `xssh -R host` sets up reverse port forwarding, enabling you to copy  
  files directly from the connected servers. You only use -R when you first  
  start xssh and the ,copy command will be available from all hosts.  

    `,get <path>`

- **ControlMaster by Default**  
  XSSH enables ControlMaster by default for faster multi-server connections.  
  Use `-M0` to disable or `-MX` to close the ControlMaster socket.  
  This ensures speed and control without using lengthy CLI parameters.  

- **sudo support**  
  You can keep using your XSSH config even after you `sudo su`.  
  Just use `,su` and all the configurations and scripts are available to you.  

- **ssh config templates**  
  `.config.tpl` is a template that includes `.ssh/config` and then allows you  
  to customize the values you might need expanding the environment variables.  
  The expanded template is saved to `.config` and used by the xssh command.  

  The config will not propagate on servers where the user you connect as is 
  equal to `$XDEBUG` as defined in your environment (precursor to multi-tenant).

- **No login messages**  
  By default, you get no motd messages. This behavior is controlled by the  
  `.hushlogin` and `.hushxssh` files. Removing these files will show you the  
  default login messages or a customized version.  

  This is very useful in an enterprise setting where you have various servers  
  that give you information you can't really use for anything.  

  The customized version you get by deleting `.hushxssh` allows you to better see  
  the server's status and to also get a unified message that you can customize  
  as you see fit.  

- **Endless Customizations**

You can customize the `.sshrc` for generic usage, add custom functionality  
for each server you log in to, or for groups of servers.  

`~/.xssh.d` is just the main directory... all `~/.xssh*` directories get  
loaded in alphabetical order and combined on the server you `xssh` into. This  
way, you can have group settings while also allowing for customization by  
overwriting with custom functionality. This structure helps you maintain  
group settings while keeping the flexibility to personalize your own,  
ensuring that group configurations are still respected, but individual  
preferences take precedence.  

**100% Compatibility, 100% Code is Bash**

All code is Bash, so it can execute without problems on any Linux server. Here  
is the list of external dependencies: `bash`, `cat`, `eval`, `echo`, `find`,  
`wc`, `kill`, `mktemp`, `printf`, `command`, `trap`, `read`, `unset`, `awk`,  
`shuf`, `openssl`, `ssh`, `tar`, `rsync`, `envsubst`. These are core external tools  
and utilities widely present on Linux servers.  

The code is not easy to understand completely, even if it’s only ~50 lines of  
Bash, but it's not that difficult to review and ensure it does what it says.  

- **Extensibility**  
  These usage examples are just simplified use cases but there's a lot more  
  that can be done, especially in the enterprise realm:  
  - logging input/output of all the xssh sessions
  - yubikey plugged into your laptop can be used on the server
  - plugin system for complex functionality
  - encryption is baked in and easily extended to other uses
  - group/team features, pastebin sharing
  - server health and notifications
  - intrusion detection
  - safe static binary execution from a trusted location
  - ... all with on-the-fly automatic setup and no modifications on the servers

XSSH extends SSH’s functionality without altering the familiar workflow,  
streamlining multi-server connections and file operations being especially  
useful for workflows with jump hosts, bastion servers, and multiple users  
using the same accounts on the servers.  

You get your personal configuration and scripts automatically even if it's the  
first time you logged into that server. All the configurations are temporary  
and get removed automatically when the connection breaks or you log out.  

