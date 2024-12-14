classdef GameEventData < event.EventData
    % GameEventData - Event data for summarizing game data at the end of a game.
    %
    % This class carries event data transmitted when game is completed.

    properties
        Successful (1,1) % Total number of successful trials
        Total (1,1) % Total number of trial attempts
    end

    methods
        % Constructor
        function obj = GameEventData(numSuccessful, numTotal)
            %GAMEEVENTDATA Constructs an instance of GameEventData
            %
            % Syntax:
            %   eventData = GameEventData(targetIndex, inTarget);
            %
            % Inputs:
            %   numSuccessful - Number of successful trials.
            %   numTotal - Number of total trials.
            %
            % Outputs:
            %   eventData - An instance of GameEventData.
            arguments
                numSuccessful (1,1) {mustBeNumeric}
                numTotal (1,1) {mustBeNumeric}
            end
            obj.Successful = numSuccessful;
            obj.Total = numTotal;
        end
    end
end
