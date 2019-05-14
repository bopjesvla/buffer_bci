function label=channum2label(channum);
letter=char(64+mod(channum,32));
number=rem(channum,32);
label=[letter,num2str(number)];