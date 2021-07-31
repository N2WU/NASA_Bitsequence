function [dataPacket_array] = commsProc(teamKey_Hex,time_date, quantityOfPackets)
% Taken from Brodie Wallace
% 2/15/19 -> 01 Jun 2021
% CU-E3

% CQC: Random Data Generator

%% Define Congruent Generator Terms

% Define Constants provided by CQC
a = 1664525;
b = 1013904223;
M = 2^32;

% Define provided teamkey and convert to binary
%teamKey_Hex = 'EB901E1E';
teamKey_dec = hex2dec(teamKey_Hex);
teamKey_bin = de2bi(teamKey_dec,'left-msb');

%% Define Times

% Read current time for start of communication sequence, convert time to
% binary
%time_date = datetime('2020-01-01 00:00:00');
timeSeconds_dec = posixtime(time_date);
timeSeconds_bin = de2bi(timeSeconds_dec,'left-msb');

% Ensure that the binary posix time in seconds has a length of 32 bits
num_bits_timeSeconds_bin = length(timeSeconds_bin);
timeSeconds_bin_zeros = zeros(1,32-num_bits_timeSeconds_bin);
timeSeconds_bin = [timeSeconds_bin_zeros timeSeconds_bin];

% Determine time in microseconds past the posix time
% Padded with straight zeros for simplicity
timeMicroSeconds_bin = zeros(1,32);

%% Calculate Seed Value

% Bitwise XOR provided teamkey and the initial posix time
XOR_TeamKey_Time_bin = bitxor(teamKey_bin, timeSeconds_bin);

%% Calculate Random Data Block

% Set quantity of packets to be generated
%quantityOfPackets = 50;

for n = 1:quantityOfPackets

% Determine the data block sequence number
dataBlockSequenceNumber_dec = n;
dataBlockSequenceNumber_bin = de2bi(dataBlockSequenceNumber_dec, 32, 'left-msb');

% Store data block sequence number for writing to the communications packet
dataBlockSequenceNumber_bin_storage(n,:) = dataBlockSequenceNumber_bin;
    
% XOR the binary value of the team key time xor with the data block sequence number
XOR_TeamKey_Time_SequenceNumber_bin = bitxor(XOR_TeamKey_Time_bin, dataBlockSequenceNumber_bin);       
XOR_TeamKey_Time_SequenceNumber_dec = bi2de(XOR_TeamKey_Time_SequenceNumber_bin , 'left-msb');

% Calculate the dividend for the modulo function
dividend = (a*XOR_TeamKey_Time_SequenceNumber_dec + b);

% Calculate the first 32 bit portion of the random data in decimal using the modulo function
x1 = mod(dividend , M);

x_dec(1) = x1;

for counter = 2:(32)
   
    % Calculate the decimal values of the additional 31 random data numbers
    dividend = (a*x_dec(counter-1) + b);
    x_dec(counter) =  mod(dividend , M);

end

    % Convert the random data from decimal to binary
    x_bin_column((n-1)*32+1:(n*32),:) = dec2bin(x_dec(1:32)); 
    
end

% Reorder the binary random data vectors into a single character string
for counter = 1:length(x_bin_column)
    
    if counter == 1
        x_bin_row = x_bin_column(counter,:);
    else
        x_bin_row = strcat(x_bin_row,x_bin_column(counter,:));
    end
    
end

%% Format Entire Packet For Transmission

% Concatenate the teamkey, sequence number, time in seconds, and time in
% micro seconds to generate a packet header
teamKey_SequenceNumber_str = strcat(num2str(teamKey_bin), num2str(dataBlockSequenceNumber_bin_storage(1,:)));
teamKey_SequenceNumber_timeSeconds_str = strcat(teamKey_SequenceNumber_str, num2str(timeSeconds_bin));
teamKey_SequenceNumber_timeSeconds_timeMicroSeconds_str = strcat(teamKey_SequenceNumber_timeSeconds_str, num2str(timeMicroSeconds_bin));

% remove spaces from string
idx = strfind(teamKey_SequenceNumber_timeSeconds_timeMicroSeconds_str,' ');
teamKey_SequenceNumber_timeSeconds_timeMicroSeconds_str(idx)=[];

% concatenate the team key-sequence number-time in seconds-time in
% microseconds string with the first 1024 bits of random data to generate a
% single 1152 bit frame
dataPacket_str = strcat(teamKey_SequenceNumber_timeSeconds_timeMicroSeconds_str, x_bin_row(1:1024));

% Concatenate each packet header with their corresponding 1024 bits of
% randomly generated data and append to a single character string
for i=2:(quantityOfPackets)
    
    % Concatenate the teamkey, sequence number, time in seconds, and time in
    % micro seconds
    teamKey_SequenceNumber_str = strcat(num2str(teamKey_bin), num2str(dataBlockSequenceNumber_bin_storage(i,:)));
    teamKey_SequenceNumber_timeSeconds_str = strcat(teamKey_SequenceNumber_str, num2str(timeSeconds_bin));
    teamKey_SequenceNumber_timeSeconds_timeMicroSeconds_str = strcat(teamKey_SequenceNumber_timeSeconds_str, num2str(timeMicroSeconds_bin));

    % remove spaces
    idx = strfind(teamKey_SequenceNumber_timeSeconds_timeMicroSeconds_str,' ');
    teamKey_SequenceNumber_timeSeconds_timeMicroSeconds_str(idx)=[];
    
    dataPacket_str = strcat(dataPacket_str, teamKey_SequenceNumber_timeSeconds_timeMicroSeconds_str);
    dataPacket_str = strcat(dataPacket_str, x_bin_row((i-1)*1024+1:((i)*1024)));
    
end

% Convert data packet string into an array for saving to binary file
for counter = 1:length(dataPacket_str)
    
   dataPacket_array(counter) = str2num(dataPacket_str(counter));
   
end

%% Print Data to txt file
%{
fileID = fopen('CU-E3_DataBlock_Jan1_2020_260Packets_decimalSequeneceNumber.txt','w');
fprintf(fileID, '%s', dataPacket_str);
fclose(fileID);
%}
%% Print Data to binary file
%{
fileID = fopen('CU-E3_DataBlock_Jan1_2020_5000Packets_decimalSequeneceNumber.bin','w');
fwrite(fileID, dataPacket_array, 'ubit1', 'ieee-be');
fclose(fileID);
%}
end

