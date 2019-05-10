cd trunk
svn update  # record the head version number for logging info: (YYY)
svn log --stop-on-copy svn+ssh://server/path/to/branch # find the version we branched from (XXX)
svn merge -r XXX:HEAD svn+ssh://server/path/to/branch #merge changes into trunk
# conflict resolution
svn ci -m 'MERGE branch XXX:YYY into trunk'
# logging
cd branch
svn ci -m 'MERGE branch XXX:YYY into trunk'