#!/bin/sh

# Bail on any errors
set -e

update_path() {
    # Export some useful directories.
    export PATH=/usr/local/sbin:$PATH

    # Put these in .bash_profile too.
    if ! grep -q "export PATH=/usr/local/sbin" ~/.bash_profile; then
        echo "export PATH=/usr/local/sbin:$$PATH" >> ~/.bash_profile
    fi
}

register_ssh_keys() {
    # Create a public key if need be.
    mkdir -p ~/.ssh
    if [ ! -e ~/.ssh/id_rsa ]; then
	ssh-keygen -q -N "" -t rsa -f ~/.ssh/id_rsa
    fi

    # Copy the public key into the OS X clipboard.
    cat ~/.ssh/id_rsa.pub | pbcopy

    # Have the user copy it into kiln and github.
    echo "Opening kiln and github for you to register your ssh key."
    echo "We've already copied the key into the OS clipboard for you."
    echo "Click 'Add SSH Key', paste into the box, and hit 'Add key'"
    open "https://github.com/settings/ssh"
    read -p "Press enter to continue..."

    echo "Click 'Add a New Key', paste into the box, and hit 'Save key'"
    open "https://khanacademy.kilnhg.com/Keys"
    read -p "Press enter to continue..."
}

install_gcc() {
    if ! gcc --version >/dev/null 2>&1; then
	echo "Downloading Command Line Tools (log in to start the download)"
	# download the command line tools
	open "https://developer.apple.com/downloads/download.action?path=Developer_Tools/command_line_tools_for_xcode__june_2012/command_line_tools_for_xcode_june_2012.dmg"
	# If this doesn't work for you, you can find the most recent
	# version here: https://developer.apple.com/downloads
	# Then plug that file into the commands below
        read -p "Press enter to continue..."

	echo "Running Command Line Tools Installer"
	# Attach the disk image, install the tools, then detach the image.
	hdiutil attach ~/Downloads/command_line_tools_for_xcode_june_2012.dmg \
            > /dev/null
	sudo installer \
            -package "/Volumes/Command Line Tools/Command Line Tools.mpkg" \
            -target /
	hdiutil detach "/Volumes/Command Line Tools/" > /dev/null
    fi
}

install_hipchat() {
    # TODO(csilvers): see if hipchat is already installed before doing this.
    echo "Opening Hipchat website (log in and click download to install)"
    open "http://www.hipchat.com/"
    read -p "Press enter to continue..."
}

install_homebrew() {
    echo "Installing Homebrew"
    # If homebrew is already installed, don't do it again.
    if [ ! -d /usr/local/.git ]; then
	/usr/bin/ruby -e "`curl -fsSkL raw.github.com/mxcl/homebrew/go`"
    fi
    # Update brew.
    brew update > /dev/null

    # Make the cellar
    mkdir -p /usr/local/Cellar

    # brew doctor
    brew doctor
}

install_nginx() {
    echo "Installing nginx"
    brew install nginx

    if [ ! -e /usr/local/etc/nginx/nginx.conf.old ]; then
        echo "Backing up nginx.conf to nginx.conf.old"
        sudo cp /usr/local/etc/nginx/nginx.conf \
            /usr/local/etc/nginx/nginx.conf.old
    fi

    # Copy some default SSL certificates.  If you want to make your
    # own, follow the instructions found here:
    #     http://wiki.nginx.org/HttpSslModule
    sudo cp -f stable.ka.local.crt /usr/local/etc/nginx/stable.ka.local.crt
    sudo cp -f stable.ka.local.key /usr/local/etc/nginx/stable.ka.local.key

    echo "Setting up nginx"
    # setup the nginx configuration file
    sudo sh -c \
        "sed 's/%USER/$USER/' nginx.conf > /usr/local/etc/nginx/nginx.conf"

    # Copy the launch plist.
    sudo cp -f /usr/local/Cellar/nginx/*/homebrew.mxcl.nginx.plist \
        /Library/LaunchDaemons
    # Delete the username key so it is run as root
    sudo /usr/libexec/PlistBuddy -c "Delete :UserName" \
        /Library/LaunchDaemons/homebrew.mxcl.nginx.plist 2>/dev/null
    # Load it.
    sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
}

install_appengine_launcher() {
    if [ ! -d /Applications/GoogleAppEngineLauncher.app ]; then
        echo "Setting up App Engine Launcher"
        # TODO(csilvers): skip this step if it's already been done.
        curl -s http://googleappengine.googlecode.com/files/GoogleAppEngineLauncher-1.7.4.dmg \
            -o ~/Downloads/GoogleAppEngineLauncher-1.7.4.dmg
        hdiutil attach ~/Downloads/GoogleAppEngineLauncher-1.7.4.dmg
        cp -fr /Volumes/GoogleAppEngineLauncher-*/GoogleAppEngineLauncher.app \
            /Applications/
        hdiutil detach /Volumes/GoogleAppEngineLauncher-*

        echo "Set up the Google App Engine Launcher according to the website."
        open "https://sites.google.com/a/khanacademy.org/forge/for-khan-employees/-new-employees-onboard-doc/developer-setup/launching-your-test-site"
        open -a GoogleAppEngineLauncher

        read -p "Press enter to continue..."
    fi
}


echo "Running Khan Installation Script 1.0"
echo "Warning: This is only tested on Mac OS 10.7 (Lion)"
echo "  After each statement, either something will open for you to"
echo "    interact with, or a script will run for you to use"
echo "  Press enter when a download/install is completed to go to"
echo "    the next step (including this one)"

read -p "Press enter to continue..."

# Run sudo once at the beginning to get the necessary permissions.
echo "This setup script needs your password to install things as root."
sudo sh -c 'echo Thanks'

update_path
register_ssh_keys
install_gcc
install_hipchat
install_homebrew
install_nginx
install_appengine_launcher

echo "You might be done!"
