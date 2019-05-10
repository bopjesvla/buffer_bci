function jsonRPC_receive(port,verb)
% Initializes the socket connection, the midi connection and the screen
if ( nargin < 1 ) port=6666; end;
if ( nargin < 2 ) verb=1; end;

% Open listener socket 
global socket; % persistent so can re-start listen if error
if ( isempty(socket) ) 
   server = java.net.ServerSocket(port);
   disp(sprintf('Waiting for incoming connection on port %.0d...', port));
   socket = server.accept();
   disp(sprintf('Connected to %s', char(socket.toString)));
   server.close(); % Close listener socket -- but leave connected client socket open
end

% Listen to the socket
in = java.io.BufferedReader(java.io.InputStreamReader(socket.getInputStream()));
nesting = 0;
str = [];
while(true) % loop-forever listening for commands to execute
   chr = in.read(); 
   if ( chr == '{' )
      nesting = nesting + 1;
   end
   if ( nesting > 0 )
      if ( verb>1 ) fprintf('%c',chr); end;
      str = [str chr];
   end
   if( chr =='}' )
      nesting = nesting - 1;
      if ( nesting == 0 )
         s = unserialize(str, 'json');
         method=s.method;
         if ( isfield(s,'params') ) params=s.params; else params={}; end;
         if ( ~iscell(params) ) params={params}; end;
         if ( verb>0  ) disp({method params{:}}); end;
         feval(method, params{:}); 
         str = [];
      end
   end
end

socket.close();
return;
%---------------------------------------------------------------
function testCase()
   