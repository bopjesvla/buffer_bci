#!/bin/bash -x
svn mkdir -m 'Initial Version' svn+ssh://mmmxserver.nici.ru.nl/Volumes/Xserver\ RAID/BCI\ code/Repository/svn/BCI/$1
cd $1
svn co svn+ssh://mmmxserver.nici.ru.nl/Volumes/Xserver\ RAID/BCI\ code/svn/BCI/$1 .
svn propset svn:ignore "*~" .
svn add *
svn ci -m 'Initial Version'
