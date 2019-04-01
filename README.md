# dotman
Set of bash scripts to manage dotfiles and custom ~/bin scripts
 
## Installation
- Fork this repository into your github/gitlab/other account
- Clone forked repository into your home directory
- run: ```. ~/dotman/install.sh```

## Usage:
### Registering a dotfile
To add a file and push it to the repository:
```
cd ~
dotadd path/under/home/directory/to/the/file
```
### Updating local environment
To sync from the repository, use ```dotpull``` command

### Pushing changes to repository
To push changes made to your previously registered dotfiles, use ```dotpull``` command 

### Syncing with the repository
```dotsync``` command will stash your local changes, pull and apply changes from the repository, and then it will unstash and push your local changes to the repository

### Resetting changes 
To reset any changes made to registered dotfiles, use ```dotclean``` command
