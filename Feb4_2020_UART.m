%This code works with pplcount_lab_xwr68xx.bin
% C:\ti\mmwave_industrial_toolbox_4_0_1\labs\people_counting\68xx_people_counting\prebuilt_binaries
% and Config2.cfg


% Constants magic numbers
DataBufferSize = 65536;
SerialDataBaud = 921600;    % UART Data port baudrate
SerialCfgBaud = 115200;     % UART Configuration port baudrate

maxBytesAvailable = 0;


% We declare the length of every field in output packet here
% file:///C:/ti/mmwave_sdk_03_02_00_04/packages/ti/demo/xwr68xx/mmw/docs/doxygen/html/index.html
% We use MmwDemo_output_message_header_t Struct to get this data
% These field lengths are used to find sprcific data 
NoOfBytes_Total_Header = 40;

NoOfBytes_Header_Version = 4;
NoOfBytes_Header_PacketLength = 4;
NoOfBytes_Header_Platform = 4;
NoOfBytes_Header_FrameNo = 4;
NoOfBytes_Header_TimeStamp = 4;
NoOfBytes_Header_DetectedObj = 4;
NoOfBytes_Header_numTLVs = 4;
NoOfBytes_Header_SubFrameNo = 4;

NoOfBytes_TLVType = 4;
NoOfBytes_TLVDataBytes = 4;

syncPatternUINT64 = typecast(uint16([hex2dec('0102'),hex2dec('0304'),hex2dec('0506'),hex2dec('0708')]),'uint64')
    
%magicBytes = typecast(uint8(A(9:16)), 'uint64')
%TotalPacketsUINT32 = typecast(uint8(A(13:16)), 'uint32') 

% Serial Port Setup
% Close all the serial port at start of this prog 
if ~isempty(instrfind('Type','serial'))
    disp('Serial port(s) already open. Re-initializing...');
    delete(instrfind('Type','serial'));  % delete open serial ports.
end

% UART Configuration port setup
SerialConfigPort = serial("COM11",'BaudRate',SerialCfgBaud, 'Parity','none','Terminator','LF');
fopen(SerialConfigPort);

% UART Data port setup
SerialDataPort = serial("COM10",'BaudRate',SerialDataBaud,'Terminator', '','InputBufferSize', DataBufferSize, 'Timeout',10, 'ErrorFcn',@dispError);
fopen(SerialDataPort);

%Read config file 
cliCfg = readCfg('config2.cfg');

mmwDemoCliPrompt = char('mmwDemo:/>');

fprintf('Sending configuration from %s file to IWR16xx ...\n', 'config3.cfg');
for k=1:length(cliCfg)
    fprintf(SerialConfigPort, cliCfg{k});
    fprintf('%s\n', cliCfg{k});
    echo = fgetl(SerialConfigPort) % Get an echo of a command
    done = fgetl(SerialConfigPort) % Get "Done" 
    prompt = fread(SerialConfigPort, size(mmwDemoCliPrompt,2)); % Get the prompt back 
end

i1=0;
%while (i1<3)
while (isvalid(SerialDataPort))
    
    bytesAvailable = get(SerialDataPort,'BytesAvailable')
    if(bytesAvailable > maxBytesAvailable)
        maxBytesAvailable = bytesAvailable;
    end
    
    %Getting the Header data from serial buffer
    [A, byteCount] = fread(SerialDataPort, NoOfBytes_Total_Header, 'uint8')
    %i1=i1+1   
    A    
    D = A.'; % Converting column array to row array
    % MagicBytes B is the First bytes of the Header packet
    B = [2 1 4 3 6 5 8 7];
    %Converting B array elements to 8 bit integers
    C = uint8(B);    
    % Comparing the buffer data with magic bytes to get location
    % Index() returns the starting indices of any occurrences of PATTERN in TEXT. 
    Index  = strfind(D, C)
    % Printing the start bits of header (2 1 4 3 6 5 8 7) using the Index
    
    
    if(Index)
        
        Received_magicBytes = zeros(1,length(B));
        i=0;
        for n = Index:Index+length(B)-1       
            i=i+1;
            Received_magicBytes(i) = A(n);
        end
        Received_magicBytes
        
        %Extracting the Packet Length information from the Header package
        PacketLength = zeros(1,NoOfBytes_Header_PacketLength);
        arrayStart = Index+length(B)+NoOfBytes_Header_Version; %Start of Packert Length from Data (1 is not substracted as in arrayEnd)
        arrayEnd = arrayStart + NoOfBytes_Header_PacketLength-1; %End of Packert Length from Data (Notice 1 is substracted in the end)
%         i=0;
%         for n = arrayStart:arrayEnd
%             i=i+1;
%             PacketLength(i) = D(n);
%         end    
        %PacketLength;
        PacketLength_uint32 = typecast(uint8(D(arrayStart:arrayEnd)), 'uint32')
        
        
        %Frame Number information extracted from the Header package
        FrameNo = zeros(1,NoOfBytes_Header_FrameNo);
        arrayStart = arrayEnd + 1 + NoOfBytes_Header_Platform; %Start of Packert Length from Data (1 is not substracted as in arrayEnd)
        arrayEnd = arrayStart+NoOfBytes_Header_FrameNo-1; %End of Packert Length from Data (Notice 1 is substracted in the end)
%         i=0;
%         for n = arrayStart:arrayEnd
%             i=i+1;
%             FrameNo(i) = D(n);
%         end    
        %FrameNo
        FrameNo_uint32 = typecast(uint8(D(arrayStart:arrayEnd)), 'uint32')
        
        %No of Detected Objects information extracted from the Header package
        NoofDetectedObj = zeros(1,NoOfBytes_Header_FrameNo);
        arrayStart = arrayEnd + 1 + NoOfBytes_Header_TimeStamp; %Start of Detected object from Data (1 is not substracted as in arrayEnd)       
        arrayEnd = arrayStart + NoOfBytes_Header_DetectedObj - 1; %End of Detected object from Data (Notice 1 is substracted in the end)
%         i=0;
%         for n = arrayStart:arrayEnd
%             i=i+1;
%             NoofDetectedObj(i) = D(n);
%         end    
        %Detected object in uint32 format
        NoofDetectedObj = typecast(uint8(D(arrayStart:arrayEnd)), 'uint32')
        
        
        %No of TLV information extracted from the Header package
        NoofTLVs = zeros(1,NoOfBytes_Header_numTLVs);
        arrayStart = arrayEnd + 1; %Start of Detected object from Data (1 is not substracted as in arrayEnd)       
        arrayEnd = arrayStart + NoOfBytes_Header_numTLVs - 1; %End of Detected object from Data (Notice 1 is substracted in the end)
%         i=0;
%         for n = arrayStart:arrayEnd
%             i=i+1;
%             NoofDetectedObj(i) = D(n);
%         end    
        %Detected object in uint32 format
        NoofTLVs = typecast(uint8(D(arrayStart:arrayEnd)), 'uint32')
        
        
        if (NoofTLVs == 0)
            fprintf("No Object detected\n");    
            
            %No of TLV information extracted from the Header package
            %NoOfBytes_Header_SubFrameNo
            Len_paddedData = 0;
            Len_paddedData = PacketLength_uint32 - byteCount
            Len_paddedData_double = double(Len_paddedData);
            PaddedData = zeros(1,Len_paddedData);
            arrayStart = arrayEnd + 1 + NoOfBytes_Header_SubFrameNo %Start of Detected object from Data (1 is not substracted as in arrayEnd)       
            arrayEnd = arrayStart + Len_paddedData - 1 %End of Detected object from Data (Notice 1 is substracted in the end)
    %         i=0;
    %         for n = arrayStart:arrayEnd
    %             i=i+1;
    %             NoofDetectedObj(i) = D(n);
    %         end    
            %Detected object in uint32 format
           %Getting the Header data from serial buffer
            [A_Padded] = fread(SerialDataPort, Len_paddedData_double, 'uint8')
            %i1=i1+1    
            D_Padded = A_Padded.'; % Converting column array to row array
    % MagicBytes B is the First bytes of the Header packet 
            
            
            %PaddedData = typecast(uint8(D_Padded(arrayStart:arrayEnd)), 'uint32')
            
            
            
        else
            % Getting the data from the buffer
        
            NoOfBytes_TotalDataLength = 0;
            NoOfBytes_TotalDataLength = PacketLength_uint32 - NoOfBytes_Total_Header               
            [TLV_Data, byteCount] = fread(SerialDataPort, double(NoOfBytes_TotalDataLength), 'uint8')

            TLV_DataRow = TLV_Data.'; % Converting column array to row array


            %Type of Data information extracted from the package
            TLVType = zeros(1,NoOfBytes_TLVType);
            arrayStart = 1; %Start of Packert Length from Data (1 is not substracted as in arrayEnd)
            arrayEnd = arrayStart+NoOfBytes_TLVType-1; %End of Packert Length from Data (Notice 1 is substracted in the end)
    %         i=0;
    %         for n = arrayStart:arrayEnd
    %             i=i+1;
    %             TLVType(i) = TLV_DataRow(n);
    %         end    
            %TLV type
            TLVType = typecast(uint8(TLV_DataRow(arrayStart:arrayEnd)), 'uint32')


            %Number of Data bytes information extracted from the package
            DataBytes_TLV = zeros(1,NoOfBytes_TLVDataBytes);
            arrayStart = 1+NoOfBytes_TLVType; %Start of Packert Length from Data (1 is not substracted as in arrayEnd)
            arrayEnd = arrayStart+NoOfBytes_TLVDataBytes-1; %End of Packert Length from Data (Notice 1 is substracted in the end)
    %         i=0;
    %         for n = arrayStart:arrayEnd
    %             i=i+1;
    %             DataBytes_TLV(i) = TLV_DataRow(n);
    %         end    
            %TLV type
            DataBytes_TLV = typecast(uint8(TLV_DataRow(arrayStart:arrayEnd)), 'uint32')

            % Each byte in 4 byte data belongs to x cordinate, y cordinate, z
            % cordinate and velocity respectively so we divide total data field
            % by 4
            Total_DataField = (DataBytes_TLV/4)
            %Start of Packert Length from Data (1 is not substracted as in arrayEnd)
            arrayStart = 1+NoOfBytes_TLVType+NoOfBytes_TLVDataBytes; 
            %End of Packert Length from Data (Notice 1 is substracted in the end)
            arrayEnd = arrayStart+NoOfBytes_TLVDataBytes-1; 
            filename = 'Feb4_2020Data_test.xlsx';
            %Parsing the TLVs with x,y,z and velocity data
            for tlv_parsing_var = 1:Total_DataField
                tlv_parsing_var
                x_cordinate = TLV_DataRow(arrayStart)
                y_cordinate = TLV_DataRow(arrayStart+1)
                z_cordinate = TLV_DataRow(arrayStart+2)
                velocity = TLV_DataRow(arrayStart+3)
                arrayStart = arrayStart+4;
                fprintf("End of TLV Parsing\n");
            end
            fprintf("End of TLV Parsing for loop\n");
        end              
    else 
        fprintf("Bad Data\n");
        %break;
    end
end

% Function to read the configuration from .cfg file and
% Writing this config to the board
function config = readCfg(filename)
    config = cell(1,100);
    fid = fopen(filename, 'r');
    if fid == -1
        fprintf('File %s not found!\n', filename);
        return;
    else
        fprintf('Opening configuration file %s ...\n', filename);
    end
    tline = fgetl(fid);
    k=1;
    while ischar(tline)
        config{k} = tline;
        tline = fgetl(fid);
        k = k + 1;
    end
    config = config(1:k-1);
    fclose(fid);
end


%Function to get the data from Buffer
% function datainfo = readData()
%     
% end