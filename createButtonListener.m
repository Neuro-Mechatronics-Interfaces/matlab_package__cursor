function lh = createButtonListener(cursorObj, buttonNum, buttonEvent, fcn)
%CREATEBUTTONLISTENER  Creates listener handle for specific button-down/up and indexing combination.

arguments
    cursorObj (1,1) cursor.Cursor
    buttonNum (1,1) {mustBeInteger, mustBeInRange(buttonNum,1,8)}
    buttonEvent {mustBeMember(buttonEvent, {'ButtonDown', 'ButtonUp'})}
    fcn = []; % Function handle
end

if isempty(fcn)
    lh = addlistener(cursorObj, buttonEvent, @(~,evt)displayButtonInfo(evt,buttonNum));
else
    lh = addlistener(cursorObj, buttonEvent, fcn);
end

    function displayButtonInfo(evt, num)
        switch evt.EventName
            case 'ButtonDown'
                if bitand(evt.NewState, 2^(num-1))==(2^(num-1)) && (bitand(evt.PreviousState, 2^(num-1))==0)
                    fprintf(1,'Button-%02d pressed!\n', num);
                end
            case 'ButtonUp'
                if bitand(evt.PreviousState, 2^(num-1))==(2^(num-1)) && (bitand(evt.NewState, 2^(num-1))==0)
                    fprintf(1,'Button-%02d released!\n', num);
                end
        end
    end
end