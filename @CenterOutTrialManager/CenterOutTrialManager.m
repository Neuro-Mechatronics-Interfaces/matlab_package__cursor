classdef CenterOutTrialManager < handle
    %CENTEROUTTRIALMANAAGER  Class for tracking overall experiment trial parameterization/outcomes on a center-out behavioural task. 

    properties (GetAccess = public, SetAccess = protected)
        StateManager (1,1) cursor.CenterOutStateManager;
        Trials (:,:) table  % Table containing trial information
        NumAttempts (1,1) single = 0;
        NumSuccessful (1,1) single = 0;
        MoveDuration (:,1) single
        TotalDuration (:,1) single
        TStart (:,1) single
        Overshoots (:,1) single
        Outcome (:,1) logical
    end

    properties (Access = protected)
        CurrentTrialIndex (1,1) single = 0; % Index of the current trial
        ForceCompletion (1,1) logical = true; % Require successful completion of the current trial
        TrialCompletedListener
        TimeElapsed (1,1) single = 0;
    end

    events
        GameOver          % Triggered when all trials are completed, on `nextTrial` call.
        NewTrial          % Triggered when a new trial starts
    end

    methods
        %% Constructor
        function obj = CenterOutTrialManager(filename)
            %CENTEROUTTRIALMANAGER Constructor for CenterOutTrialManager
            arguments
                filename {mustBeTextScalar} = "";
            end
            if strlength(filename) > 0
                obj.loadTrials(filename);
            end
            obj.StateManager = cursor.CenterOutStateManager();
            obj.TrialCompletedListener = addlistener(obj.StateManager, 'TrialCompleted', @obj.nextTrial);
        end

        function update(obj, delta_t)
            obj.TimeElapsed = obj.TimeElapsed + delta_t;
            obj.StateManager.update(delta_t);
        end

        function delete(obj)
            %DELETE Ensures listeners are deleted on cleanup.
            if ~isempty(obj.TrialCompletedListener)
                try %#ok<*TRYNC>
                delete(obj.TrialCompletedListener);
                end
            end
            if ~isempty(obj.StateManager)
                try
                    delete(obj.StateManager);
                end
            end
        end

        function loadTrials(obj, filename)
            %LOADTRIALS Load trials from a CSV file
            arguments
                obj
                filename {mustBeTextScalar, mustBeFile}
            end
            obj.Trials = cursor.CenterOutTrialManager.read(filename);
            obj.resetIndex(); % Reset trial index to 0
        end

        function nextTrial(obj, ~, event)
            %NEXTTRIAL  Advance to the Next Trial.

            % Increment the trial index
            if obj.CurrentTrialIndex < height(obj.Trials)
                if obj.CurrentTrialIndex > 0
                    obj.Overshoots(obj.CurrentTrialIndex) = event.NOvershoot;
                    obj.MoveDuration(obj.CurrentTrialIndex) = event.MoveDuration;
                    obj.TotalDuration(obj.CurrentTrialIndex) = event.TotalDuration;
                    obj.Outcome(obj.CurrentTrialIndex) = event.Successful;
                    obj.TStart(obj.CurrentTrialIndex) = obj.TimeElapsed;
                    obj.NumSuccessful = obj.NumSuccessful + event.Successful;
                end
                obj.CurrentTrialIndex = obj.CurrentTrialIndex + 1;
                newTrialEventData = cursor.NewTrialEventData(obj.Trials(obj.CurrentTrialIndex, :));
                obj.NumAttempts = obj.NumAttempts + 1;
                notify(obj, 'NewTrial', newTrialEventData); % Emit NewTrial event
            else
                obj.NumSuccessful = obj.NumSuccessful + event.Successful;
                gameEventData = cursor.GameEventData(obj.NumSuccessful, obj.NumAttempts);
                notify(obj, 'GameOver', gameEventData); % Emit GameOver event
            end
        end

        function resetIndex(obj)
            %RESETINDEX Reset trial index to 0.
            obj.NumAttempts = 0;
            obj.NumSuccessful = 0;
            obj.CurrentTrialIndex = 0;
            obj.Overshoots = zeros(size(obj.Trials,1),1,'single');
            obj.MoveDuration = ones(size(obj.Trials,1),1,'single').*100.0;
            obj.TotalDuration = ones(size(obj.Trials,1),1,'single').*100.0;
            obj.Outcome = false(size(obj.Trials,1),1);
            obj.TStart = zeros(size(obj.Trials,1),1,'single');
        end

        
        function trial = getCurrentTrial(obj)
            %GETCURRENTTRIAL Get current trial information.
            if obj.CurrentTrialIndex > 0 && obj.CurrentTrialIndex <= height(obj.Trials)
                trial = obj.Trials(obj.CurrentTrialIndex, :);
            else
                trial = [];
            end
        end
    end

    methods (Static, Access = public)
        %% Read Trials from CSV
        function T = read(filename)
            %READ Load trials as table from a CSV file.
            % File must contain columns: T1_x, T1_y, T1_r, T2_x, T2_y, T2_r, T1Hold1, T1Hold2, T2Hold1, Move, Total.
            %
            % Syntax:
            %   T = cursor.CenterOutTrialManager.read(filename);
            %
            % Inputs:
            %   filename - Name of the CSV file.
            %
            % Outputs:
            %   T - Table containing trial data.
            arguments
                filename {mustBeTextScalar} = 'CenterOut.csv';
            end

            p = fileparts(filename);
            if strlength(p) < 1
                folderPath = fileparts(mfilename('fullpath'));
                packagePath = fileparts(folderPath);
                filename = fullfile(packagePath, '.trial_structure', filename);
            end

            % Read the file
            opts = detectImportOptions(filename);
            opts.VariableTypes = {...
                'double', 'double', 'double', ...
                'double',  'double', 'double', ...
                'double', 'double', 'double', ...
                'double', 'double'};
            T = readtable(filename, opts);
            T.Index = reshape((1:size(T,1)),size(T,1),1);
            T = movevars(T,'Index','Before',1);

            % Validate columns
            requiredCols = {'Index', 'T1_x', 'T1_y', 'T1_r', 'T2_x', 'T2_y', 'T2_r', 'T1Hold1', 'T1Hold2', 'T2Hold1', 'Move', 'Total'};
            cols_in_file = ismember(requiredCols, T.Properties.VariableNames);
            if ~all(cols_in_file)
                error('The file is missing these required columns: %s', strjoin(requiredCols(~cols_in_file), ', '));
            end
        end
    end
end
