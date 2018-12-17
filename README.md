# glusterdroid
Semi Automated Setup of GlusterFS on odroid HC2

## Disclaimer:

This is probably not the most optimal of things. There are much better ways to
do things but this project was never meant to show off any 1337 bash skillz. It was just
an easy way for me to consistently build new gluster nodes and have them work. There
are no guarantees and this is use at your own risk.


- This has been tested on Odroid HC2 but would probably work on the 2.5" version.
- This **does not** take care of the gluster setup as far as setting up/adding to volumes.
That part is up to you.


## Installation:

I am using [Ubuntu 18.04](https://forum.odroid.com/viewtopic.php?t=27449) on my odroid HC2s. You can download it from the Odroid forum.
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
**BURSTPOOL** = This is the pool you are mining on. I recommend using the default. Make sure you read up on joining a pool.
you have to set the reward assignment to the pools address etc.
**BURSTACCOUNT** = Set this to your account ID of the wallet you using to mine with.
**BURSTDEADLINE** = This is where you set the deadline. Research this... It's based on how much space you have etc.
**BURSTPATH** = This is the path. Default should work.   

## Telegraf
Telegraf is a slick way to monitor what's going on with your setup. I will include a grafana dashboard that you will have to edit for your environment. I have included a custom monitoring script for disk temps that gets dropped into cron.

## Burst
Might as well mine with your free space right? Enabling this feature allows you to copy plots to your drives and have your odroids mine. This document or this script don't cover what you need to do to start burst mining. I have only tested this in distributed mode. I am not sure what would happen in dispersed when you fill the drive up
outside the brick. Its on the list of thins to try. I find that 50GB plot sizes seem to work the best for balancing out across the cluster. Your experience may be different though. I will be releasing a script that will track the size of your
plots and the size of your data and delete older plot files to free up space for real data. Stay Tuned!


Feel free to submit PRs to make this better.
