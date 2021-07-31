%% Introduction
%Bit reader companion to RandomDataGenerator_BCT.m from CU-E3
%Developed by Nolan Pearce, May 2021

%Problem statement: 

%% Clear

close all;
clear;
clc;


%% Read Binary data

%1152-bit frame, must read as binary bit stream
fileID = fopen('CU-E3_DataBlock_Jan1_2020_5000Packets_decimalSequeneceNumber.bin');
BitRaw = fread(fileID,'*uint8');
fclose(fileID);

%padding improvements until 'packet' taken from: https://bit.ly/3yD2GJv
%Convert to binary with 8-bit length and add padding if needed
BitRaw = dec2bin(BitRaw(:), 8) - '0';    

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

%% Header Transformation

%Get the header you need and store it into a matrix
%Assuming I don't need the random data from the actual packet

HeaderLength = 1152-1024; %Taken from RDG_BCT.m

%Cut off the actual packet
PacketHeaders = packet(:,1:HeaderLength);

%% Sequence Decoding
%Decode the sequence number and store it in the CSV
%Units of measurement - 50 packets

%Get the relevant 32-bit header portion (from NASA CommProc)
SequencePortion = PacketHeaders(:,(33:64));

%Convert from binary bit stream to hexadecimal integer

for n=1:50
    
%Requires Data Acquisition Toolbox:
hexSeq(n,:) = binaryVectorToHex(SequencePortion(n,:)); 

end

%Create and store in 1st column of CSV

FinalCell = cell(50, 4);
FinalCell(:,1) = cellstr(hexSeq);

%% Timestamp Decoding
%Similar procedure - decode timestamp and store in CSV
%Units of measurement - 50 packets
%Microseconds are ignored - can also not be igonored if desired

%Get the relevant 32-bit header portion (from NASA CommProc)
TimePortion = PacketHeaders(:,(65:96));

%Convert from binary bit stream to hexadecimal integer

for n=1:50
    
%Requires Data Acquisition Toolbox:
decTime(n,:) = bi2de(TimePortion(n,:)); 

end

%Store as 2nd Column in Matrix
FinalCell(:,2) = cellstr(num2str(decTime));

%% Bit Error Computation
%Calculate the number of bit errors and display them in the 3rd csv column

%Operates with either a reference packet at same sequence (combined with
%channel model) or a packet at different sequence?
teamkey_Hex = 'EB901E1E';
time_date = datetime('2020-01-01 00:00:00');
quantityOfPackets = 50;

Trusted_packet = commsProc(teamkey_Hex,time_date, quantityOfPackets);
%commsProc('EB901E1E',datetime('2020-01-01 00:00:00'),50)

TrustedData = BitReaderFunction(Trusted_packet);
TrustedData = TrustedData(:,1:length(TrustedData)-1);
ErrorData = BitReaderFunction(BitStream);
ErrorData = ErrorData(:,1:length(ErrorData)-1);

BitErrors = xor(TrustedData,ErrorData);
BitErrorNum = zeros(1,psize);
for m=1:psize
    %BitErrors(m,:) = xor(TrustedData(m,:),ErrorData(m,:));
    for k=1:length(BitErrors(m,:))
        if BitErrors(m,k) == 1
            BitErrorNum(m) = BitErrorNum(m) + 1;
        end
    end
end

%Store the vector into the CSV

FinalCell(:,3) = cellstr(num2str(BitErrorNum.'));

%% Byte Error Computation
%Calculate the number of 8-bit byte errors and display them in the 4th csv
%column
NumBytes = length(TrustedData(1,:))/8; %Should be 28
ByteErrorVector = zeros(psize,NumBytes);
ByteStarts = zeros(1,NumBytes);
%Find ByteStarts Matrix
ByteCounter = 1;
TempErrorVector = zeros(1,8);
ByteErrorSum = zeros(1,psize);
for g=1:length(BitErrors)
    if mod(g,8) == 0 && g ~= length(TrustedData(1,:))
        %ByteStarts(ByteCounter) = g+1;
        TempErrorVector = xor(TrustedData(m,g+1:g+8),ErrorData(m,g+1:g+8));
        TempErrorSum = 0;
        %calculate bit errors
        for b=1:8
            if TempErrorVector(b) == 1
                TempErrorSum = TempErrorSum + 1;
            end
        end
        ByteErrorVector(m,ByteCounter) = TempErrorSum;
        
        ByteCounter = ByteCounter + 1;     
    end
    for c=1:length(ByteErrorVector(1,:))
    if  ByteErrorVector(m,c) == 1
        ByteErrorSum(m) = ByteErrorSum(m) + 1;
    end
    end
end

%Sum Byte Errors


FinalCell(:,4) = cellstr(num2str(ByteErrorSum.'));


%Operates with either a reference packet at same sequence (combined with
%channel model) or a packet at different sequence?

%% Data formatting and Storage

%Add labels on top row
FinalCell_Label = cell(51,4);
FinalCell_Label(1,:) = {'Sequence Number','TimeStamp','Bit Errors','Byte Errors'};
FinalCell_Label(2:51,:) = FinalCell;

CSV_Table = cell2table(FinalCell_Label);
writetable(CSV_Table, 'CQC_Error_Checking.csv');









