import pandas as pd
import numpy as np

commands_columns = 'tv.1 tv.2 tv.3 tv.end sos.food sos.pain sos.toilet call.1 call.2 call.3 navigate.left navigate.right navigate.up navigate.down'.split()

NR_EVENTS = 5

# probs = pd.DataFrame(np.zeros((NR_EVENTS, len(commands_columns))), columns=commands_columns)

CMDS = pd.DataFrame(
    [c.split('.') for c in commands_columns],
    columns=['event', 'value'],
    index=commands_columns)


# probs.loc[0, 'navigate.left'] = 1
# probs.loc[1, 'navigate.left'] = 1
# probs.loc[2, 'navigate.left'] = 1
# probs.loc[3, 'tv.1'] = 1
# probs.loc[4, 'sos.food'] = 1

#error costs
cost_navigation_error = 15
cost_tv_error = 5
cost_communicate_error = 15
cost_sos_error = 60


# probs.loc[0, 'navigate.left'] = 1
# probs.loc[1, 'navigate.left'] = 1
# probs.loc[2, 'navigate.left'] = 1
# probs.loc[3, 'tv.1'] = 1
# probs.loc[4, 'sos.food'] = 1

def calc_priors(ev_list):
    commands = CMDS.copy()

    sent_list = commands.loc[ev_list]
    print('sent', sent_list)

    # number of occurrences during demo / number of options

    default_priors = {
        'tv': cost_tv_error * 3 / 3,
        'sos': 2 * cost_sos_error * 1 / 3, # 2 errors: 1 for sos.on, 1 for sos.*
        'call': cost_communicate_error * 2 / 3,
        'navigate': cost_navigation_error * 11 / 4
    }

    ## priors

    commands['priors'] = commands.event.replace(default_priors)

    print('god',commands.priors)

    tvevents = sent_list[sent_list.event == 'tv']
    navevents = sent_list[sent_list.event == 'navigate']

    if len(tvevents) == 0 or tvevents.iloc[-1].value == 'end':
        commands.loc['tv.end', 'priors'] = 0
    else:
        commands.loc['tv.end', 'priors'] = 1
        commands.loc[tvevents.index[-1], 'priors'] = 0


    error_priors = commands.priors.copy()

    CERTAINTY = .8
    dirs = 'navigate.' + pd.DataFrame({'normal':['up', 'right', 'down', 'left']})
    dirs['ldir'] = np.roll(dirs.normal, 1)
    dirs['rdir'] = np.roll(dirs.normal, -1)
    dirs['opposite'] = np.roll(dirs.normal, 2)
    dirs = dirs.set_index('normal')

    if len(sent_list) > 0 and sent_list.iloc[-1].event == 'navigate':
        last_dir = sent_list.index[-1]
        commands.loc[last_dir, 'priors'] *= 2.5
        commands.loc[dirs.loc[last_dir].ldir, 'priors'] *= .75
        commands.loc[dirs.loc[last_dir].rdir, 'priors'] *= .75
        commands.loc[dirs.loc[last_dir].opposite, 'priors'] = 0

    final_priors = CERTAINTY * commands.priors + (1 - CERTAINTY) * error_priors

    return final_priors / sum(final_priors.values)

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

    def send_prior_loop(events, timeout=2):

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
                        bufhelp.sendEvent('priors', priors.to_csv())

                    # print(evt)

        ftc.disconnect() # disconnect from buffer when done

    send_prior_loop(CMDS)
