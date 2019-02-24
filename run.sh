#!/usr/bin/env bash

pkill -fe ".*send-reminders.py"
python3 -mvenv .
source bin/activate
pip install -r requirements.txt
python send-reminders.py
