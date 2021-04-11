#!/bin/bash
nmcli con down eno1
nmcli con up bridge0
