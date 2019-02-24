#!/usr/bin/env bash

python3 -mvenv .
source bin/activate
pip install -r requirements.txt
python send-reminders.py
