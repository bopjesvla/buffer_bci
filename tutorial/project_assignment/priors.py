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

sent_list = commands.loc['navigate.left navigate.left navigate.left tv.1 sos.food'.split()]

print(probs)

# number of occurrences during demo / number of options

default_priors = {
    'tv': 1 / 3,
    'sos': 1 / 3,
    'call': 1 / 3,
    'navigate': 12 / 4
}

## priors

commands['priors'] = commands.event.replace(default_priors)

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

tvevents = sent_list[sent_list.event == 'tv']
navevents = sent_list[sent_list.event == 'navigate']

if len(navevents) > 0:
    last_dir = navevents[-1]

    commands.priors.loc[last_dir] *= 2.5
    commands.priors.loc[dirs.loc[last_dir].ldir] *= .75
    commands.priors.loc[dirs.loc[last_dir].rdir] *= .75
    commands.priors.loc[dirs.loc[last_dir].opposite] = 0

final_priors = CERTAINTY * commands.priors + (1 - CERTAINTY) * error_priors
