#!/bin/bash

helm install mysql mysql/ -n oai
helm install nrf oai-nrf/ -n oai
helm install udr oai-udr/ -n oai
helm install udm oai-udm/ -n oai
helm install ausf oai-ausf/ -n oai
helm install amf oai-amf/ -n oai
helm install smf oai-smf/ -n oai
helm install upf oai-spgwu-tiny/ -n oai

