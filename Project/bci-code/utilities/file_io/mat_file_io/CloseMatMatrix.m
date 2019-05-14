function mmf = CloseMatMatrix(mmf)

mmf.closed = 1;
fclose(mmf.fid);
