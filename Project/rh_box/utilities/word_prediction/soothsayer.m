function [prediction, ret, err] = soothsayer(text,model)
% Input
%  text: text currently being typed
%  model: language model to be used for word completion prediction
%
% Output
%  prediction: the predicted word
%  ret: the information returned by soothsayer server
%  err: non-empty in case an error occured during the http-request call

err = [];
ret = [];
prediction = [];
if nargin < 1
   return
end
if nargin < 2
   model = 'allmail'; 
end

% webserver producing prediction
url = 'http://soothsayer.cls.ru.nl/';

space_at_end = text(end)==' ';

% split text into words
words = strtokall(text,' ');

% only use last three words and combine with underscores
text = sprintf('%s_',words{end-(min(2,numel(words)-1)):end}); 
if ~space_at_end, text(end)=[]; end % preserve possible space at end

% compile http request string
httpcall = [url 'predict?model=' model '&text=' text '&show_source=True'];

% do the request and get the prediction
try
   url = java.net.URL(httpcall);
   in = url.openStream();
   timeout = false; tic
   while in.available() == 0 
      if toc >= 0.1, timeout = true; break; end
   end
   if timeout
      err.message = 'http timeout request';
   else
      incoming = java.io.BufferedReader(java.io.InputStreamReader(in));
      ret = char(incoming.readLine());
   end
catch err
end
% parse returned result, get prediction
prediction = strtok(ret,',');

% NOTE: the returned prediction is what soothsayer thinks what should
% become the currently spelled word. In an application correct for already
% spelled characters!

