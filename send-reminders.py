#!/usr/bin/env python
import datetime
import http.client
import json
import logging
import operator
import os
import sys
import time
import urllib

from dateutil import parser

logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
EXPECTED_ENV_VARIABLES = ["pushover_tok", "pushover_key", "reminders_file"]

class Reminder:
    """A Reminder as exported by the emacs extension"""
    def __init__(self, title, date, message=None, **kwargs):
        self.date = parser.parse(date)
        self.msg = message or title

    def __str__(self):
        return f"REMINDER\nDATE {self.date}\nMSG {self.msg}"


def read_reminders(filename, cutoff_time):
    """Read reminders from `filename` removing those before `cutoff_time`"""
    with open(filename) as f:
        reminders = [Reminder(**e) for e in json.load(f)]
        return sorted(
            [r for r in reminders if r.date > cutoff_time],
            key=operator.attrgetter("date"),
            reverse=True
        )


def sleep_until(reminder):
    """Sleep until the reminder firing date"""
    to_sleep = (reminder.date - datetime.datetime.now())
    to_sleep_s = to_sleep.total_seconds()
    if to_sleep_s > 0:
        logging.debug(f"Sleeping for {to_sleep}")
        time.sleep(to_sleep_s)


def pushover_send(msg):
    """Send a message with the pushover API"""
    print(f"Sending '{msg}'")
    conn = http.client.HTTPSConnection("api.pushover.net:443")
    conn.request("POST", "/1/messages.json",
                 urllib.parse.urlencode({
                     "token": os.environ["pushover_tok"],
                     "user": os.environ["pushover_key"],
                     "message": msg,
                 }), { "Content-type": "application/x-www-form-urlencoded" })
    conn.getresponse()
    print(f"Sent '{msg}'")

def validate_env_or_die(keys):
    """Fail with error if an expected envs variable is not set."""
    failed = False
    for e in keys:
        if not e in os.environ:
            print(f"Please set up the '{e}' environment variable")
            failed = True
    if failed:
        sys.exit(1)

def main():
    validate_env_or_die(EXPECTED_ENV_VARIABLES)
    pushover_send("Reminder server started")
    filename = os.environ["reminders_file"]
    reminders = read_reminders(filename, cutoff_time=datetime.datetime.now())
    logging.debug(f"Read: {len(reminders)} reminders from {filename}")
    while reminders:
        next_reminder = reminders.pop()
        logging.debug(f"Next reminder: \n{next_reminder}")
        sleep_until(next_reminder)
        pushover_send(next_reminder.msg)


if __name__ == '__main__':
    main()
