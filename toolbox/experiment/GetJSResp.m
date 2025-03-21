function [buttonPress] = GetJSResp(options)
% This gets a gamepad response. This is not using Psychtoolbox.
%
% Syntax:
%    [buttonPress] = GetJSResp(numGamepad)
%
% Description:
%    This gets a single button press from the gamepad. This is based on the
%    gamepad from Logitech F310. Before using this routine, the gamepad
%    should be read out first using the routine 'OpenJS'. After the use of
%    it, it can be closed out with the routine 'CloseJS'.
%
%    For this project, we will only use the colored four buttons on the
%    right and one button on the side top left. Those are all mapped with
%    the type 1. It could be updated as we wish later on.
%
% Inputs:
%    N/A
%
% Outputs:
%    buttonPress                - Shows which button was pressed on the
%                                 gamepad.
%
% Optional key/value pairs:
%    verbose                    - Boolean. Default true. Controls
%                                 printout.
%
% See also:
%    N/A

% History:
%   09/11/24 smo                - Wrote it.
%   03/10/25 smo                - Modified it to work on Windows.
%   03/21/25 smo                - Added all possible button options on the
%                                 gamepad on Windows.

%% Set variables.
arguments
    options.typeButton (1,1) = 1;
    options.numButtonUp (1,1) = 3;
    options.numButtonDown (1,1) = 0;
    options.numButtonLeft (1,1) = 2;
    options.numButtonRight (1,1) = 1;
    options.numButtonSideLeft (1,1) = 4;
    options.verbose = true;
end

%% Open the gamepad.
%
% Decide which machine is on use. We will decide either we are using Linux
% machine or EIZO monitor. Linux machine gets connected to js0 for gamepad,
% which is a typically first joystick on the system.
gamepadDirLinux = '/dev/input/js0';

if isfolder(gamepadDirLinux)
    % Linux.
    computerType = 'linux';

    % Check if there is availabe gamepad.
    numGamepad = fopen(gamepadDirLinux,'rb');
    if (numGamepad == -1)
        error('Unable to open joystick device.');
    end
else
    % EIZO monitor. We use different function as it's on Windows.
    computerType = 'windows';

    % Open the gamepad.
    numGamepad = 1;
    vr = vrjoystick(numGamepad);
end

%% Get a button press here.
%
% Only the buttons within the array 'buttonPressOptions' would be
% activated. For now, we only activate the four directional buttons on the
% right side of the gamepad and the one on the side left.
buttonPress = [];
% buttonPressOptions = {'up','down','left','right','sideleft',...
%     'sideright','back','start','lefthandle','righthandle'};
buttonPressOptions = {'up','down','left','right','back'};

while true
    % We use slightly different functions across different machines.
    switch computerType
        case 'linux'
            % Read out 8 bytes from the joystick input stream.
            numBytes = 8;
            data = fread(numGamepad, numBytes);

            % Check if we get the button press okay.
            if isempty(data)
                break;
            end

            % Button type.
            typeButton = data(7);
            % Button number.
            numButton = data(8);

            % Check the button type.
            if (typeButton == options.typeButton)
                % Get the string of which button was pressed.
                if (numButton == options.numButtonUp)
                    buttonPress = 'up';
                elseif (numButton == options.numButtonDown)
                    buttonPress = 'down';
                elseif (numButton == options.numButtonLeft)
                    buttonPress = 'left';
                elseif (numButton == options.numButtonRight)
                    buttonPress = 'right';
                elseif (numButton == options.numButtonSideLeft)
                    buttonPress = 'sideleft';
                end
            end

        case 'windows'
            % Read the button state.
            buttonState = button(vr);

            % Get the string of which button was pressed. Allocated numbers
            % for the buttons are different from the Linux functions, so
            % update them here.
            numButtonUpWindows = 4;
            numButtonDownWindows = 1;
            numButtonLeftWindows = 3;
            numButtonRightWindows = 2;
            numButtonSideLeftWindows = 5;
            numButtonSideright = 6;
            numBottonLefthandle = 9;
            numBottonRighthandle = 10;

            if buttonState(numButtonUpWindows)
                buttonPress = 'up';
            elseif buttonState(numButtonDownWindows)
                buttonPress = 'down';
            elseif buttonState(numButtonLeftWindows)
                buttonPress = 'left';
            elseif buttonState(numButtonRightWindows)
                buttonPress = 'right';
            elseif buttonState(numButtonSideLeftWindows)
                buttonPress = 'sideleft';
            elseif buttonState(numButtonSideright)
                buttonPress = 'sideright';
            elseif buttonState(numButtonBack)
                buttonPress = 'back';
            elseif buttonState(numBottonStart)
                buttonPress = 'start';
            elseif buttonState(numBottonLefthandle)
                buttonPress = 'lefthandle';
            elseif buttonState(numBottonRighthandle)
                buttonPress = 'righthandle';
            end
        otherwise
    end

    % Close the loop if we got a valid button press.
    if ~isempty(buttonPress)
        if ismember(buttonPress,buttonPressOptions)
            break;
        end
    end
end

% Display which button was pressed.
if (options.verbose)
    fprintf('Button pressed - (%s) \n', buttonPress);
end
end
