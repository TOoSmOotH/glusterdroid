#!/bin/bash

################################
###                          ###
###      Config Section      ###
###                          ###
################################

# Change stuff to match in here. Add ALL your gluster nodes to the clusterhosts before you run this script
# Hostname of the node you are adding
HN=gluster10tb06
# Get your IP cause DHCP FTW
MAINIP=$(ip route get 1 | awk '{print $7;exit}')
# Pick a filesystem. I would choose either ext4 or xfs. It's up to you!
FILESYSTEM=ext4
# Name of the encrypted volume. This can be anything you want
CRYPTVOL=securedata
# This is where we are mounting the 3.5" drive
MOUNTPOINT=/gluster
# This is what we are naming the brick.
BRICKNAME=brick1
# GTYPE can be "distributed" or "dispersed". This is the type of volume you will be setting up. If using replicated disable BURST
GTYPE=distributed
# Do you want to set up Telegraf? 1 is on 0 is off. You need influx and grafana for this to be of any use.
TELEGRAF=1
INFLUXSERVER=http://192.168.2.4:8086
# Do you want to mine burst on your free space? Set to 0 to disable.
BURST=1
# Enter the Pool you want to use.
BURSTPOOL=http://voiplanparty.com:8124
# Don't know if you really need this but this is the account id for which you are mining.
BURSTACCOUNT=2163918534933052101
# This is based on total TB you are mining with. Do research on the pool and the space you have for mining.
BURSTDEADLINE=11087847
# This path is dependant on the type of volume in gluster you are creating
if [ $GTYPE == "distributed" ]; then
  BURSTPATH=/$MOUNTPOINT/$BRICKNAME/burst
else
  BUSTPATH=/$MOUNTPOINT/burst
fi

###############################
###                         ###
###    This is the magic    ###
###                         ###
###############################

# Don't mess with anything below this unless you know what you are doing.
if [ ! -f 1stboot ]; then
  # Set the Hostname
  hostnamectl set-hostname $HN

  # Change the hosts file
  sed -i "s/odroid/$HN/g" /etc/hosts

  # Add all the nodes to the local hosts file
  cat clusterhosts | while read line
  do
    echo $line >> /etc/hosts
  done

  # Add the new gluster node to all the other nodes
  # Yes this is lame
  cat clusterhosts | grep -v $HN | awk '{print $1}' >> hostscluster
  CMD=$(echo "$MAINIP $HN")
  echo $CMD
  for host in $(cat hostscluster); do ssh -o StrictHostKeyChecking=accept-new root@$host sudo echo "$CMD >> /etc/hosts"; done
  rm hostscluster

  # Update the OS
  apt update
  echo "Upgrading all the things"
  apt -y upgrade

  # Install some tools we need.
  apt -y install wget parted curl cryptsetup

  # Add some Repos
  wget -O- https://download.gluster.org/pub/gluster/glusterfs/3.12/rsa.pub | apt-key add -
  add-apt-repository ppa:gluster/glusterfs-4.1
  wget -O- https://repos.influxdata.com/influxdb.key | apt-key add -
  echo "deb https://repos.influxdata.com/ubuntu bionic stable" > /etc/apt/sources.list.d/influxdata.list
  apt update

  # Install what we came here for.
  echo "Installing Gluster Server.. This will error out sometimes but that is ok."
  apt install glusterfs-server -y
  echo " If you got an error about gluster server don't worry about it."
  touch 1stboot
  echo "Rebooting in 30s... Re-run this script when you log in again."
  sleep 30
  reboot
fi

if [ -f 1stboot ]; then

  # Toss up the warning. Can't say I didn't warn you!

  install="no"
  while [ "$install" != "yes" ]; do
  echo "###########################################"
  echo "##          ** W A R N I N G **          ##"
  echo "##    _______________________________    ##"
  echo "##                                       ##"
  echo "##       If you continue from here       ##"
  echo "##     ALL DATA on the 3.5 inch drive    ##"
  echo "##           WILL BE DESTROYED!          ##"
  echo "##                                       ##"
  echo "##      ** ALL DATA WILL BE LOST **      ##"
  echo "###########################################"
  echo "Do you wish to continue? (Type the entire word "yes" to proceed.) "
  read install
  done

  # Partition and encrypt
  echo "Partitioning the drive"
  parted -a opt /dev/sda mktable gpt
  parted -a opt /dev/sda mkpart primary 0% 100%

  # Crypto Time
  echo "Loading Crypto Modules into the Kernel"
  modprobe dm-crypt sha256 aes

  # Wipe the partition
  echo "Wiping the partition"
  wipefs -a /dev/sda1

  # This key is used to auto mount the drive on reboot. If someone swipes your entire system then they could get to the data.
  # The main reason for this is so that if you RMA a drive your data is encrypted.
  # This is not meant to protect you from the Matrix.
  echo "Generating a random key for auto mount purposes"
  dd if=/dev/urandom of=/root/keyfile bs=1024 count=4
  chmod 400 /root/keyfile

  # Make this like at least 32 characters
  echo "Make a hard password and remember it or store in a password manager"
  cryptsetup --verify-passphrase luksFormat /dev/sda1 -c aes-ctr-plain -h sha256 -s 128
  echo "Opening the encrypted volume"
  cryptsetup luksOpen /dev/sda1 $CRYPTVOL
  echo "Creating a $FILESYSTEM filesystem on the encrypted volume $CRYPTVOL"
  mkfs -t $FILESYSTEM -m 1 /dev/mapper/$CRYPTVOL
  echo " Closing the volume so we can apply the key to it for booting"
  cryptsetup -v luksClose $CRYPTVOL
  echo " Applying key to the volume. You will need that password again. Last time I promise."
  cryptsetup luksAddKey /dev/sda1 /root/keyfile
  echo "Setting up the crypttab"
  echo "$CRYPTVOL /dev/sda1 /root/keyfile luks" >> /etc/crypttab
  echo "Assigning the key to cryptdisks"
  sed -i "/CRYPTODISKS_MOUNT*/c\CRYPTDISKS_MOUNT=\"/root/keyfile\"" /etc/default/cryptdisks
  mkdir -p $MOUNTPOINT/$BRICKNAME
  echo "Adding the mount to /etc/fstab"
  echo "/dev/mapper/$CRYPTVOL $MOUNTPOINT $FILESYSTEM default,rw  0 2" >> /etc/fstab
  echo "Mounting the encrypted drive"
  mount -a

  # Get Telegraf rocking if it is enabled.
  if [ $TELEGRAF == 1 ]; then
    echo "Installing Telegraf to monitor the things"
    apt install telegraf smartmontools
    mkdir -p /var/log/temps
    cp drivetemp.sh /usr/sbin/
    chmod 755 /usr/sbin/drivetemp.sh
    # Add the job to Cron
    echo "*/10 * * * * root /usr/sbin/drivetemp.sh" > /etc/cron.d/hddtemp
    cp telegraf.conf /etc/telegraf/
    sed -i "s/ACIDINFLUX/$INFLUXSERVER/g" /etc/hosts
    systemctl restart telegraf
    systemctl enable telegraf
  fi
  if [ $BURST == 1 ]; then
    echo "Installing Burst"
    wget https://github.com/TOoSmOotH/glusterdroid/releases/download/scav1.6.6/scavenger-1.6.6-odroid.tar.gz
    tar zxvf scavenger-1.6.6-odroid.tar.gz
    mkdir -p /opt
    mv release /opt/scavenger
    cp burstconfig.yaml /opt/scavenger/config.yaml
    sed -i "s/POOL/$BURSTPOOL/g" /opt/scavenger/config.yaml
    sed -i "s/PLOTPATH/$BURSTPATH/g" /opt/scavenger/config.yaml
    sed -i "s/DEADLINE/$BURSTDEADLINE/g" /opt/scavenger/config.yaml
    sed -i "s/ACNT/$BURSTACCOUNT/g" /opt/scavenger/config.yaml

    # Install screen
    apt -y install screen
    # Create a junky script
    echo "cd /opt/scavenger" > /usr/sbin/scav.sh
    echo "./scavenger" >> /usr/sbin/scav.sh
    chmod +x /usr/sbin/scav.sh
    echo "screen -dmS scav /usr/sbin/scav.sh" > /usr/sbin/screenscav.sh
    chmod +x /usr/sbin/screenscav.sh
    # Add this so it starts at boot
    cp scav.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable scav.service
    # Launch scavenger in the background. You can connect by doing screen -r scav
    systemctl start scav
  fi

  # This should not be automated because there are a multitude of options here.
  echo "All Done. It's up to you to handle the gluster volume creation"
fi
