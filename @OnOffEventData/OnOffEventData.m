classdef OnOffEventData < event.EventData
    % OnOffEventData - Event data for "ON" (1) vs "OFF" (0) events.
    %
    % This class encapsulates the data associated with button state change
    % events, such as ButtonUp and ButtonDown, for the Cursor class.

    properties
        OnOff (1,1) logical
    end

    methods
        % Constructor
        function obj = OnOffEventData(onOff)
            %ONOFFEVENTDATA Constructs an instance of OnOffEventData
            %
            % Syntax:
            %   eventData = OnOffEventData(onOff);
            %
            % Inputs:
            %   onOff - Logical - true (1) == "ON" vs false (0) == "OFF"
            %
            % Outputs:
            %   eventData - An instance of OnOffEventData.
            arguments
                onOff (1,1) logical
            end
            obj.OnOff = onOff;
        end
    end
end
