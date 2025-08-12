git config core.sshCommand "ssh -o IdentitiesOnly=yes -i ~/.ssh/id_nagazul"

.git/config
[core]
    ...
    sshCommand = ssh -o IdentitiesOnly=yes -i ~/.ssh/id_nagazul

# ----------

git config --unset core.sshCommand

~/.ssh/config

Host github.com-nagazul
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_nagazul
    IdentitiesOnly yes

git remote set-url origin git@github.com-nagazul:nagazul/xs.git
