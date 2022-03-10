#!/bin/bash

helm uninstall mysql -n oai 
helm uninstall nrf -n oai
helm uninstall udr -n oai
helm uninstall udm -n oai
helm uninstall ausf -n oai
helm uninstall amf -n oai
helm uninstall smf -n oai
helm uninstall upf -n oai

