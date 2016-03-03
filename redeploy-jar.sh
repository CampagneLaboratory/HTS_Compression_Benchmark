#!/bin/bash
cd ~/deployment/goby2RCs/ && git pull --tags origin 2.0RC2 && git checkout 2.0 -f && ant jar-goby && cp goby.jar ~/reads-for-paper/

