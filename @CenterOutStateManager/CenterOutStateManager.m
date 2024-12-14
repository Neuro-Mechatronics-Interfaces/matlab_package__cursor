classdef CenterOutStateManager < handle
    %CENTEROUTSTATEMANAGER  Class for managing trial state for a center-out behavioural task. 

    properties
        State (1,1) cursor.CenterOutState = cursor.CenterOutState.idle;
        TTrial (1,1) = 0;
        TMove (1,1) = 0;
        Overshoots (1,1) = 0;
        Outcome (1,1) logical = false;
    end

    properties (Access = protected)
        TState (1,1) = 0;
        InTarget (1,2) logical = [false, false];
        HoldRequired (1,3) single = [1.0, 0.5, 0.5];
        MoveLimit (1,1) single = 1.0;
        TotalLimit (1,1) single = 10.0;
    end

    events
        NewState
        TrialCompleted
    end

    methods
        function obj = CenterOutStateManager()
        end
        function update(obj, delta_t)
            if obj.State ~= cursor.CenterOutState.idle
                obj.TState = obj.TState + delta_t;
                if (obj.TState + obj.TTrial) >= obj.TotalLimit
                    obj.Outcome = false;
                    setState(obj, cursor.CenterOutState.idle);
                end
            end
            switch obj.State
                case cursor.CenterOutState.idle % Do nothing
                    return;
                case cursor.CenterOutState.t1_pre
                    if obj.InTarget(1)
                        obj.setState(cursor.CenterOutState.t1_hold_1);
                        return;
                    end
                case cursor.CenterOutState.t1_hold_1
                    if ~obj.InTarget(1)
                        obj.setState(cursor.CenterOutState.t1_pre);
                        return;
                    end
                    if obj.TState >= obj.HoldRequired(1)
                        obj.setState(cursor.CenterOutState.t1_hold_2);
                        return;
                    end
                case cursor.CenterOutState.t1_hold_2
                    if ~obj.InTarget(1)
                        obj.setState(cursor.CenterOutState.idle);
                        return;
                    end
                    if obj.TState >= obj.HoldRequired(2)
                        obj.setState(cursor.CenterOutState.go);
                        return;
                    end
                case cursor.CenterOutState.go
                    if ~obj.InTarget(1)
                        obj.setState(cursor.CenterOutState.move);
                        return;
                    end
                case cursor.CenterOutState.move
                    if obj.TState >= obj.MoveLimit
                        obj.setState(cursor.CenterOutState.idle);
                        return;
                    end
                    if obj.InTarget(2)
                        obj.setState(cursor.CenterOutState.t2_hold_1);
                        return;
                    end
                case cursor.CenterOutState.t2_hold_1
                    if obj.TState >= obj.HoldRequired(3)
                        obj.Outcome = true;
                        obj.setState(cursor.CenterOutState.idle);
                        return;
                    end
                    if ~obj.InTarget(2)
                        obj.Overshoots = obj.Overshoots + 1;
                        obj.setState(cursor.CenterOutState.overshoot);
                        return;
                    end
                case cursor.CenterOutState.overshoot
                    if obj.InTarget(2)
                        obj.setState(cursor.CenterOutState.t2_hold_1);
                        return;
                    end
                otherwise
                    error("Unhandled state: %s", string(obj.State));
            end
        end
        
        function setCursorTargetState(obj, targetIndex, cursorState)
            %SETCURSORTARGETSTATE  Sets the cursor state for the indexed target.
            %
            % Syntax:
            %   obj.setCursorTargetState(targetIndex, cursorState);
            %
            % Inputs:
            %   targetIndex - Index of the target (1 or 2)
            %   cursorState(1,1) logical - True if it is in the target. 

            obj.InTarget(targetIndex) = cursorState;
        end
        function setTrialParameters(obj, newHold, newLimit)
            %SETTRIALPARAMETERS  Set the parameters for current trial. 
            obj.HoldRequired = newHold;
            obj.MoveLimit = newLimit(1);
            obj.TotalLimit = newLimit(2);
            obj.setState(cursor.CenterOutState.t1_pre);
        end
    end
    methods (Access = protected)
        function setState(obj, newState)
            if obj.State == cursor.CenterOutState.move
                obj.TMove = obj.TState;
            end
            obj.TTrial = obj.TTrial + obj.TState;
            obj.TState = 0;
            obj.State = newState;
            if newState == cursor.CenterOutState.idle
                eventData = cursor.TrialCompletedEventData(obj.Outcome, obj.Overshoots, obj.TMove, obj.TTrial);
                notify(obj, 'TrialCompleted', eventData);
                obj.TMove = 0;
                obj.TTrial = 0;
                obj.Overshoots = 0;
                obj.Outcome = false;
            else
                notify(obj, 'NewState');
            end
        end
    end
end