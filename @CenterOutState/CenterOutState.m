classdef CenterOutState < int32
    %CENTEROUTSTATE Enumeration class for more-general Center-Out task state machine.
    %
    %   This enumeration class is *newer* than TaskState, which was
    %   previously used with the Wrist Task. This class should be used
    %   moving forward where possible, so that the Wrist and Delta tasks
    %   can be put into compatibility.
    
    enumeration
        unknown (-1)
        idle (0)
        t1_pre (1)
        t1_hold_1 (2)
        t1_hold_2 (3)
        go (4)
        move (5)
        t2_hold_1 (6)
        overshoot (7)
    end
end



