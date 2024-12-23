classdef ButtonEventData < event.EventData
    % ButtonEventData - Event data for ButtonUp and ButtonDown events.
    %
    % This class encapsulates the data associated with button state change
    % events, such as ButtonUp and ButtonDown, for the Cursor class.

    properties
        PreviousState % Previous button state
        NewState      % New button state
    end

    methods
        % Constructor
        function obj = ButtonEventData(previousState, newState)
            %BUTTONEVENTDATA Constructs an instance of ButtonEventData
            %
            % Syntax:
            %   eventData = ButtonEventData(previousState, newState);
            %
            % Inputs:
            %   previousState - Previous button state (uint8)
            %   newState      - New button state (uint8)
            %
            % Outputs:
            %   eventData - An instance of ButtonEventData.
            arguments
                previousState (1,1) uint8
                newState (1,1) uint8
            end
            obj.PreviousState = previousState;
            obj.NewState = newState;
        end
    end
end
