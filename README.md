# glusterdroid
Semi Automated Setup of GlusterFS on odroid HC2

## Disclaimer:

This is probably not the most optimal of things. There are mych beter ways to
do things but this project was never meant to show off any 1337 bash skillz. It was just
an easy way for me to consistently build new cluster nodes and have them work. There
are no guarantees and this is use at your won risk.

## Installation:

I am using Ubuntu 18.04 on my odroid HC2s. You can download it from the Odroid forum.
First things first, let's install git. You can run an update here if you like as well but I call that in the script.
It will reboot and you will have to run the setup a second time. You will notices the script knows
when you reboot and takes you to the encryption part.

1. Install git:
`apt install git`
2. Clone the repo:
`git clone https://github.com/TOoSmOotH/glusterdroid.git`
3. Edit clusterhosts and add all your nodes to the list. When you add new nodes it will append the new ones to existing host files on the nodes.
4. Edit the setup script and review the variables that you need to customize.

**HN** = The Hostname of the node you are currently building.  
**FILESYSTEM** = Pick a file system. You can choose XFS or ext4. Other might work but those are the ones I tested.  
**CRYPTVOL** = This is your crypt volume name. Nothing really speacial about this except that it will show up as this unde /dev/mapper.  
**MOUNTPOINT** = This is where you plan on mounting your 3.5" drive. I chose /gluster but you can change this to whatever.  
**BRICKNAME** = Again this is what you plan on calling your brick. you can name it whatever you like.  
**GTYPE** = Gluster Node Type. This only really matters if you plan on burst mining on free space.  
**TELEGRAF** = 1 enables telegraf to be installed and 0 disables it. See Details below.  
**INFLUXSERVER** = This is the URL for your influxDB server. This only matters is you enable Telegraf..  
**BURST** = 1 enabled 0 disabled. See details below  

## Telegraf
Telegraf is a slick way to monitor what's going on with your setup. I will include a grafana dashboard that you will have to edit for your environment. I have included a custom monitoring script for disk temps that gets dropped into cron.

## Burst
Might as well mine with your free space right? Enabling this feature allows you to copy plots to your drives and have your odroids mine. This document or this script don't cover whay you need to do to start burst mining.


Feel free to submit PRs to make this better.
