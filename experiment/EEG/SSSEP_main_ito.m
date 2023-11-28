clear all 
close all
clc

subname = input('Type subject name > ', 's');
condition = input('Type condition > ', 's');

rectime = 20;
PolymateMini_SSSEP_8ch_ito(subname , condition, rectime);