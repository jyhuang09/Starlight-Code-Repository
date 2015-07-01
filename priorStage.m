function [w] = priorStage(port)
% Prior
% Creates object to handle Prior stage control
% and initializes communication with the stage
% The object should be created only once
% Untested

%%%% METHODS %%%%
myTag = 'priorStage';
obj1 = instrfind('Type', 'serial', 'Port', port, 'Tag', '');

if ~exist('virtual', 'var')
    virtual = false;
end

location = zeros(2, 32);
counter = 1;

handle = int32(0);

w.close = @priorClose;
w.moveToXY = @priorMoveToXY;
w.setZero = @priorSetZero;
w.readPosition = @priorReadPosition;
priorOpen;

    function priorOpen
        % Establish communication 
        obj1 = instrfind('Type', 'serial', 'Port', port, 'Tag', '');
        if isempty(obj1)
            obj1 = serial(port);
        else
            fclose(obj1);
            obj1 = obj1(1);
        end
        % Connect to instrument serial, obj1.
        fopen(obj1);
        set(obj1, 'BaudRate', 9600);
        set(obj1, 'StopBits', 2);
        obj1.Terminator = 'CR';
    end

    function priorClose
        delete obj1;
    end

    function priorMoveToXY(xCoord, yCoord)
        fprintf(obj1, ['G', ' ', num2str(xCoord), ' ', num2str(yCoord)]);
    end

    function priorSetZero
        fprintf(obj1, 'PS 0 0');
    end
        
    function[output] = priorReadPosition
        cnt = 0;
        prev = [13299,18381,123];
        while cnt<15
            fprintf(obj1, 'P');
            output = str2num(fscanf(obj1));  
            if output == prev
                cnt = cnt + 1;
            else
                cnt = 0;
            end
            prev = output;
        end
    end 
        

end %prior