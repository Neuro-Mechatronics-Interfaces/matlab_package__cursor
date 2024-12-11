classdef Cursor < handle
    % Cursor - A joystick-based cursor class with logging and event handling.
    %
    % The Cursor class provides an interface to interact with a joystick device
    % for controlling a 2D cursor, logging joystick and cursor states, and 
    % detecting button press/release events. It includes visualization of cursor
    % movement in real-time and logging to a binary file for later analysis.
    %
    % Features:
    %   - Smooth joystick-based cursor control.
    %   - Real-time cursor visualization.
    %   - Event-driven detection of button presses (ButtonDown) and releases
    %     (ButtonUp).
    %   - Logging of joystick and cursor states to a binary file with microsecond
    %     timestamp precision.
    %   - Reading of logged data for analysis.
    %
    % Usage:
    %   % Create a Cursor object
    %   cObj = cursor.Cursor();
    %
    %   % Start logging to a binary file
    %   cObj.setLogging(true, 'joystick_log.dat');
    %   cObj.start();
    %   pause(5);  % Log data for 5 seconds
    %   cObj.stop();
    %
    %   % Read the logged data
    %   logData = Cursor.readLogFile('joystick_log.dat');
    %   disp(logData);
    %
    %   % Visualize the cursor trajectory
    %   figure;
    %   plot(logData.CursorPosition(:, 1), logData.CursorPosition(:, 2), '-o');
    %   xlabel('X Position');
    %   ylabel('Y Position');
    %   title('Cursor Trajectory');
    %   grid on;
    %
    %   % Add event listeners for button press/release
    %   addlistener(cObj, 'ButtonDown', @(src, eventdata) ...
    %       fprintf('ButtonDown: PreviousState=%d, NewState=%d\n', ...
    %               eventdata.PreviousState, eventdata.NewState));
    %   addlistener(cObj, 'ButtonUp', @(src, eventdata) ...
    %       fprintf('ButtonUp: PreviousState=%d, NewState=%d\n', ...
    %               eventdata.PreviousState, eventdata.NewState));
    %
    %   % Start the cursor to detect button events
    %   cObj.start();
    %   pause(10);  % Monitor for 10 seconds
    %   cObj.stop();
    %
    % Methods:
    %   Cursor          - Constructor to initialize a Cursor object.
    %   start           - Starts sampling and visualizing cursor motion.
    %   stop            - Stops sampling and visualization.
    %   setLogging      - Enables/disables logging and specifies the log file.
    %   sample          - Timer callback to sample joystick and cursor states.
    %   show            - Displays the cursor position in a 2D figure.
    %
    % Static Methods:
    %   readLogFile - Reads a binary log file created by the Cursor class.
    %
    % Events:
    %   ButtonDown - Triggered when a button is pressed. Includes previous and
    %                new button states in the event data.
    %   ButtonUp   - Triggered when a button is released. Includes previous and
    %                new button states in the event data.
    %
    % Example 1: Logging and Reading Data
    %   cObj = cursor.Cursor();
    %   cObj.setLogging(true, 'joystick_log.dat');
    %   cObj.start();
    %   pause(5);
    %   cObj.stop();
    %
    %   logData = cursor.Cursor.readLogFile('joystick_log.dat');
    %   disp(logData);
    %
    % Example 2: Using Event Listeners
    %   cObj = cursor.Cursor();
    %   addlistener(cObj, 'ButtonDown', @(src, eventdata) ...
    %       fprintf('ButtonDown: PreviousState=%d, NewState=%d\n', ...
    %               eventdata.PreviousState, eventdata.NewState));
    %   addlistener(cObj, 'ButtonUp', @(src, eventdata) ...
    %       fprintf('ButtonUp: PreviousState=%d, NewState=%d\n', ...
    %               eventdata.PreviousState, eventdata.NewState));
    %
    %   cObj.start();
    %   pause(10);
    %   cObj.stop();
    %
    % See also: timer, datetime, fread, fwrite, struct

    properties (Access = public)
        Game (1,1) cursor.GameContainer = cursor.GameContainer();
        CursorPosition (1,2) single = zeros(1,2,'single'); % Apparent cursor position (x, y)
        CursorVelocity (1,2) single = zeros(1,2,'single'); % Apparent cursor velocity (x, y)
        CursorAcceleration (1,2) single = zeros(1,2,'single'); % Apparent cursor acceleration (x, y)
        JoystickState = zeros(1,2,'int8'); % Raw joystick state (x, y)
        ButtonState = zeros(1,1,'uint8'); % Raw button state
    end

    properties (Hidden, Access = public)
        DragCoefficients (1,2) single = 0.5.*ones(1,2,'single'); % "Drag" on cursor (related to velocity; <x,y>)
        VelocityGains (1,2) single = 15.*ones(1,2,'single'); % Gains on <x, y> velocity
        VelocityDeadzones (1,2) single = 0.0025.*ones(1,2,'single'); % Deadzones for <x,y>
        AccelerationGains (1,2) single = 0.05.*ones(1,2,'single'); % Gains on <x, y> acceleration
        SmoothingFactor (1,1) single = single(0.2); % Smoothing factor for cursor motion

        SampleTimer % Timer object for background sampling
        SamplePeriod = 0.01; % Sampling period (default 10 ms)
        JoystickID = 0; % Joystick ID to use
        LoggingEnabled = false; % Flag to indicate logging
        LogFile = ""; % Log file name
        LogFID = -1; % File identifier for logging
    end

    events
        ButtonUp % Triggered when button is released
        ButtonDown % Triggered when button is pressed
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
            obj.SampleTimer = timer( ...
                'ExecutionMode', 'fixedRate', ...
                'Period', obj.SamplePeriod, ...
                'TimerFcn', @(~, ~) obj.sample());
        end

        % Start sampling
        function start(obj)
            %START  Start sampling from joystick/gamepad. Also starts logging (if setLogging(true, 'filename') was called).
            if strcmp(obj.SampleTimer.Running, 'off')
                if obj.LoggingEnabled
                    obj.openLogFile();
                end
                show(obj); % Pull up the visualization
                start(obj.SampleTimer);
            end
        end

        % Stop sampling
        function stop(obj)
            %STOP Stop sampling from joystick/gamepad.
            if strcmp(obj.SampleTimer.Running, 'on')
                stop(obj.SampleTimer);
                if obj.LoggingEnabled
                    obj.closeLogFile();
                end
            end
        end

        % Set logging state and filename
        function setLogging(obj, enable, filename)
            %SETLOGGING Sets logging state and filename.
            %
            % Syntax:
            %   cObj.setLogging(enable, filename);
            %
            % Inputs:
            %   enable (1,1) logical - Set true to enable logging.
            %   filename (1,1) string - Sets file where logging happens.
            %
            % Example 1: Start logging
            %   cObj.setLogging(true, 'mycursor.dat');
            %   start(cObj);
            %
            % Example 2: Stop logging
            %
            arguments
                obj
                enable (1,1) logical
                filename (1,1) string = "default_cursor_log.dat";
            end
            if strcmp(obj.SampleTimer.Running, 'on')
                error('Cannot change logging state while sampling is running.');
            end
            obj.LoggingEnabled = enable;
            if enable
                obj.LogFile = filename;
            else
                obj.LogFile = "";
            end
        end

        % Open log file
        function openLogFile(obj, logFile)
            %OPENLOGFILE Opens log file to begin logging.
            %
            % Syntax:
            %   cObj.openLogFile();
            %   cObj.openLogFile(logFile);
            %
            % Inputs:
            %   logFile (optional) - Can open new log directly here if no
            %                        existing log is open. This is useful
            %                        rather than using setLogging, if you
            %                        want to manage the logging from
            %                        another acquisition loop rather than
            %                        implicitly from the animation timer in
            %                        the view update loop. 
            arguments
                obj
                logFile {mustBeTextScalar}
            end
            if obj.LogFID < 0
                if nargin > 1
                    obj.LogFile = logFile;
                    obj.LogFID = fopen(logFile, 'wb');
                else
                    obj.LogFID = fopen(obj.LogFile, 'wb');
                end
                if obj.LogFID == -1
                    error('Failed to open log file: %s', obj.LogFile);
                end
            end
        end

        % Close log file
        function closeLogFile(obj)
            %CLOSELOGFILE  Closes the binary log file.
            if obj.LogFID > 0
                fclose(obj.LogFID);
                obj.LogFID = -1;
            end
        end

        % Timer callback for joystick sampling
        function sample(obj)
            %SAMPLE  Read joystick and button data in timer-mediated loop.
            % Read joystick data
            [x, y, buttons] = WinJoystickMex(obj.JoystickID);

            % Update joystick state
            obj.JoystickState = [x, y];
             % Detect button state changes
            if buttons > obj.ButtonState
                % Button pressed
                eventdata = cursor.ButtonEventData(obj.ButtonState, buttons);
                notify(obj, 'ButtonDown', eventdata);
            elseif buttons < obj.ButtonState
                % Button released
                eventdata = cursor.ButtonEventData(obj.ButtonState, buttons);
                notify(obj, 'ButtonUp', eventdata);
            end
            obj.ButtonState = buttons;

            % Apply smoothing to cObj position
            delta = single(obj.JoystickState);
            obj.CursorAcceleration = obj.CursorAcceleration * (1 - obj.SmoothingFactor) + ...
                delta * obj.SmoothingFactor - (1 - abs(delta)) .* obj.DragCoefficients .* obj.CursorVelocity;
            obj.CursorVelocity = max(min(obj.CursorVelocity + obj.CursorAcceleration .* obj.AccelerationGains, obj.Game.Boundaries(2)),obj.Game.Boundaries(1));
            v = obj.CursorVelocity .* obj.VelocityGains;
            v(abs(v) < obj.VelocityDeadzones) = 0;
            obj.CursorPosition = max(min(obj.CursorPosition + v, obj.Game.Boundaries(2)),obj.Game.Boundaries(1));

            % Log data if enabled
            if obj.LoggingEnabled && obj.LogFID > 0
                % Create a binary buffer for the data
                obj.logData();
            end

            % Update visualization
            update(obj);
        end

        function logData(obj, extra)
            %LOGDATA Gives option to externally log data to externally-opened binary file (i.e. in external acquisition loop). 
            arguments
                obj
                extra (1,1) single = 0
            end
            logData = [ ...
                single(posixtime(datetime('now')) * 1e6), ... % Timestamp (microseconds as single)
                single(obj.JoystickState), ...    % Joystick x, y
                single(obj.ButtonState), ...     % Button state
                single(obj.CursorPosition), ...  % Cursor x, y position
                single(obj.CursorVelocity), ...  % Cursor x, y velocity
                single(obj.CursorAcceleration) ... % Cursor x, y acceleration
                single(extra)
                ];
            % Write the packed binary data
            fwrite(obj.LogFID, logData, 'single');
        end

        function show(obj)
            %SHOW Shows the Game.
            show(obj.Game);
        end

        function hide(obj)
            %HIDE Hides the Game.
            hide(obj.Game);
        end

        function update(obj)
            %UPDATE Updates the Game visual state. 
            setCursorPosition(obj.Game, obj.CursorPosition(1), obj.CursorPosition(2));
        end

        % Destructor
        function delete(obj)
            %DELETE Overloaded delete ensures Timer is stopped/destroyed log-file is closed, and Game is shutdown.
            obj.stop();
            if isvalid(obj.SampleTimer)
                delete(obj.SampleTimer);
            end
            if ~isempty(obj.Game)
                delete(obj.Game);
            end
            obj.closeLogFile();
        end
    end

    methods (Static)
        function logTable = readLogFile(filename)
            % readLogFile Reads the log file created by the Cursor class.
            %
            % Syntax:
            %   logData = Cursor.readLogFile(filename);
            %
            % Input:
            %   - filename: Name of the log file to read.
            %
            % Output:
            %   - logTable: A table containing the logged data fields.
            %
            % Example:
            %   cObj = Cursor();
            %   cObj.setLogging(true, 'joystick_data.dat');
            %   cObj.start();
            %   pause(5);
            %   cObj.stop();
            %   cObj.setLogging(false);
            %   logData = Cursor.readLogFile('joystick_data.dat');

            if nargin < 1 || ~isfile(filename)
                error('File not found or filename not provided: %s', filename);
            end

            % Open the file for reading
            fid = fopen(filename, 'rb');
            if fid == -1
                error('Failed to open file: %s', filename);
            end

            try
                % Read the binary data as single-precision floating point
                rawData = fread(fid, 'single'); % Read in single precision
            catch ME
                fclose(fid);
                rethrow(ME);
            end

            % Close the file
            fclose(fid);

            % Parse the raw data
            numFields = 11; % Number of fields per entry
            numEntries = length(rawData) / numFields;

            if mod(length(rawData), numFields) ~= 0
                error('Log file data is corrupted or incomplete.');
            end

            % Reshape the data into rows
            reshapedData = reshape(rawData, numFields, numEntries)';

            % Populate the output structure
            logData = struct();
            logData.Time = datetime(reshapedData(:, 1) / 1e6, 'ConvertFrom', 'posixtime');              % Timestamps
            logData.JoystickState = reshapedData(:, 2:3);    % Joystick x, y state
            logData.ButtonState = reshapedData(:, 4);        % Button state
            logData.CursorPosition = reshapedData(:, 5:6);   % Cursor x, y position
            logData.CursorVelocity = reshapedData(:, 7:8);   % Cursor x, y velocity
            logData.CursorAcceleration = reshapedData(:, 9:10); % Cursor x, y acceleration
            logData.Extra = reshapedData(:,11); % Extra 'key' values like sync state etc.
            logTable = struct2table(logData);
            logTable.Time.TimeZone = 'America/New_York';
            logTable.Time.Format = 'uuuu-MM-dd''T''HH:mm:ss.SSS';
        end
    end
end
