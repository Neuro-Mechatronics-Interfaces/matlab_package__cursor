classdef TrialCompletedEventData < event.EventData
    % TrialCompletedEventData - Event data for TrialCompleted events.
    %
    % This class encapsulates the data associated with individual trial outcomes.

    properties
        Successful (1,1) logical
        NOvershoot (1,1) single
        MoveDuration (1,1) single
        TotalDuration (1,1) single
    end

    methods
        % Constructor
        function obj = TrialCompletedEventData(successful, nOvershoot, moveDuration, totalDuration)
            %TRIALCOMPLETEDEVENTDATA  Constructs an instance of TrialCompletedEventData
            %
            % Syntax:
            %   eventData = TrialCompletedEventData(successful, nOvershoot, moveDuration, totalDuration);
            %
            % Inputs:
            %   successful (1,1) logical - True if trial was successful.
            %   nOvershoot (1,1) single - Number of overshoots
            %   moveDuration (1,1) single - Duration of the MOVE state.
            %   totalDuration (1,1) single - Duration of the total trial.
            %
            % Outputs:
            %   eventData - An instance of TrialCompletedEventData.
            %
            % See also: CenterOutTrialManager, CenterOutStateManager
            arguments
                successful (1,1) logical
                nOvershoot (1,1) single
                moveDuration (1,1) single
                totalDuration (1,1) single
            end
            obj.Successful = successful;
            obj.NOvershoot = nOvershoot;
            obj.MoveDuration = moveDuration;
            obj.TotalDuration = totalDuration;
        end
    end
end
