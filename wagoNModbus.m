function [w] = wagoNModbus(ipAddress, polarity, virtual)
% wago
% Creates object to handle solenoid control through a Wago controller
% and initializes communication with the controller.
% The opbject should be created only once (i.e. the wago function should
% be called just once).
% NOTE:  This version uses the open source NModbus library
%        that can be donwloaded at http://code.google.com/p/nmodbus/
%        The NModbus DLL files must be in a folder named NModbus inside
%        the folder where this function is
%
% w = wagoNModbus(ipAddress, polarity, [virtual])
%
% ipAddress = String with IP address of controller
% polarity = Vector with the polarity for each valve
%            polarity(j) = 0 --> (j-1)th valve is normally open
%            polarity(j) = 1 --> (j-1)th valve is normally closed
%            Valve numbers start at 0.
% virtual = Optional boolean parameter that when true makes the valve
%           controller not connect to the Wago, but it still accepts all
%           commands.  Defaults to false when absent.
%
% w = Wago object
%
% Methods:
% --------
% w.setValves(numbers, values)
%   Set the valves specified by numbers to the states specified in
%   values (0 = open or 1 = closed).  Valve numbers start at 0.
%
% values = w.getValves(numbers)
%   Get the valve values specified by numbers (0 = open or 1 = closed).
%   Valve numbers start at 0.
%
% w.setMemory(addressOffset, values)
% Write vector values to non-volatile memory, with an address offset.
% addressOffset must be >=0 and <= 12288
%
% values = w.getMemory(addressOffset, totalWords)
% Read vector of values from non-volatile memory, with an address offset.
% addressOffset must be >=0 and <= 12288
%
% w.close()
%   Close communication with the Wago controller.
%   If the object won't be used again, must clear w after closing.
%
% [error, description] = w.error()
%   Returns the error code and description produced by the last method called.
%   
%
% R. Gomez-Sjoberg  4/14/11
% L. Ardila-Perez   1/11/12
% C. Díaz-Botía     2/21/12

myTag = 'wagoNModbus';

if ~exist('virtual', 'var')
    virtual = false;
end

handle = int32(0);
wagoError = 0;
totalValves = length(polarity);
totalBytes = ceil(totalValves/8);
totalWords = ceil(totalBytes/2);
wordPadLength = totalWords*16 - totalValves;
wagoMaster = [];

currValues = zeros(1, totalValves);

w.close = @wagoClose;
w.error = @wagoGetError;

if ~virtual
    w.setValves = @wagoSetValves;
    w.getValves = @wagoGetValves;
    w.setMemory = @wagoSetMemory;
    w.getMemory = @wagoGetMemory;
    wagoOpen;
    % Read current state of all valves
    wagoGetValves([0:(totalValves-1)]);
else
    ipAddress = 'Virtual';
    w.setValves = @wagoSetValvesVirtual;
    w.getValves = @wagoGetValvesVirtual;
    w.setMemory = @wagoSetMemoryVirtual;
    w.getMemory = @wagoGetMemoryVirtual;
    wagoVirtualMemory = zeros(1, 12288);
end

% Open communication
    function wagoOpen

        modbusObj = NET.addAssembly([fileparts(which('wagoNModbus.m')) '\NModbus\Modbus.dll']);
        systemObj = NET.addAssembly('System');

        if isempty(wagoMaster)
            try
                tcpClient = System.Net.Sockets.TcpClient(ipAddress, 502);
                wagoMaster = Modbus.Device.ModbusIpMaster.CreateIp(tcpClient);
            catch
                wagoError = 999;
            end
        end

    end %wagoOpen


% Close communication
    function wagoClose(~)
        if ~virtual
            try
                wagoMaster.Dispose();
                clear wagoMaster;
                delete(modbusObj);
                delete(systemObj);
            catch
                wagoError = 999;
            end
        end
   end %wagoClose

% Return error code
    function [err, descr] = wagoGetError
        descr = '';
        if wagoError < 0
            err = 2^31 + wagoError;
            if err == hex2dec('80000000')
                err = 0;
            end
        end
        switch wagoError
            case 0
                descr = 'No error';
            case 1
                descr = 'Lengths of numbers and values vectors do not match';
            case 2
                descr = 'An element in the numbers vector is out of bounds';
            case 10
                descr = 'Invalid non-volatile memory offset value';
            case 11
                descr = 'Vector to write/read to/from non-volatile memory is out of bounds';
            case 999
                descr = 'Unknown error';
            otherwise
                descr = 'DLL error';
        end
        err = wagoError;
    end %wagoGetError

% Convert a vector with valve values for all valves to a vector of words,
% where each valve is a bit in one of the words
    function words = wagoValues2Words(values)
        values = [values zeros(1, wordPadLength)];
        words = uint16(zeros(1, totalWords));
        for ii = 1:totalWords
            idx = 16*(ii - 1) + 1;
            % Extract block of 16 valves and converto to binary string
            sWord = char(values((idx + 15):-1:idx) + 48);
            words(ii) = bin2dec(sWord);
        end
    end

% Set state of one or more valves
    function wagoSetValves(numbers, values)
        % Set the valves secified in vector numbers to the states
        % specified in vector values (0 = open or 1 = closed).
        % Valve numbers start at 0.
        % R. Gomez-Sjoberg, 4/14/11
        % C. Díaz-Botía,    2/24/12

        if length(numbers) ~= length(values)
            wagoError = 1;
        elseif max(numbers) > totalValves - 1;
            wagoError = 2;
        else
            % Make sure values are 0 or 1
            values = (values > 0);
            % Update valves that must be changed
            newValues = currValues;
            newValues(numbers+1) = values;
            writeValues = ~xor(newValues, polarity);
            % Write new values to the Wago
            try
                wagoMaster.WriteMultipleCoils(0, logical(writeValues));
                wagoError = 0;
            catch
                wagoError = 999;
            end
            if ~wagoError
                currValues = newValues;
            end
        end
        pause(0.01);
    end %wagoSetValves

% Get state of one or more valves
    function values = wagoGetValves(numbers)
        % Get the states of the valves specified in vector numbers
        % (0 = open or 1 = closed).
        % Valve numbers start at 0.
        % R. Gomez-Sjoberg, 4/14/11
        % C. Díaz-Botía,    2/24/12
        
        values = [];
        if max(numbers) > totalValves - 1;
            wagoError = 2;
        else
            % Read registers for all valves, starting with address 512 (coil #0)
            % For some reason, reading the coils always gives zeros, so we must
            % read the registers
            try
                registers = wagoMaster.ReadHoldingRegisters(512, totalWords);
                wagoError = 0;
            catch
                wagoError = 999;
            end
            words = [];
            for ii=1:totalWords
                words(ii) = registers.GetValue(ii-1);
            end
            if ~wagoError
                % Convert all bytes to bits
                allValvesBin = char('0'*ones(1, totalWords*16));
                for ii = 1:totalWords
                    word = words(ii);
                    bb = dec2bin(word,16);
                    idx = 16*(ii - 1) + 1;
                    allValvesBin(idx:(idx + 15)) = bb(end:-1:1);
                end
                values = allValvesBin(1:totalValves) - 48;
                currValues = ~xor(values, polarity);
                values = currValues(numbers+1);
            end
        end
    end %wagoGetValves

% Set virtual state of one or more valves
    function wagoSetValvesVirtual(numbers, values)
        % Set the virtual valves secified in vector numbers to the states
        % specified in vector values (0 = open or 1 = closed).
        % Valve numbers start at 0.
        % R. Gomez-Sjoberg, 11/3/11

        if length(numbers) ~= length(values)
            wagoError = 1;
        elseif max(numbers) > totalValves - 1;
            wagoError = 2;
        else
            % Make sure values are 0 or 1
            values = (values > 0);
            % Update valves that must be changed
            newValues = currValues;
            newValues(numbers + 1) = values;
            wagoError = 0;
            currValues = newValues;
        end
    end %wagoSetValvesVirtual

% Get state of one or more virtual valves
    function values = wagoGetValvesVirtual(numbers)
        % Get the states of the virtual valves specified in vector numbers
        % (0 = open or 1 = closed).
        % Valve numbers start at 0.
        % R. Gomez-Sjoberg, 11/3/11
        
        values = [];
        if max(numbers) > totalValves - 1;
            wagoError = 2;
        else
            values = currValues(numbers + 1);
            wagoError = 0;
        end
    end %wagoGetValvesVirtual


% Get Non-volatile Memory Values
    function allWords = wagoGetMemory(addressOffset, nWords)
        % Read registers for non-volatile memory, starting addressOffset words beyond address 12288.
        % Non-volatile memory space is 12288.. 24575(0x3000... 0x5FFF)(%MW0... %MW12287)
        % Created by L. Ardila-Perez, 1/11/12
        % Modified by C. Díaz-Botía,    2/24/12
        
        allWords = [];
        if (addressOffset >= 0) && (addressOffset <= 12288)
            endAddress = 12288 + addressOffset + nWords;
            if (endAddress <= 24575)
                try
                    registers = wagoMaster.ReadHoldingRegisters(12288 + addressOffset, nWords);
                    wagoError = 0;
                catch
                    wagoError = 999;
                end
                for ii=1:nWords
                    wordsP(ii) = registers.GetValue(ii-1);
                end
                words = wordsP;
            else
                wagoError = 11;
            end
        else
            wagoError = 10;
        end
        if ~wagoError
            % Convert all bytes to bits
            allWords = zeros(1, nWords);
            for ii = 1:nWords
                word = words(ii);
                allWords(ii) = word;
            end
        end
    end%wagoGetMemory

% Set non-volatile Memory Values
    function wagoSetMemory(addressOffset, values)
        % Write values to non-volatile memory registers, starting addressOffset words beyond address 12288.
        % Non-volatile memory space is 12288.. 24575(0x3000... 0x5FFF)(%MW0... %MW12287)
        % Created by L. Ardila-Perez, 1/11/12
        % Modified by C. Díaz-Botía,    2/24/12
        
        nWords = length(values);
        if (addressOffset >= 0) && (addressOffset <= 12288)
            endAddress = 12288 + addressOffset + nWords;
            if (endAddress <= 24575)
                % Write new words to the Wago
                allWords = zeros(1, nWords);
                for ii = 1:nWords
                    word = values(ii);
                    allWords(ii) = word;
                end
                words = uint16(allWords);
                try
                    wagoMaster.WriteMultipleRegisters(12288 + addressOffset, words);
                    wagoError = 0;
                catch
                    wagoError = 999;
                end
            else
                wagoError = 11;
            end
        else
            wagoError = 10;
        end
    end %wagoSetMemory


% Get virtual non-volatile Memory Values
    function allWords = wagoGetMemoryVirtual(addressOffset, nWords)
        % Read registers from virtual non-volatile memory, starting addressOffset words beyond address 12288.
        % Virtual non-volatile memory space is 1:12288
        % L. Ardila-Perez and R. Gomez-Sjoberg, 1/11/12
        
        allWords = [];
        addressOffset = addressOffset + 1;
        if (addressOffset >= 1) && (addressOffset <= 12288)
            endAddress = addressOffset + nWords - 1;
            if (endAddress <= 12288)
                allWords = wagoVirtualMemory(addressOffset:endAddress);
            else
                wagoError = 11;
            end
        else
            wagoError = 10;
        end
    end%wagoGetMemoryVirtual

% Set virtual non-volatile Memory Values
    function wagoSetMemoryVirtual(addressOffset, values)
        % Write values to virtual non-volatile memory registers, starting at addressOffset
        % Virtual non-volatile memory space is 1:12288
        % L. Ardila-Perez and R. Gomez-Sjoberg, 1/11/12
        
        addressOffset = addressOffset + 1;
        nWords = length(values);
        if (addressOffset >= 0) && (addressOffset <= 12288)
            endAddress = addressOffset + nWords - 1;
            if (endAddress <= 12288)
                % Write new words to the Wago
                wagoVirtualMemory(addressOffset:endAddress) = values;
            else
                wagoError = 11;
            end
        else
            wagoError = 10;
        end
    end %wagoSetMemoryVirtual

% Custom function for word swaping
% C. Díaz-Botía,    2/21/12
    function outputWord = swapWord(inputWord)
       wordBin = dec2bin(inputWord, 16);
       outputWord = '';
       outputWord(1:8) = wordBin(9:16);
       outputWord(9:16) = wordBin(1:8);
       outputWord = bin2dec(outputWord);
    end


end %wago
