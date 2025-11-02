sudo apt-get update
sudo apt upgrade
sudo apt install -y make git curl gh wget dirmngr gpg gawk luarocks snap snapd composer flatpak unzip gcc lldb
sudo install -dm 755 /etc/apt/keyringso

wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null

echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
touch ~/.bash_profile
echo 'eval "$(~/usr/bin/mise activate bash)"' > ~/.bash_profile
sudo apt update
sudo apt install -y mise
for tool in node python rust lua java; do
mise install $tool
done
sh -c "$(curl -fsLS get.chezmoi.io)"


