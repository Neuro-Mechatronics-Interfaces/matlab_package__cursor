classdef TargetEventData < event.EventData
    % TargetEventData - Event data for TargetEnter and TargetExit events.
    %
    % This class encapsulates the data associated with target interactions.

    properties
        Index (1,1) % Index of the target
        InTarget (1,1) logical % True if the cursor is inside the target.
    end

    methods
        % Constructor
        function obj = TargetEventData(targetIndex, inTarget)
            %TARGETEVENTDATA Constructs an instance of TargetEventData
            %
            % Syntax:
            %   eventData = TargetEventData(targetIndex, inTarget);
            %
            % Inputs:
            %   targetIndex - Index of the current target.
            %   inTarget    - True if the cursor is inside the target.
            %
            % Outputs:
            %   eventData - An instance of TargetEventData.
            arguments
                targetIndex (1,1) {mustBeNumeric}
                inTarget (1,1) logical
            end
            obj.Index = targetIndex;
            obj.InTarget = inTarget;
        end
    end
end
