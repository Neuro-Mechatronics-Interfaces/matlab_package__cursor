classdef NewTrialEventData < event.EventData
    % NewTrialEventData - Event data for NewTrial events.
    %
    % This class encapsulates the data associated with individual trial parameterization.

    properties
        Index (1,1) % Index of the current trial
        T1 (1,2) single
        T2 (1,2) single
        TargetRadius (1,2) single
        Hold (1,3) single % T1Hold1, T1Hold2, T2Hold1
        Limit (1,2) single % Move, Total
    end

    methods
        % Constructor
        function obj = NewTrialEventData(trialData)
            %NEWTRIALEVENTDATA Constructs an instance of NewTrialEventData
            %
            % Syntax:
            %   eventData = NewTrialEventData(trialData);
            %
            % Inputs:
            %   trialData - Row from Trial table (handled by CenterOutTrialManager or comparable).
            %
            % Outputs:
            %   eventData - An instance of TrialEventData.
            %
            % See also: CenterOutTrialManager
            arguments
                trialData (1,:) table
            end
            obj.Index = trialData.Index;
            obj.T1 = [trialData.T1_x, trialData.T1_y];
            obj.T2 = [trialData.T2_x, trialData.T2_y];
            obj.TargetRadius = [trialData.T1_r, trialData.T2_r];
            obj.Hold = [trialData.T1Hold1, trialData.T1Hold2, trialData.T2Hold1];
            obj.Limit = [trialData.Move, trialData.Total];
        end
    end
end
