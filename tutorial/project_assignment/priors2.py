import pandas as pd
import numpy as np

commands_columns = 'tv.1 tv.2 tv.3 tv.end sos.food sos.pain sos.toilet call.1 call.2 call.3 navigate.left navigate.right navigate.up navigate.down'.split()

NR_EVENTS = 5

probs = pd.DataFrame(np.zeros((NR_EVENTS, len(commands_columns))), columns=commands_columns)

commands = pd.DataFrame(
    [c.split('.') for c in commands_columns],
    columns=['event', 'value'],
    index=commands_columns)


probs.loc[0, 'navigate.left'] = 1
probs.loc[1, 'navigate.left'] = 1
probs.loc[2, 'navigate.left'] = 1
probs.loc[3, 'tv.1'] = 1
probs.loc[4, 'sos.food'] = 1

#error costs
cost_navigation_error = 15
cost_tv_error = 5
cost_communicate_error = 15
cost_sos_error = 60

sent_list = commands.loc['navigate.left navigate.left navigate.left tv.1 sos.food'.split()]

print(commands)

# number of occurrences during demo / number of options

default_priors = {
    'tv': 1 / 3,
    'sos': 1 / 3,
    'call': 1 / 3,
    'navigate': 12 / 4
}

## priors

commands['priors'] = commands.event.replace(default_priors)

print(commands.priors)

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

print(dirs)


if commands.iloc[-1].event == 'navigate':
    last_dir = commands.index[-1]
    print(navevents)
    commands.loc[last_dir, 'priors'] *= 2.5
    commands.loc[dirs.loc[last_dir].ldir, 'priors'] *= .75
    commands.loc[dirs.loc[last_dir].rdir, 'priors'] *= .75
    commands.loc[dirs.loc[last_dir].opposite, 'priors'] = 0


final_priors = CERTAINTY * commands.priors + (1 - CERTAINTY) * error_priors
