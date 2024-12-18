classdef GameContainer < handle

    properties (GetAccess = public, SetAccess = protected)
        Axes     % Handle to the axes
        Cursor   % Handle to the plotted cursor point
        Control  % struct with uicontrol elements
        Label    % struct with uilabel elements
        Panel    % Panel for showing other stuff
        Boundaries (1,2) double = [-340, 340];
        InTarget1 (1,1) logical = false;
        Target1Location (1,2) double = [0 0];
        InTarget2 (1,1) logical = false;
        Target2Location (1,2) double = [0 0];
        Target1  % Handle to a primary target destination
        Target1Radius (1,1) {mustBePositive, mustBeInteger} = 32;%
        Target2  % Handle to a secondary target destination
        Target2Radius (1,1) {mustBePositive, mustBeInteger} = 32; % 
        Figure   % "Parent" figure
        Visible (1,1) logical = true;
    end

    events
        Next    % Notifies cursor "parent" when we want to start game or skip to next trial
        Target  % Notified when cursor enters/exits targets
        OnOff   % Logical toggle for stopping/starting cursor "parent"
    end

    methods
        % Constructor
        function obj = GameContainer()
            % folderPath = fileparts(mfilename('fullpath'));

            obj.Figure = figure(...
                'Name', 'Cursor Viewer', ...
                'Color',  'w', ...
                'Units', 'pixels', ...
                'Position', [200 80 1080 780], ...
                'NumberTitle', 'off', ...
                'CloseRequestFcn', @obj.hide, ...
                'Visible', 'on');
            obj.Axes = axes(...
                obj.Figure, ...
                'Units', 'pixels', ...
                'Position', [390 50 681 681], ...
                'XLim', obj.Boundaries, ...
                'YLim', obj.Boundaries, ...
                'Box', 'on', ...
                'XColor','k','YColor','k', ...
                'XTick', [], 'YTick', [], ...
                'NextPlot', 'add');
            obj.Label = struct;
            obj.Label.Header = uicontrol(...
                'Parent', obj.Figure, 'Style', 'text',...
                "String", "Game Info", ...
                'FontName','Consolas', ...
                'ForegroundColor', 'k', ...
                'BackgroundColor', 'w', ...
                'FontSize', 22, 'FontWeight', 'bold', ...
                'Position', [5, 710, 380, 40], ...
                'HorizontalAlignment', 'center');
            obj.Label.GameText = uicontrol(...
                'Parent', obj.Figure, 'Style', 'text',...
                "String", "Game Ready", ...
                'FontName','Consolas', ...
                'BackgroundColor', 'w', ...
                'ForegroundColor', 'k', ...
                'FontSize', 20, ...
                'FontWeight', 'normal', ...
                'Position', [5, 670, 380, 40], ...
                'HorizontalAlignment', 'center');
            obj.Label.TrialsText = uicontrol(...
                'Parent', obj.Figure, 'Style', 'text',...
                "String", "", ...
                'FontName','Consolas', ...
                'BackgroundColor', 'w', ...
                'ForegroundColor', 'k', ...
                'FontSize', 20, 'FontWeight', 'normal', ...
                'Position', [5, 630, 380, 40], ...
                'HorizontalAlignment', 'center');
            obj.Label.FileText = uicontrol(...
                'Parent', obj.Figure, 'Style', 'text', ...
                "String", "Not Saving", ...
                'FontName', 'Consolas', ...
                'BackgroundColor', 'w', ...
                'ForegroundColor', 'k', ...
                'FontSize', 16, 'FontWeight', 'normal', ...
                'Position', [5, 430, 380, 40], ...
                'HorizontalAlignment', 'center');
            obj.Control = struct();
            obj.Control.Button = struct();
            obj.Control.Button.OnOff = uicontrol(obj.Figure, ...
                "Style", 'pushbutton', ...
                "String", "Start Cursor",...
                "BackgroundColor", [0.4 0.4 1.0], ...
                "ForegroundColor", 'k', ...
                'FontSize', 16, 'FontWeight', 'bold', ...
                "Position", [5 590, 380, 35], ...
                "Callback", @obj.startCursor);
            obj.Control.Button.Next = uicontrol(obj.Figure, ...
                "Style", 'pushbutton', ...
                "String", "Start Game",...
                'FontSize', 16, 'FontWeight', 'bold', ...
                "Position", [5 550, 380, 35], ...
                "Callback", @obj.startGame);
            faces = [1:20,1];
            theta = linspace(0,2*pi,numel(faces));
            theta = theta(1:(end-1));
            x1 = cos(theta)'.*obj.Target1Radius;
            y1 = sin(theta)'.*obj.Target1Radius;
            vertices1 = [x1, y1];
            obj.Target1 = patch(obj.Axes, ...
                'Faces', faces, ...
                'Vertices', vertices1 + obj.Target1Location, ...
                'FaceColor', 'r', ...
                'EdgeColor', 'k', ...
                'Visible', 'off', ...
                'UserData', struct('x', x1, 'y', y1), ...
                'Tag', 'Target1');
            x2 = cos(theta)'.*obj.Target2Radius;
            y2 = sin(theta)'.*obj.Target2Radius;
            vertices2 = [x2, y2];
            obj.Target2 = patch(obj.Axes, ...
                'Faces', faces, ...
                'Vertices', vertices2 + obj.Target2Location, ...
                'FaceColor', 'r', ...
                'EdgeColor', 'k', ...
                'Visible', 'off', ...
                'UserData', struct('x', x2, 'y', y2), ...
                'Tag', 'Target2');
            obj.Cursor = plot(obj.Axes, 0, 0, ...
                'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b', ...
                'Tag', 'Cursor');
        end

        function hide(obj,~,~)
            obj.Figure.Visible = matlab.lang.OnOffSwitchState(false);
            obj.Visible = false;
        end

        function show(obj)
            obj.Figure.Visible = matlab.lang.OnOffSwitchState(true);
            figure(obj.Figure);
            obj.Visible = true;
        end

        function startGame(obj, src, ~)
            obj.setTrialsLabel(0, 0);
            obj.setGameStateLabel("Game Running");
            set(src,"String","Next","Callback",@obj.nextTrial);
            notify(obj,'Next');
        end

        function startCursor(obj, ~, ~)
            obj.setOnOffButtonState("Started");
            eventData = cursor.OnOffEventData(true);
            notify(obj,'OnOff',eventData);
        end

        function stopCursor(obj, ~, ~)
            obj.setOnOffButtonState("Stopped");
            eventData = cursor.OnOffEventData(false);
            notify(obj,'OnOff',eventData);
        end

        function setOnOffButtonState(obj, state)
            arguments
                obj
                state {mustBeMember(state, ["Stopped", "Started"])}
            end
            switch state
                case "Stopped"
                    set(obj.Control.Button.OnOff,'String', "Start Cursor", 'ForegroundColor', 'k', 'BackgroundColor', [0.4 0.4 1.0], 'Callback', @obj.startCursor);
                case "Started"
                    set(obj.Control.Button.OnOff,'String', "Stop Cursor",'ForegroundColor', 'w', 'BackgroundColor', [0.8 0.2 0.2], 'Callback', @obj.stopCursor);
                otherwise
                    error("Unhandled state: %s", state);
            end
        end

        function nextTrial(obj, ~, ~)
            notify(obj,'Next');
        end

        function setTrialsLabel(obj, numSuccessful, numAttempts)
            obj.Label.TrialsText.String = string(sprintf("%d / %d", numSuccessful, numAttempts));
        end

        function setGameStateLabel(obj, gameStateText)
            obj.Label.GameText.String = gameStateText;
        end
        
        function setFileLabel(obj, fileLabel)
            arguments
                obj
                fileLabel {mustBeTextScalar} = "Not Saving";
            end
            obj.Label.FileText.String = fileLabel;
            if strcmpi(fileLabel, "not saving")
                obj.Label.FileText.FontSize = 16;
            else
                obj.Label.FileText.FontSize = 10;
            end
        end

        function update(obj, x, y)
            if obj.Visible
                set(obj.Cursor,'XData',x,'YData',y);
                % drawnow limitrate;
                if obj.Target1.Visible
                    d = norm(obj.Target1Location - [x, y]);
                    if obj.InTarget1
                        if d > obj.Target1Radius
                            eventdata = cursor.TargetEventData(1, false);
                            obj.InTarget1 = false;
                            notify(obj, 'Target', eventdata);
                        end
                    else
                        if d <= obj.Target1Radius
                            eventdata = cursor.TargetEventData(1, true);
                            obj.InTarget1 = true;
                            notify(obj, 'Target', eventdata);
                        end
                    end
                end
                if obj.Target2.Visible
                    d = norm(obj.Target2Location - [x, y]);
                    if obj.InTarget2
                        if d > obj.Target2Radius
                            eventdata = cursor.TargetEventData(2, false);
                            obj.InTarget2 = false;
                            notify(obj, 'Target', eventdata);
                        end
                    else
                        if d <= obj.Target2Radius
                            eventdata = cursor.TargetEventData(2, true);
                            obj.InTarget2 = true;
                            notify(obj, 'Target', eventdata);
                        end
                    end
                end
            end
        end

        function setPrimaryTargetPosition(obj, x, y)
            arguments
                obj
                x (1,1) double
                y (1,1) double
            end
            obj.Target1Location = [x, y];
            set(obj.Target1,'Vertices',[obj.Target1.UserData.x + x,obj.Target1.UserData.y + y]);
        end

        function setPrimaryTargetColor(obj, cdata)
            arguments
                obj
                cdata (1,3) double
            end
            obj.Target1.FaceColor = cdata;
        end

        function setPrimaryTargetSize(obj, newRadius)
            arguments
                obj
                newRadius (1,1) double {mustBePositive}
            end
            obj.Target1Radius  = newRadius;
            theta = linspace(0,2*pi,21);
            theta = theta(1:(end-1));
            x = cos(theta)'.*obj.Target1Radius;
            y = sin(theta)'.*obj.Target1Radius;
            cx = mean(obj.Target1.Vertices(:,1));
            cy = mean(obj.Target1.Vertices(:,2));
            set(obj.Target1, ...
                'UserData',struct('x',x,'y',y), ...
                'Vertices',[x + cx, y + cy]);
        end

        function setPrimaryTargetVisible(obj, visible)
            arguments
                obj
                visible (1,1) logical
            end
            obj.Target1.Visible = matlab.lang.OnOffSwitchState(visible);
            wasInTarget = obj.InTarget1;
            obj.InTarget1 = wasInTarget && visible;
            if (wasInTarget && ~visible)
                eventdata = cursor.TargetEventData(1, false);
                obj.InTarget1 = false;
                notify(obj, 'Target', eventdata);
            elseif (~wasInTarget && visible)
                eventdata = cursor.TargetEventData(1, true);
                obj.InTarget1 = true;
                notify(obj, 'Target', eventdata);
            end
        end

        function setSecondaryTargetPosition(obj, x, y)
            arguments
                obj
                x (1,1) double
                y (1,1) double
            end
            obj.Target2Location = [x, y];
            set(obj.Target2,'Vertices',[obj.Target2.UserData.x + x,obj.Target2.UserData.y + y]);
        end

        function setSecondaryTargetSize(obj, newRadius)
            arguments
                obj
                newRadius (1,1) double {mustBePositive}
            end
            obj.Target2Radius  = newRadius;
            theta = linspace(0,2*pi,21);
            theta = theta(1:(end-1));
            x = cos(theta)'.*obj.Target2Radius;
            y = sin(theta)'.*obj.Target2Radius;
            cx = mean(obj.Target2.Vertices(:,1));
            cy = mean(obj.Target2.Vertices(:,2));
            set(obj.Target2, ...
                'UserData',struct('x',x,'y',y), ...
                'Vertices',[x + cx, y + cy]);
        end

        function setSecondaryTargetColor(obj, cdata)
            arguments
                obj
                cdata (1,3) double
            end
            obj.Target2.FaceColor = cdata;
        end

        function setSecondaryTargetVisible(obj, visible)
            arguments
                obj
                visible (1,1) logical
            end
            obj.Target2.Visible = matlab.lang.OnOffSwitchState(visible);
            wasInTarget = obj.InTarget2;
            obj.InTarget2 = wasInTarget && visible;
            if (wasInTarget && ~visible)
                eventdata = cursor.TargetEventData(2, false);
                obj.InTarget2 = false;
                notify(obj, 'Target', eventdata);
            elseif (~wasInTarget && visible)
                eventdata = cursor.TargetEventData(2, true);
                obj.InTarget2 = true;
                notify(obj, 'Target', eventdata);
            end
        end

        function delete(obj)
            try %#ok<*TRYNC>
                obj.Figure.DeleteFcn = [];
            end
            try
                delete(obj.Figure);
            end
        end
    end
end