#!/bin/bash


section() {
  local hr="--------------------------------------------------------------------"
  echo $hr
  echo $1
  echo $hr
}


section "setup vars"
USER=$(whoami)
GROUP=$(id -g -n $USER)
HOME=$(getent passwd "$USER" | cut -d : -f 6)
AGENTS_FOLDER="/srv/build-agents"


ci_teamcity_9x_agent__install_prerequisites() {
  section "install prerequisites"
  sudo apt-add-repository -y ppa:webupd8team/java
  sudo apt-get update
  sudo apt-get install -y oracle-java8-installer oracle-java8-set-default unzip
}


ci_teamcity_9x_agent__download_agent() {
  echo "server url?"
  read SERVER
  section "download agent"
  if [ -f "buildAgent.zip" ]; then
    rm "buildAgent.zip"
  fi
  wget $SERVER/update/buildAgent.zip
}


ci_teamcity_9x_agent__create_agents_folder() {
  section "create agents folder"
  if ! [ -d $AGENTS_FOLDER ]; then
    sudo mkdir $AGENTS_FOLDER
  fi
  sudo chown -R $USER:$GROUP $AGENTS_FOLDER
}


ci_teamcity_9x_agent__define_shutdown_permissions() {
  sudo addgroup shutdown
  sudo adduser $USER shutdown

  FILE="/etc/sudoers.d/shutdown"
  if [ -f $FILE ]; then
    sudo rm $FILE
  fi
  echo "
%shutdown ALL=NOPASSWD: /sbin/shutdown
%shutdown ALL=NOPASSWD: /sbin/reboot
" | sudo tee $FILE

  FILE="$HOME/.bash_profile"
  if [ -f $FILE ]; then
    sudo rm $FILE
  fi
  echo "
alias shutdown='sudo /sbin/shutdown'
alias reboot='sudo /sbin/reboot'
" | sudo tee $FILE
}


ci_teamcity_9x_agent__setup_agent() {
  SERVER=$1
  NAME=$2
  echo "agent port?"
  read PORT

  FOLDER=$AGENTS_FOLDER/$NAME
  if [ -d $FOLDER ]; then
    sudo rm -rf $FOLDER
  fi
  unzip "buildAgent.zip" -d $FOLDER
  sudo chown -R $USER:$GROUP $FOLDER
  
  rm $FOLDER/BUILD*
  chmod -R +x $FOLDER/bin
  
  CONFIG=$FOLDER/conf/buildAgent.properties
  mv $FOLDER/conf/buildAgent.dist.properties $CONFIG
  sed -i -- "s#serverUrl=http://localhost:8111/#serverUrl=$SERVER#g" $CONFIG
  sed -i -- "s#name=#name=$NAME#g" $CONFIG
  sed -i -- "s#9090#$PORT#g" $CONFIG
}


ci_teamcity_9x_agent__setup_agent_service() {
  NAME=$1

  FOLDER=$AGENTS_FOLDER/$NAME
  SCRIPT="/etc/init.d/$NAME"
  if [ -f $SCRIPT ]; then
    sudo rm $SCRIPT
    sudo update-dc.d remove $NAME
  fi
  echo "
#!/bin/sh
USER=\"$USER\"
case \"\$1\" in
  start)                                                                          
    su - \$USER -c \"$FOLDER/bin/agent.sh start\"
    ;;
  stop)
    su - \$USER -c \"$FOLDER/bin/agent.sh stop\"
    ;;
  *)
    echo \"usage start/stop\"
    exit 1
    ;;
esac
exit 0                                                                          
" | sudo tee $SCRIPT

  sudo chmod +x $SCRIPT
  sudo update-rc.d $NAME defaults
}


ci_teamcity_9x_agent__install_agent() {
  echo "server url?"
  read SERVER
  echo "agent name?"
  read NAME
  ci_teamcity_9x_agent__setup_agent $SERVER $NAME
  ci_teamcity_9x_agent__setup_agent_service $NAME
}


ci_teamcity_9x_agent__prepare_all() {
  ci_teamcity_9x_agent__install_prerequisites
  ci_teamcity_9x_agent__download_agent
  ci_teamcity_9x_agent__create_agents_folder
  ci_teamcity_9x_agent__define_shutdown_permissions
}
