function channum=label2channnum(label);
num1=double(label(1)-64);
num2=str2num(label(2:end));
channum=(num1-1)*32+num2;
