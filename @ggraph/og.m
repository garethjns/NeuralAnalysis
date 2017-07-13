function og
%% Try and set openGL settings

% Is openGL available? Returns 1 if available
H = opengl('INFO');
if H == 1
    % Get information about OpenGL
    D = opengl('DATA');
    if D.Software == 1 % In software mode
        try
            % Try and switch to hardware
            opengl hardware
        catch err
            % Catch error, if switch fails (?)
            disp(err)
        end
    end
    
    % Confirm switch worked
    D = opengl('DATA');
    if D.Software==1
        % If not, warn and continue
        disp('Warning: Unable to set OpenGL to hardware.')
    else
        disp('OpenGL set to hardware.')
    end
    
else
    % H=0, openGL not available
    disp('Warning: OpenGL unavailable.')
end