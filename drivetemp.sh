smartctl -a /dev/sda -d sat | grep Temperature_Celsius | awk {'print "hddtemp temp="$10'} > /var/log/temps/hddtemps.log 
