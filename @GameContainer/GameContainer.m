classdef GameContainer < handle
    properties (Access = public)
        Axes     % Handle to the axes
        Cursor   % Handle to the plotted cursor point
        Boundaries (1,2) double = [-340, 340];
    end

    properties (Access = protected)
        Target1  % Handle to a primary target destination
        Target1Radius (1,1) {mustBePositive, mustBeInteger} = 32;%
        Target2  % Handle to a secondary target destination
        Target2Radius (1,1) {mustBePositive, mustBeInteger} = 32; % 
        Figure   % "Parent" figure
        Visible (1,1) logical = false;
    end

    methods
        % Constructor
        function obj = GameContainer()
            obj.Figure = figure(...
                'Name', 'Cursor Viewer', ...
                'Color',  'w', 'Units', 'pixels', ...
                'Position', [200 80 1080 780], ...
                'NumberTitle', 'off', 'CloseRequestFcn', @obj.hide, ...
                'Visible', 'off');
            obj.Axes = axes('Parent', obj.Figure, ...
                'Units', 'pixels', ...
                'Position', [200 50 681 681], ...
                'XLim', obj.Boundaries, ...
                'YLim', obj.Boundaries, ...
                'Box', 'on', ...
                'XColor','k','YColor','k', ...
                'XTick', [], 'YTick', [], ...
                'NextPlot', 'add');
            faces = [1:20,1];
            theta = linspace(0,2*pi,numel(faces)+1);
            theta = theta(1:(end-1));
            vertices1 = [cos(theta)'.*obj.Target1Radius, sin(theta)'.*obj.Target1Radius];
            obj.Target1 = patch(obj.Axes, ...
                'Faces', faces, ...
                'Vertices', vertices1, ...
                'FaceColor', 'r', ...
                'EdgeColor', 'k', ...
                'Visible', 'off', ...
                'Tag', 'Target1');
            vertices2 = [cos(theta)'.*obj.Target2Radius, sin(theta)'.*obj.Target2Radius];
            obj.Target2 = patch(obj.Axes, ...
                'Faces', faces, ...
                'Vertices', vertices2, ...
                'FaceColor', 'r', ...
                'EdgeColor', 'k', ...
                'Visible', 'off', ...
                'Tag', 'Target1');
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
            obj.Visible = true;
        end

        function setCursorPosition(obj, x, y)
            if obj.Visible
                set(obj.Cursor,'XData',x,'YData',y);
            end
        end

        function setPrimaryTargetPosition(obj, x, y)
            arguments
                obj
                x (1,1) double
                y (1,1) double
            end
            set(obj.Target1,'XData',obj.Target1.XData + x,'YData',obj.Target1.YData + y);
        end

        function setPrimaryTargetColor(obj, cdata)
            arguments
                obj
                cdata (1,3) double
            end
            obj.Target1.MarkerFaceColor = cdata;
        end

        function setPrimaryTargetVisible(obj, visible)
            arguments
                obj
                visible (1,1) logical
            end
            obj.Target1.Visible = matlab.lang.OnOffSwitchState(visible);
        end

        function setSecondaryTargetPosition(obj, x, y)
            arguments
                obj
                x (1,1) double
                y (1,1) double
            end
            set(obj.Target2,'XData',obj.Target2.XData + x,'YData',obj.Target2.YData + y);
        end

        function setSecondaryTargetColor(obj, cdata)
            arguments
                obj
                cdata (1,3) double
            end
            obj.Target2.MarkerFaceColor = cdata;
        end

        function setSecondaryTargetVisible(obj, visible)
            arguments
                obj
                visible (1,1) logical
            end
            obj.Target2.Visible = matlab.lang.OnOffSwitchState(visible);
        end

        function delete(obj)
            if ~isempty(obj.Figure)
                if isvalid(obj.Figure)
                    obj.Figure.DeleteFcn = [];
                end
            end
            delete(obj.Figure);
        end
    end
end