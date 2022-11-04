import argparse
import socket
import sys
from datetime import datetime
from time import sleep

parser = argparse.ArgumentParser(description="Random data generator",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument("count",     help="total message count")
parser.add_argument("batch",     help="Amount of messages for each batch")
parser.add_argument("boot_time", help="sleep time before running the program")
parser.add_argument("sleep",     help="Sleep between runs")

args = parser.parse_args()
config = vars(args)

# Waiting n-seconds to boot
sleep(int(config['boot_time']))

teller = 0
for _ in range(1, int(config['count']) + 1):
    for x in range(1, int(config['batch']) + 1):
        teller += 1
        message = str(teller) + ", " + str(datetime.now(tz=None))
        print(message)
        sleep(int(config['sleep']))
