function [packetData] = BitReaderFunction(bitstream)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
BitRaw = dec2bin(bitstream(:), 8) - '0';    

%Convert into bit stream
BitStream = reshape( BitRaw.', [],1);

%Set packet size
psize = 50;

%See if there is a remainder between raw bits and expected #bits
remain=rem(size(BitStream,1),psize);

%BitStream(end+psize-remain)=0; -> Not quite sure what this does, it only
%appends a '0' onto the end messing with the packet length

%Pack bits into 50 packets (rows) the total number of bits (1152) long
packet = reshape( BitStream.', [],50);
%reshape it for my own sake
packet = packet.';

%% Error Comparison

%Get the "random" bits used for error comparison from the function and the
%data

DataLength = 1024;
packetData = packet(:,129:129+DataLength);


%Store these bits


end

