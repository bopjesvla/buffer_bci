#!/usr/bin/env python3
# Set up imports and paths
bufferpath = "../../dataAcq/buffer/python"
sigProcPath = "../signalProc"
import sys
# from pygame.locals import *
from time import sleep, time
import os
import numpy
bufhelpPath = "../../python/signalProc"
sys.path.append(bufhelpPath)
import bufhelp

def echoClient(timeout=5000):
        		
    ## init connection to the buffer
    ftc,hdr=bufhelp.connect();

    # send event to buffer
    while True:
        events = bufhelp.buffer_newevents(state=True)

        for event in events:
            if event.type == 'quit':
                ftc.disconnect()
                return
            elif event.type != 'echo':
                bufhelp.sendEvent('echo', event.value)

if __name__ == "__main__":
    echoClient();
