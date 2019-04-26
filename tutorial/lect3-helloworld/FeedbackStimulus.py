#!/usr/bin/env python3
# Set up imports and paths
import matplotlib
# matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import sys, os
from time import sleep, time
bufhelpPath = "../../python/signalProc"
sys.path.append(bufhelpPath)
import bufhelp

## HELPER FUNCTIONS
def drawnow(fig=None):
    "force a matplotlib figure to redraw itself, inside a compute loop"
    if fig is None: fig=plt.gcf()
    fig.canvas.draw()
    plt.pause(1e-3) # wait for draw.. 1ms

currentKey=None
def keypressFn(event):
    "wait for keypress in a matplotlib figure, and store in the currentKey global"
    global currentKey
    currentKey=event.key
def waitforkey(fig=None,reset=True):
    "wait for a key to be pressed in the given figure"
    if fig is None: fig=gcf()
    global currentKey
    fig.canvas.mpl_connect('key_press_event',keypressFn)
    if reset: currentKey=None
    while currentKey is None:
        plt.pause(1e-3) # allow gui event processing
    return currentKey

def injectERP(amp=1,host="localhost",port=8300):
    """Inject an erp into a simulated data-stream, sliently ignore if failed, e.g. because not simulated"""
    import socket
    try:
        socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0).sendto(bytes(amp),(host,port))
    except: # sliently igore any errors
        pass
    
    
## CONFIGURABLE VARIABLES
# make the target sequence
import string
letters = list(string.ascii_uppercase)
interSentenceDuration=3;
interCharDuration=1;

ftc,hdr=bufhelp.connect();

# set the display and the string for stimulus
fig = plt.figure()
fig.suptitle('RunSentences-Stimulus', fontsize=24, fontweight='bold')
ax = fig.add_subplot(111) # default full-screen ax
ax.set_xlim((-1,1))
ax.set_ylim((-1,1))
ax.set_axis_off()
h =ax.text(0, 0,'', style='italic')

## init connection to the buffer

bufhelp.sendEvent('stimulus.letters','start');
## STARTING PROGRAM LOOP
drawnow() # update the display

# inject a signal into the simulated data-stream for debugging your signal-processing scripts

# sleep(interCharDuration)
    

##------------------------------------------------------
##                    ADD YOUR CODE BELOW HERE
##------------------------------------------------------

def charStim(t):
    for i in range(5):
        h.set(text='')
        drawnow()

        np.random.shuffle(letters)
        sleep(1)
        print(letters)
        bufhelp.sendEvent('stimulus.repetition', i)
        for c in letters:
            bufhelp.sendEvent('stimulus.char', c if t == None else c + '_' + str(c==t))
            if c == t:
                injectERP(1)
            h.set(text=c)
            drawnow() # update the display
            sleep(.1)

def calibration():
    targets = np.random.choice(letters, 10, replace=False)
    bufhelp.sendEvent('stimulus.targets', targets)
    for t in targets:
        bufhelp.sendEvent('stimulus.target', t)
        h.set(text=t, color='g')
        drawnow()
        sleep(2)
        h.set(text='', color='k')
        drawnow()
        sleep(1)
        charStim(t)
        h.set(text='', color='k')
        drawnow()
        sleep(1)
    bufhelp.sendEvent('stimulus.training', 'end')

def feedback():
    for i in range(10):
        beforevents, state = bufhelp.buffer_newevents('classifier.prediction', 0, state=None)
        h.set(text='Think of your target letter and get ready')
        drawnow()
        sleep(2)
        h.set(text='', color='k')
        drawnow()
        sleep(1)
        charStim(None)
        h.set(text='', color='k')
        drawnow()
        sleep(1)

        feedbackevents, _state = bufhelp.buffer_newevents('classifier.prediction', state=state)

        # predictions contain both labels and values
        chars, predictions = np.array([e.value.split('_') for e in feedbackevents]).T

        predictions = predictions.astype(float)

        # get the character with the highest mean prediction (currently random in feedback stage)
        best = max(np.unique(chars), key=lambda c: np.mean(predictions[chars == c]))

        h.set(text=best, color='b')
        drawnow()
        sleep(2)

while True:
    h.set(text='Press c for calibration, f for feedback')
    drawnow()
    x = waitforkey(fig)
    if x == 'c':
        calibration()
    elif x == 'f':
        feedback()
