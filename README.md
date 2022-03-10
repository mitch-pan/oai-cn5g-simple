# oai-cn5g-simple
The goal of this repository is to create a simplified 5G Core deployment based on the Open Air Interface (OAI) 
OPENAIR-CN-5G project.  Numerous modifications have been made, which are outlined below.

* HTTP2 is used on all Service Based Interfaces (SBIs).  Relevant configmaps with apprpriate values are already set.
* Some custom images for the SMF and AMF are used
* To simplify things, multus is disabled
* Helper install and uninstall scripts are included, which deploy the helm charts in the
correct order

In addition I've included a UERANSIM build that has some tools built into it (such as ping)
to make its use easier.  This image is based on the open source implementation found here: 
https://github.com/aligungr/UERANSIM.  Using the manifest I've provided, you can deploy
the UERANSIM client as a Pod in your cluster, for simplified communication to and from 
the 5G packet core.

## Deployment Steps

1. Clone the repository (git clone https://github.com/mitch-pan/oai-cn5g-simple.git)
2. cd into the oai-cn5g-simple/charts directory
3. Ensure you are connected to the Kubernetes cluster where you want your 5G core 
deployed (e.g. <code>kubectl get nodes</code> should show the nodes of your cluster)
4. If this is your first time to deploy, its probably best to go slowly.  Run each 
command below and troubleshoot any issues you see.<br>
    ```
    helm install mysql mysql/ -n oai <br>
    helm install nrf oai-nrf/ -n oai <br>
    helm install udr oai-udr/ -n oai<br>
    helm install udm oai-udm/ -n oai<br>
    helm install ausf oai-ausf/ -n oai<br>
    helm install amf oai-amf/ -n oai<br>
    helm install smf oai-smf/ -n oai<br>
    helm install upf oai-spgwu-tiny/ -n oai
    ```
5. Deploy the UERANSIM pod.  
    Make sure you are not in the charts directory, but in the 
main repo directory where the ueransim.yaml manifest is located.<br><br>
    `kubectl apply -f ueransim.yaml`
6. Excec into the UERANSIM pod<br><br>
    `kubectl exec --stdin --tty ueransim -- /bin/bash`
7. Edit the oai-gnb.yaml config file.  <br>The MNC and MCC should be set appropriately.  Verify the MCC is 
    208, the MNC should be 95. You will need to set the `linkIP`, `ngapIp` and `gtpIp` to the be eth0 interface IP of the 
    UERANSIM Pod.  See below for examples.
    <br>
    ```
    json
    mcc: '208'          # Mobile Country Code value<br>
    mnc: '95'           # Mobile Network Code value (2 or 3 digits)`<br><br>
    ```
    `$ kubectl get pod ueransim -o wide</code> `<--- This will show your UERANSIM IP<br>
    `$ kubectl get pods -n oai</code>` <--- This will show your your AMF IP<br><br>
    Assuming my UERANSIM was on 192.168.0.128 and my AMF had the IP 192.168.18.136 my 
    gnb config file would contain the following:<br>
    ```
    linkIp: 192.168.0.228   # gNB's local IP address for Radio Link Simulation (Usually same with local IP)
    ngapIp: 192.168.0.228   # gNB's local IP address for N2 Interface (Usually same with local IP)
    gtpIp: 192.168.0.228    # gNB's local IP address for N3 Interface (Usually same with local IP)
    ```
    ```json
    amfConfigs:
      - address: 192.168.18.136
        port: 38412
    ```
10. Edit the oai-ue.yaml config file.  <br>
    All the subscriber information can be found in the mysql `values.yaml` file, but I will summarize it below:<br>
    <br>Provisioned IMSIs:<br>
    208950000000030
    208950000000031
    208950000000032
    208950000000033
    208950000000034

    The only field you should need to edit in the `oai-ue.yaml` file is the IP address of the gNodeB.  Open the manifest file
    and set the `gnbSearchList` appropriately.  If my UERANSIM was using IP address 192.168.0.128, my config would like
    like the following:
    ```
    # List of gNB IP addresses for Radio Link Simulation
    gnbSearchList:
    - 192.168.0.128
    ```
    Feel free to make copies of this manifest using the other IMSI values.  This will allow you to attach multiple UEs
    at the same time if you desire to.
    
11. Attach gNodeB to AMF<br>
    If we have done everything correctly, our gNodeB should connect without any issue.  To attempt a connection to the
    AMF, run:<br><br>
    ```./build/nr-gnb -c config/oai-gnb.yaml```<br><br>If all goes well you should see something like:<br>
    ```
    ./build/nr-gnb -c config/oai-gnb.yaml 
    UERANSIM v3.2.6
    [2022-03-10 20:48:24.802] [sctp] [info] Trying to establish SCTP connection... (192.168.18.136:38412)
    [2022-03-10 20:48:24.813] [sctp] [info] SCTP connection established (192.168.18.136:38412)
    [2022-03-10 20:48:24.813] [sctp] [debug] SCTP association setup ascId[79]
    [2022-03-10 20:48:24.813] [ngap] [debug] Sending NG Setup Request
    [2022-03-10 20:48:24.816] [ngap] [debug] NG Setup Response received
    [2022-03-10 20:48:24.816] [ngap] [info] NG Setup procedure is successful
    ```
12. UE Attach
    While the gNodeB is running, we'll execute the UE attach in a different tab/window.  Use kubectl to connect to the 
    pod.<br><br>
    `kubectl exec --stdin --tty ueransim -- /bin/bash`<br><br>
    Once in the Pod:<br><br>
    `cd UERANSIM`<br>
    `./build/nr-ue -c config/oai-ue.yaml`<br><br>
    If all goes well you should see something like the following:<br>
    ```
    ./build/nr-ue -c config/oai-ue.yaml 
    UERANSIM v3.2.6
    [2022-03-10 21:44:01.005] [nas] [info] UE switches to state [MM-DEREGISTERED/PLMN-SEARCH]
    [2022-03-10 21:44:01.005] [rrc] [debug] New signal detected for cell[1], total [1] cells in coverage
    [2022-03-10 21:44:01.005] [nas] [info] Selected plmn[208/95]
    [2022-03-10 21:44:01.005] [rrc] [info] Selected cell plmn[208/95] tac[1] category[SUITABLE]
    [2022-03-10 21:44:01.005] [nas] [info] UE switches to state [MM-DEREGISTERED/PS]
    [2022-03-10 21:44:01.005] [nas] [info] UE switches to state [MM-DEREGISTERED/NORMAL-SERVICE]
    [2022-03-10 21:44:01.005] [nas] [debug] Initial registration required due to [MM-DEREG-NORMAL-SERVICE]
    [2022-03-10 21:44:01.005] [nas] [debug] UAC access attempt is allowed for identity[0], category[MO_sig]
    [2022-03-10 21:44:01.005] [nas] [debug] Sending Initial Registration
    [2022-03-10 21:44:01.006] [nas] [info] UE switches to state [MM-REGISTER-INITIATED]
    [2022-03-10 21:44:01.006] [rrc] [debug] Sending RRC Setup Request
    [2022-03-10 21:44:01.006] [rrc] [info] RRC connection established
    [2022-03-10 21:44:01.006] [rrc] [info] UE switches to state [RRC-CONNECTED]
    [2022-03-10 21:44:01.006] [nas] [info] UE switches to state [CM-CONNECTED]
    [2022-03-10 21:44:01.034] [nas] [debug] Authentication Request received
    [2022-03-10 21:44:01.037] [nas] [debug] Security Mode Command received
    [2022-03-10 21:44:01.038] [nas] [debug] Selected integrity[1] ciphering[1]
    [2022-03-10 21:44:01.044] [nas] [debug] Registration accept received
    [2022-03-10 21:44:01.044] [nas] [info] UE switches to state [MM-REGISTERED/NORMAL-SERVICE]
    [2022-03-10 21:44:01.044] [nas] [debug] Sending Registration Complete
    [2022-03-10 21:44:01.044] [nas] [info] Initial Registration is successful
    [2022-03-10 21:44:01.044] [nas] [debug] Sending PDU Session Establishment Request
    [2022-03-10 21:44:01.044] [nas] [debug] UAC access attempt is allowed for identity[0], category[MO_sig]
    [2022-03-10 21:44:01.274] [nas] [debug] PDU Session Establishment Accept received
    [2022-03-10 21:44:01.274] [nas] [info] PDU Session establishment is successful PSI[1]
    [2022-03-10 21:44:01.286] [app] [info] Connection setup for PDU session[1] is successful, TUN interface[uesimtun0, 12.1.1.129] is up.
    ```
    Congratulations!  You just set up a 5G PDU session!  To send traffic through the UE's tunnel interface, run ping with 
    the -I argument.  For example:<br><br>
    `ping -I uesimtun0 google.com`
    <br><br>
    Feel to explore the logs of the Pods, they have tons of information about the messaging back and forth, registration
    status, etc.
    
    For example, to see AMF logs, you could run the following (replacing the xyz with the appropriate suffix)
    `kubectl logs oai-amf-xyz -n oai` 