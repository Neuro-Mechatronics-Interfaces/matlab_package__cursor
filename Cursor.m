classdef Cursor < handle
    properties
        Timer % Timer object for background sampling
        SamplePeriod = 0.01; % Sampling period (default 10 ms)
        JoystickID = 0; % Joystick ID to use
        LoggingEnabled = false; % Flag to indicate logging
        LogFile = ''; % Log file name
        LogFID = -1; % File identifier for logging
        CursorPosition = [0, 0]; % Apparent cursor position (x, y)
        CursorVelocity = [0, 0]; % Apparent cursor velocity (x, y)
        CursorAcceleration = [0, 0]; % Apparent cursor acceleration (x, y)
        DragCoefficients = [0.75, 0.75]; % "Drag" on cursor (related to velocity; <x,y>)
        VelocityGains = [1e-1, 1e-1]; % Gains on <x, y> velocity
        VelocityDeadzones = [0.010, 0.010]; % Deadzones for <x,y>
        AccelerationGains = [0.05, 0.05]; % Gains on <x, y> acceleration
        JoystickState = zeros(1,2,'int8'); % Raw joystick state (x, y)
        ButtonState = 0; % Raw button state
        SmoothingFactor = 0.2; % Smoothing factor for cursor motion
        FigureHandle = []; % Handle to the visualization figure
        AxesHandle = []; % Handle to the visualization axes
        PointHandle = []; % Handle to the cursor point
    end

    methods
        % Constructor
        function obj = Cursor()
            % Ensure the folder is on the MATLAB path
            folderPath = fileparts(mfilename('fullpath'));
            % Check for compiled MEX file
            mexFile = fullfile(pwd, 'WinJoystickMex.mexw64');
            sourceFile = fullfile(folderPath, 'WinJoystickMex.c');
            
            if ~isfile(mexFile)
                if isfile(sourceFile)
                    fprintf('Compiling MEX file from source: %s\n', sourceFile);
                    try
                        mex('-outdir', pwd, sourceFile, '-lwinmm');
                    catch ME
                        error('Failed to compile MEX file: %s\nError: %s', sourceFile, ME.message);
                    end
                else
                    error('MEX file is missing and source file (%s) is not available.', sourceFile);
                end
            end
            obj.Timer = timer( ...
                'ExecutionMode', 'fixedRate', ...
                'Period', obj.SamplePeriod, ...
                'TimerFcn', @(~, ~) obj.sampleJoystick());
        end

        % Start sampling
        function start(obj)
            if strcmp(obj.Timer.Running, 'off')
                if obj.LoggingEnabled
                    obj.openLogFile();
                end
                view(obj); % Pull up the visualization
                start(obj.Timer);
            end
        end

        % Stop sampling
        function stop(obj)
            if strcmp(obj.Timer.Running, 'on')
                stop(obj.Timer);
                if obj.LoggingEnabled
                    obj.closeLogFile();
                end
            end
        end

        % Set logging state and filename
        function setLogging(obj, enable, filename)
            if strcmp(obj.Timer.Running, 'on')
                error('Cannot change logging state while sampling is running.');
            end
            obj.LoggingEnabled = enable;
            if enable
                obj.LogFile = filename;
            else
                obj.LogFile = '';
            end
        end

        % Open log file
        function openLogFile(obj)
            if obj.LoggingEnabled && ~isempty(obj.LogFile)
                obj.LogFID = fopen(obj.LogFile, 'wb');
                if obj.LogFID == -1
                    error('Failed to open log file: %s', obj.LogFile);
                end
            end
        end

        % Close log file
        function closeLogFile(obj)
            if obj.LogFID > 0
                fclose(obj.LogFID);
                obj.LogFID = -1;
            end
        end

        % Timer callback for joystick sampling
        function sampleJoystick(obj)
            % Read joystick data
            [x, y, buttons] = WinJoystickMex(obj.JoystickID);

            % Update joystick state
            obj.JoystickState = [x, y];
            obj.ButtonState = buttons;

            % Apply smoothing to cursor position
            delta = double(obj.JoystickState);
            obj.CursorAcceleration = obj.CursorAcceleration * (1 - obj.SmoothingFactor) + ...
                delta * obj.SmoothingFactor - (1 - abs(delta)) .* obj.DragCoefficients .* obj.CursorVelocity;
            obj.CursorVelocity = max(min(obj.CursorVelocity + obj.CursorAcceleration .* obj.AccelerationGains,1),-1);
            v = obj.CursorVelocity .* obj.VelocityGains;
            v(abs(v) < obj.VelocityDeadzones) = 0;
            obj.CursorPosition = max(min(obj.CursorPosition + v, 1),-1);

            % Log data if enabled
            if obj.LoggingEnabled && obj.LogFID > 0
                fwrite(obj.LogFID, [posixtime(datetime('now')) * 1e6, x, y, buttons], ...
                    'double=>uint8');
            end

            % Update visualization
            obj.updateVisualization();
        end

        % View the cursor position
        function view(obj)
            if isempty(obj.FigureHandle) || ~isvalid(obj.FigureHandle)
                obj.FigureHandle = figure('Name', 'Cursor Viewer', ...
                    'NumberTitle', 'off', ...
                    'CloseRequestFcn', @(~, ~) obj.closeView());
                obj.AxesHandle = axes('Parent', obj.FigureHandle, ...
                    'XLim', [-1, 1], 'YLim', [-1, 1], ...
                    'XGrid', 'on', 'YGrid', 'on');
                hold(obj.AxesHandle, 'on');
                obj.PointHandle = plot(obj.AxesHandle, 0, 0, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
            else
                figure(obj.FigureHandle);
            end
        end

        % Close the visualization
        function closeView(obj)
            if ~isempty(obj.FigureHandle) && isvalid(obj.FigureHandle)
                delete(obj.FigureHandle);
                obj.FigureHandle = [];
                obj.AxesHandle = [];
                obj.PointHandle = [];
            end
        end

        % Update the visualization
        function updateVisualization(obj)
            if ~isempty(obj.PointHandle) && isvalid(obj.PointHandle)
                set(obj.PointHandle, 'XData', obj.CursorPosition(1), 'YData', obj.CursorPosition(2));
            end
        end

        % Destructor
        function delete(obj)
            obj.stop();
            if isvalid(obj.Timer)
                delete(obj.Timer);
            end
            obj.closeLogFile();
            obj.closeView();
        end
    end
end
