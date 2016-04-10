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

dotnet_env__install_prerequisites() {
  section "install prerequisites"
  sudo apt-get update
  sudo apt-get install -y unzip libuv-dev
}

dotnet_env__install_dnvm() {
  section "install dnvm"
  curl -sSL https://raw.githubusercontent.com/aspnet/Home/dev/dnvminstall.sh | DNX_BRANCH=dev sh
  source $HOME/.dnx/dnvm/dnvm.sh
}


dotnet_env__install_dotnet() {
  section "install dotnet"
  echo 'deb [arch=amd64] http://apt-mo.trafficmanager.net/repos/dotnet/ trusty main' | sudo tee /etc/apt/sources.list.d/dotnet.list
  sudo apt-key adv --keyserver apt-mo.trafficmanager.net --recv-keys 417A0893
  sudo apt-get update
  sudo apt-get install -y dotnet
}


dotnet_env__install_coreclr() {
  section "install coreclr"
  sudo apt-get install -y libunwind8 gettext libssl-dev libcurl4-openssl-dev zlib1g libicu-dev uuid-dev
}

dotnet_env__install_coreclr_runtime() {
  section "install coreclr runtime"
  dnvm upgrade -r coreclr -arch x64
}


dotnet_env__install_mono() {
  section "install mono"
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF 
  echo 'deb http://download.mono-project.com/repo/debian wheezy main' | sudo tee /etc/apt/sources.list.d/mono.list 
  sudo apt-get update
  sudo apt-get install -y mono-complete ca-certificates-mono 
  sudo apt-get install -y mozroots
  mozroots --sync --import
}


dotnet_env__install_mono_runtime() {
  section "install mono runtime"
  dnvm upgrade -r mono -arch x64
}


dotnet_env__install_nuget() {
  section "install nuget"
  LAUNCHER="/usr/share/mono/nuget"
  wget http://dist.nuget.org/win-x86-commandline/latest/nuget.exe
  sudo mv nuget.exe /usr/share/mono/

  if [ -f $LAUNCHER ]; then
    sudo rm $LAUNCHER
  fi
  echo "
#!/bin/bash
mono /usr/share/mono/nuget.exe \"\$@\"
" | sudo tee $LAUNCHER
  sudo chmod +x $LAUNCHER

  LINK="/usr/bin/nuget"
  if [ -f $LINK ]; then
    sudo rm $LINK
  fi
  sudo ln -s $LAUNCHER $LINK
}

dotnet_env__install_all() {
  dotnet_env__install_prerequisites
  dotnet_env__install_dnvm
  dotnet_env__install_dotnet
  dotnet_env__install_coreclr
  dotnet_env__install_coreclr_runtime
  dotnet_env__install_mono
  dotnet_env__install_mono_runtime
  dotnet_env__install_nuget
}
