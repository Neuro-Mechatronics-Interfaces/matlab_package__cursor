classdef AudioManager < handle
    
    properties
        go_player
        success_player
    end
    
    methods
        function obj = AudioManager()
            %AUDIOMANAGER  Construct an instance of audiomanager class.
            folderPath = fileparts(mfilename('fullpath'));
            goFile = fullfile(folderPath,'A1760.wav');
            successFile = fullfile(folderPath,'A880.wav');
            [Y,fs] = audioread(goFile);
            obj.go_player = audioplayer(Y,fs);
            [Y,fs] = audioread(successFile);
            obj.success_player = audioplayer(Y,fs);
        end

        function go(obj)
            stop(obj.success_player);
            play(obj.go_player);
        end

        function success(obj)
            stop(obj.go_player);
            play(obj.success_player);
        end
        
        function delete(obj)
            try %#ok<*TRYNC>
                delete(obj.go_player);
            end
            try
                delete(obj.success_player);
            end
        end
    end
end

