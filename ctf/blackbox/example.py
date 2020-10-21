# -*- coding: utf-8 -*-

# the threading library of python will easily execute the Receiver.run() function in background
import threading

# by importing all of libcanaero, we also get all the ID shortcuts
from libcanaero import *

# This is an example of how you can execute the Receiver.run() function in a separate thread
class AsyncReceiverRun(threading.Thread):
  def __init__(self, receiver):
    threading.Thread.__init__(self)
    self.recv = receiver
    self.continue_to_run = True
  def run(self):
    while self.continue_to_run:
      recv.run()
  def stop(self):
    self.continue_to_run = False

# the minimum revision of the SCS identifier distribution this program needs
revision_required = 1

# create a receiver and announce ourselves to the bus
recv = Receiver(revision_required)

def printval( val ):
  print "val is is now %f\n" % (val)

recv.requestDataF(IAS_M_S.Id(), printval)
recv.requestDataF(PITCH_DEG.Id(), printval)
recv.requestDataF(BANK_DEG.Id(), printval)
# recv.requestDataF(G_LOAD_NORMAL.Id(), printval)
recv.requestDataF(ENG_N1_PERCENT.Id(), printval)
recv.requestDataF(ENG_EGT_K.Id(), printval)

background = AsyncReceiverRun(recv)
background.start()

import time

time.sleep(1337)

background.stop()
background.join()
