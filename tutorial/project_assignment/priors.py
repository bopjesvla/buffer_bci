import pandas as pd
import numpy as np

commands_columns = 'tv.1 tv.2 tv.3 tv.end sos.food sos.pain sos.toilet call.1 call.2 call.3 navigate.left navigate.right navigate.up navigate.down'.split()

NR_EVENTS = 5

probs = pd.DataFrame(np.zeros((NR_EVENTS, len(commands_columns))), columns=commands_columns)

commands = pd.DataFrame(
    [c.split('.') for c in commands_columns],
    columns=['event', 'value'],
    index=commands_columns)

# probs.loc[0, 'navigate.left'] = 1
# probs.loc[1, 'navigate.left'] = 1
# probs.loc[2, 'navigate.left'] = 1
# probs.loc[3, 'tv.1'] = 1
# probs.loc[4, 'sos.food'] = 1

def calc_priors(ev_list='navigate.left navigate.left navigate.left tv.1 sos.food'.split()):
    sent_list = commands.loc[ev_list]

    # print(probs)

    # number of occurrences during demo / number of options

    default_priors = {
        'tv': 1 / 3,
        'sos': 1 / 3,
        'call': 1 / 3,
        'navigate': 12 / 4
    }

    ## priors

    commands['priors'] = commands.event.replace(default_priors)
    tvevents = sent_list[sent_list.event == 'tv']

    if len(tvevents) == 0 or tvevents.iloc[-1].value == 'end':
        commands.priors.loc['tv.end'] = 0
    else:
        commands.priors.loc['tv.end'] = 1

    error_priors = commands.priors.copy()

    CERTAINTY = .8

    dirs = pd.DataFrame(index=['up', 'right', 'down', 'left'])
    dirs['ldir'] = np.roll(dirs.index, 1)
    dirs['rdir'] = np.roll(dirs.index, -1)
    dirs['opposite'] = np.roll(dirs.index, 2)

    print(dirs)

    navevents = sent_list[sent_list.event == 'navigate']

    if len(navevents) > 0:
        last_dir = navevents[-1]

        commands.priors.loc[last_dir] *= 2.5
        commands.priors.loc[dirs.loc[last_dir].ldir] *= .75
        commands.priors.loc[dirs.loc[last_dir].rdir] *= .75
        commands.priors.loc[dirs.loc[last_dir].opposite] = 0

    final_priors = CERTAINTY * commands.priors + (1 - CERTAINTY) * error_priors

    return final_priors

if __name__ == "__main__":
    #!/usr/bin/env python3
    # Set up imports and paths
    bufferpath = "../../dataAcq/buffer/python"
    sigProcPath = "../signalProc"
    import pygame, sys
    from pygame.locals import *
    from time import sleep, time
    import os
    import numpy
    bufhelpPath = "../../python/signalProc"
    sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufhelpPath))
    import bufhelp

    def echoClient(events, timeout=2):

        ## init connection to the buffer
        ftc,hdr=bufhelp.connect();

        ev_list = []

        # Now do the echo client
        nEvents=hdr.nEvents;
        endExpt=None;
        bufhelp.sendEvent('prior.start', '1')
        while endExpt is None:
            (curSamp,curEvents)=ftc.wait(-1,nEvents,timeout) # Block until there are new events to process
            if curEvents>nEvents :
                evts=ftc.getEvents([nEvents,curEvents-1]) 
                nEvents=curEvents # update record of which events we've seen
                for evt in evts:
                    if evt.type == "exit": endExpt=1
                    ev_str = evt.type + '.' + str(evt.value)
                    if ev_str in events.index.values:
                        ev_list.append(ev_str)
                        priors = calc_priors(ev_list)
                        print(priors)

                    print(evt)

        ftc.disconnect() # disconnect from buffer when done


    echoClient(commands)
