# Reference:
## Use nmcli to create network bridge interface
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/configuring_and_managing_networking/index#configuring-a-network-bridge_configuring-and-managing-networking
## Try it out
https://www.techotopia.com/index.php/Creating_a_RHEL_KVM_Networked_Bridge_Interface
---
---

1.  List current
```
root@basecamp1:~# nmcli con show
NAME                UUID                                  TYPE      DEVICE  
bridge0             39c755af-c5a5-4a0c-a148-17459d7ad908  bridge    bridge0 
Wired connection 1  10a2d5bf-ebb2-3da3-aaba-0ff25e79a8c4  ethernet  eno1    
virbr0              10cefa18-b534-4a47-a765-6618d440ec40  bridge    virbr0  
Wired connection 2  73bce6a2-ba80-3cc8-81d8-2c846995cc1d  ethernet  --      
Wired connection 3  37f54d78-7e01-30fe-ae32-7cbe008b2fdf  ethernet  --      
Wired connection 4  266b4890-b0d1-319f-aacb-9418087b1d22  ethernet  --      
```
```
nmcli device show
```
```
root@basecamp1:~# virsh net-list --all
 Name                 State      Autostart     Persistent
----------------------------------------------------------
 default              active     yes           yes
```

1. (optional bridge0) Delete and start over
```
root@basecamp1:~# nmcli c delete bridge0
Connection 'bridge0' (39c755af-c5a5-4a0c-a148-17459d7ad908) successfully deleted.
root@basecamp1:~# nmcli con show
NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  10a2d5bf-ebb2-3da3-aaba-0ff25e79a8c4  ethernet  eno1   
virbr0              10cefa18-b534-4a47-a765-6618d440ec40  bridge    virbr0 
Wired connection 2  73bce6a2-ba80-3cc8-81d8-2c846995cc1d  ethernet  --     
Wired connection 3  37f54d78-7e01-30fe-ae32-7cbe008b2fdf  ethernet  --     
Wired connection 4  266b4890-b0d1-319f-aacb-9418087b1d22  ethernet  --     
root@basecamp1:~# 
```

1. Create new bridge
```
root@basecamp1:~# nmcli con add ifname bridge0 type bridge con-name bridge0
Connection 'bridge0' (e1345980-5d82-4b60-b472-52fbfdd12506) successfully added.
```

1.  Establish bridge slave interface between physical eno1 (slave) and bridge (master)
```
root@basecamp1:~# nmcli con add type bridge-slave ifname eno1 master bridge0
Connection 'bridge-slave-eno1' (11253487-8d5c-445e-80e0-29d0308fcc30) successfully added.
```

1. List
```
root@basecamp1:~# nmcli con show
NAME                UUID                                  TYPE      DEVICE  
bridge0             e1345980-5d82-4b60-b472-52fbfdd12506  bridge    bridge0 
Wired connection 1  10a2d5bf-ebb2-3da3-aaba-0ff25e79a8c4  ethernet  eno1    
virbr0              10cefa18-b534-4a47-a765-6618d440ec40  bridge    virbr0  
bridge-slave-eno1   11253487-8d5c-445e-80e0-29d0308fcc30  ethernet  --      
Wired connection 2  73bce6a2-ba80-3cc8-81d8-2c846995cc1d  ethernet  --      
Wired connection 3  37f54d78-7e01-30fe-ae32-7cbe008b2fdf  ethernet  --      
Wired connection 4  266b4890-b0d1-319f-aacb-9418087b1d22  ethernet  --      
```
1. Start up bridge interface, use script to avoid disconnect on blip
```sh
#!/bin/bash
nmcli con down eno1
nmcli con up bridge0
```

1. List
```
root@basecamp1:~# ./bridge.sh 
Error: 'eno1' is not an active connection.
Error: no active connection provided.
Connection successfully activated (master waiting for slaves) (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/6)
root@basecamp1:~# nmcli con show
NAME                UUID                                  TYPE      DEVICE  
bridge0             e1345980-5d82-4b60-b472-52fbfdd12506  bridge    bridge0 
Wired connection 1  10a2d5bf-ebb2-3da3-aaba-0ff25e79a8c4  ethernet  eno1    
virbr0              10cefa18-b534-4a47-a765-6618d440ec40  bridge    virbr0  
bridge-slave-eno1   11253487-8d5c-445e-80e0-29d0308fcc30  ethernet  --      
Wired connection 2  73bce6a2-ba80-3cc8-81d8-2c846995cc1d  ethernet  --      
Wired connection 3  37f54d78-7e01-30fe-ae32-7cbe008b2fdf  ethernet  --      
Wired connection 4  266b4890-b0d1-319f-aacb-9418087b1d22  ethernet  --      
root@basecamp1:~# nmcli con show --active
NAME                UUID                                  TYPE      DEVICE  
bridge0             e1345980-5d82-4b60-b472-52fbfdd12506  bridge    bridge0 
Wired connection 1  10a2d5bf-ebb2-3da3-aaba-0ff25e79a8c4  ethernet  eno1    
virbr0              10cefa18-b534-4a47-a765-6618d440ec40  bridge    virbr0  
```

1. Create bridge.xml for virsh -- configure for KVM
```
<network>
  <name>bridge0</name>
  <forward mode="bridge"/>
  <bridge name="bridge0" />
</network>
```
1. Run
```
root@basecamp1:~# virsh net-define ./bridge.xml 
Network bridge0 defined from ./bridge.xml
```
1. Start, set auto-start and list
```
oot@basecamp1:~# virsh net-start bridge0
Network bridge0 started

root@basecamp1:~# virsh net-autostart bridge0
Network bridge0 marked as autostarted

root@basecamp1:~# virsh net-list --all
 Name                 State      Autostart     Persistent
----------------------------------------------------------
 bridge0              active     yes           yes
 default              active     yes           yes
```
---
---
1. Other Packages
```
nm-connection-editor
network-manager-applet
```
