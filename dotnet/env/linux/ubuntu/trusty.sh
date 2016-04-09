#!/bin/bash


section() {
  local hr="--------------------------------------------------------------------"
  echo $hr
  echo $1
  echo $hr
}


section "setup vars"
USER=$(whoami)
HOME=$(getent passwd "$USER" | cut -d : -f 6)

install_prerequisites() {
  section "install prerequisites"
  sudo apt-get update
  sudo apt-get install -y unzip libuv-dev
}

install_dnvm() {
  section "install dnvm"
  curl -sSL https://raw.githubusercontent.com/aspnet/Home/dev/dnvminstall.sh | DNX_BRANCH=dev sh
  source $HOME/.dnx/dnvm/dnvm.sh
}


install_dotnet() {
  section "install dotnet"
  echo 'deb [arch=amd64] http://apt-mo.trafficmanager.net/repos/dotnet/ trusty main' | sudo tee /etc/apt/sources.list.d/dotnet.list
  sudo apt-key adv --keyserver apt-mo.trafficmanager.net --recv-keys 417A0893
  sudo apt-get update
  sudo apt-get install -y dotnet
}


install_coreclr() {
  section "install coreclr"
  sudo apt-get install -y libunwind8 gettext libssl-dev libcurl4-openssl-dev zlib1g libicu-dev uuid-dev
}

install_coreclr_runtime() {
  section "install coreclr runtime"
  dnvm upgrade -r coreclr -arch x64
}


install_mono() {
  section "install mono"
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF 
  echo 'deb http://download.mono-project.com/repo/debian wheezy main' | sudo tee /etc/apt/sources.list.d/mono.list 
  sudo apt-get update
  sudo apt-get install -y mono-complete ca-certificates-mono 
  sudo apt-get install -y mozroots
  mozroots --sync --import
}


install_mono_runtime() {
  section "install mono runtime"
  dnvm upgrade -r mono -arch x64
}


install_nuget() {
  section "install nuget"
  NUGET="/usr/share/mono/nuget"
  wget http://dist.nuget.org/win-x86-commandline/latest/nuget.exe
  sudo mv nuget.exe /usr/share/mono/
  sudo rm $NUGET
  echo '#!/bin/bash' | sudo tee -a $NUGET
  echo 'mono /usr/share/mono/nuget.exe "$@"' | sudo tee -a $NUGET
  sudo chmod +x $NUGET
  sudo rm "/usr/bin/nuget"
  sudo ln -s $NUGET "/usr/bin/nuget"
}

install_all() {
  install_prerequisites
  install_dnvm
  install_dotnet
  install_coreclr
  install_coreclr_runtime
  install_mono
  install_mono_runtime
  install_nuget
}
