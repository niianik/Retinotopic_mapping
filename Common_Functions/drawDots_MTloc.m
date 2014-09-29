function [triggers] = drawDots_MTloc(display,dots,duration,Behaviour,KeyCodes,triggers,CyclingStart,PrevKeypr)%,datDirImg,filesImg,aviobj)
% drawDots_MTloc(display,dots,duration,datDirImg)
%
% Animates a field of moving dots based on parameters defined in the 'dots'
% structure over a period of seconds defined by 'duration'.
%
% The 'dots' structure must have the following parameters:
%
%   nDots            Number of dots in the field
%   speed            Speed of the dots (degrees/second)
%   direction        -1  expading
%                     1  contracting
%   lifetime         Number of frames for each dot to live
%   apertureSize     [x,y] size of elliptical aperture (degrees)
%   center           [x,y] Center of the aperture (degrees)
%   color            Color of the dot field [r,g,b] from 0-255
%   size             Size of the dots (in pixels)
%   coherence        Coherence from 0 (incoherent) to 1 (coherent)
%
% 'dots' can be an array of structures so that multiple fields of dots can
% be shown at the same time.  The order that the dots are drawn is
% scrambled across fields so that one field won't occlude another.
%
% The 'display' structure requires the fields:
%    width           Width of screen (cm)
%    dist            Distance from screen (cm)
% And can also use the fields:
%    skipChecks      If 1, turns off timing checks and verbosity (default 0)
%    fixation        Information about fixation (see 'insertFixation.m')
%    screenNum       screen number       
%    bkColor         background color 
%    windowPtr       window pointer, set by 'OpenWindow'
%    frameRate       frame rate, set by 'OpenWindow'
%    resolution      pixel resolution, set by 'OpenWindow'



% 12.06.2012   Niia Nikolova
%       expanding/contracting instead of translational motion
%  
%
% 02.07.2013    whole fields, instead of half
%               to be used by radialDots_1afc.m

%%
%Calculate total number of dots across fields
nDots = sum([dots.nDots]);

%Zero out the color and size vectors
colors = zeros(3,nDots);
sizes = zeros(1,nDots);

%Generate a random order to draw the dots so that one field won't occlude
%another field.
order=  randperm(nDots);

centerAperture = [1 1];
%% Intitialize the dot positions and define some other initial parameters
count = 1;

try 
    
    for i=1:length(dots) %Loop through the fields

        %Calculate the left, right top and bottom of each aperture (in degrees)
        l(i) = dots(i).center(1)-dots(i).apertureSize(1)/2;
        r(i) = dots(i).center(1)+dots(i).apertureSize(1)/2;
        b(i) = dots(i).center(2)-dots(i).apertureSize(2)/2;
        t(i) = dots(i).center(2)+dots(i).apertureSize(2)/2;


        %Generate random starting positions
        dots(i).x = (rand(1,dots(i).nDots)-.5)*(dots(i).apertureSize(1)) + dots(i).center(1);
        dots(i).y = (rand(1,dots(i).nDots)-.5)*dots(i).apertureSize(2) + dots(i).center(2);


        %Create a direction vector for a given coherence level
        direction = rand(1,dots(i).nDots)*360;                                                     
        nCoherent = ceil(dots(i).coherence*dots(i).nDots);  %Start w/ all random directions


        %Calculate dx and dy vectors in real-world coordinates
        direction(1:nCoherent) = dots(i).direction;  %Set the 'coherent' directions  (-1 expand, 1 contract)
%         dotSpeedPix = angle2pix(display,dots(i).speed);
        
        %dots(i).dx = -dots(i).speed.*(sin(direction))/display.frameRate;
        %dots(i).dy = -dots(i).speed.*(cos(direction))/display.frameRate;
    %     dots(i).dx = dots(i).x - dots(i).center(1); %-dots(i).speed.*(sin(direction))/display.frameRate;
    %     dots(i).dy = dots(i).y - dots(i).center(2); %-dots(i).speed.*(cos(direction))/display.frameRate;
        dlength = sqrt(dots(i).x.^2+dots(i).y.^2);
        dots(i).dx = direction .* dots(i).x ./ dlength * dots(i).speed/display.frameRate;
        dots(i).dy = direction .* dots(i).y ./ dlength * dots(i).speed/display.frameRate;

        dots(i).life =  ceil(rand(1,dots(i).nDots)*dots(i).lifetime);

        %Fill in the 'colors' and 'sizes' vectors for this field
        id = count:(count+dots(i).nDots-1);  %index into the nDots length vector for this field
        colors(:,order(id)) = repmat(dots(i).color(:),1,dots(i).nDots);
        DotSizesPix = angle2pix(display,dots(i).size);          % convert to pix
        sizes(order(id)) = repmat(DotSizesPix,1,dots(i).nDots);
        count = count+dots(i).nDots;


    end

    %Zero out the screen position vectors and the 'goodDots' vector
    pixpos.x = zeros(1,nDots);
    pixpos.y = zeros(1,nDots);
    goodDots = false(zeros(1,nDots));

    %Calculate total number of temporal frames
    nFrames = secs2frames(display,duration);


    %% Loop through the frames

    for frameNum=1:nFrames
        count = 1;

        % Trigger // Behavioural response 
        [pressed, firstPress] = KbQueueCheck;
        if pressed,
            if firstPress(KeyCodes.Escape)
                % Abort screen
                Screen('FillRect', display.windowPtr, display.bkColor);%, Rect);
                DrawFormattedText(display.windowPtr, 'Experiment was aborted!', 'center', 'center');
                WaitSecs(2);
                ShowCursor;
                Screen('CloseAll');
                disp(' ');
                disp('Experiment aborted by user!');
                disp(' ');
                KbQueueFlush;
                return
            end
            if GetSecs - PrevKeypr > 0.2,
                PrevKeypr = GetSecs;
                if firstPress(KeyCodes.Trigger),
                    triggers = [triggers; GetSecs GetSecs - CyclingStart];
                else
                    k = find(firstPress);
                    Behaviour.Response = [Behaviour.Response; k];
                    Behaviour.ResponseTime = [Behaviour.ResponseTime; ones(size(k))*(GetSecs - CyclingStart)];
                end
            end
        end



        for i=1:length(dots)  %Loop through the fields

             % Transform x and y into polar coordinates
            %[A,D] = cart2pol(dots(i).x,dots(i).y);

             % Update dot positions in polar coordinates
            %dots(i).x = (cos(A).*(D+dots(i).dx));
            %dots(i).y = (sin(A).*(D+dots(i).dy));
            dots(i).x = dots(i).x + dots(i).dx;
            dots(i).y = dots(i).y + dots(i).dy;


            %Move the dots that are outside the aperture back one aperture width.
            dots(i).x(dots(i).x<l(i)) = dots(i).x(dots(i).x<l(i)) + dots(i).apertureSize(1);
            dots(i).x(dots(i).x>r(i)) = dots(i).x(dots(i).x>r(i)) - dots(i).apertureSize(1);
            dots(i).y(dots(i).y<b(i)) = dots(i).y(dots(i).y<b(i)) + dots(i).apertureSize(2);
            dots(i).y(dots(i).y>t(i)) = dots(i).y(dots(i).y>t(i)) - dots(i).apertureSize(2);


            %Increment the 'life' of each dot
            dots(i).life = dots(i).life+1;

            %Find the 'dead' dots

            DotsX = repmat(dots(i).x',1,size(dots(i).x,2));
            DotsX = tril (bsxfun(@minus,DotsX,dots(i).x));

            DotsY = repmat(dots(i).y',1,size(dots(i).y,2));
            DotsY = tril (bsxfun(@minus,DotsY,dots(i).y));
            Dist = sqrt(DotsX.^2 + DotsY.^2);

            [WhichAlliasing,~] = find (Dist > 0 & Dist < 0.2);

            EdgeDots = (((dots(i).apertureSize(1)/2)-1) < sqrt((dots(i).x(WhichAlliasing) - dots(i).center(1)).^2 + (dots(i).y(WhichAlliasing) - dots(i).center(2)).^2));
            WhichAlliasing = WhichAlliasing.*EdgeDots';
            WhichAlliasing (WhichAlliasing==0) = [];

            deadDotsAlliasing = zeros (1,size(dots(i).x,2));
            deadDotsAlliasing(WhichAlliasing) = 1;

            deadDotsLifeTime = mod(dots(i).life,dots(i).lifetime)==0;
            deadDotsRadius = (((dots(i).apertureSize(1)/2)) < sqrt((dots(i).x - dots(i).center(1)).^2 + (dots(i).y - dots(i).center(2)).^2));
            deadDots = logical(deadDotsLifeTime | deadDotsRadius | deadDotsAlliasing);

            %Replace the positions of the dead dots to random locations
            dots(i).x(deadDots) = (rand(1,sum(deadDots))-.5)*(dots(i).apertureSize(1)) + dots(i).center(1);
            dots(i).y(deadDots) = (rand(1,sum(deadDots))-.5)*dots(i).apertureSize(2) + dots(i).center(2);

            %Calculat the displacement vectors
            dots(i).dx(deadDots) = dots(i).x(deadDots) - dots(i).center(1); %-dots(i).speed.*(sin(direction))/display.frameRate;
            dots(i).dy(deadDots) = dots(i).y(deadDots) - dots(i).center(2); %-dots(i).speed.*(cos(direction))/display.frameRate;
            dlength = sqrt(dots(i).dx(deadDots).^2+dots(i).dy(deadDots).^2);
            dots(i).dx(deadDots) = direction(deadDots) .* dots(i).dx(deadDots) ./ dlength * dots(i).speed/display.frameRate;
            dots(i).dy(deadDots) = direction(deadDots) .* dots(i).dy(deadDots) ./ dlength * dots(i).speed/display.frameRate;


            %Calculate the index for this field's dots into the whole list of
            %dots.  Using the vector 'order' means that, for example, the first
            %field is represented not in the first n values, but rather is
            %distributed throughout the whole list.
            id = order(count:(count+dots(i).nDots-1));

            %Calculate the screen positions for this field from the real-world coordinates
    %         pixpos.x(id) = angle2pix(display,dots(i).x + dots(i).center(1))+ display.resolution(1)/2;
    %         pixpos.y(id) = angle2pix(display,dots(i).y + dots(i).center(2))+ display.resolution(2)/2;
            pixpos.x(id) = angle2pix(display,dots(i).x) + display.resolution(1)/2;
            pixpos.y(id) = angle2pix(display,dots(i).y) + display.resolution(2)/2;

            %Determine which of the dots in this field are outside this fields
            %elliptical aperture
    %         goodDots(id) = (dots(i).x-dots(i).center(1)).^2/((dots(i).apertureSize(1)/2)^2) + ...
    %         (dots(i).y-dots(i).center(2)).^2/(dots(i).apertureSize(2)/2)^2 < 1;
            goodDots(id) = logical(((dots(i).x-dots(i).center(1)).^2/((dots(i).apertureSize(1)/2)^2) + ...
            (dots(i).y-dots(i).center(2)).^2/(dots(i).apertureSize(2)/2)^2 < 1) == ((dots(i).x-dots(i).center(1)).^2/((centerAperture(1)/2)^2) + ...
            (dots(i).y-dots(i).center(2)).^2/(centerAperture(2)/2)^2 > 1));

            count = count+dots(i).nDots;
        end

        %Draw all fields at once
        Screen('DrawDots',display.windowPtr,[pixpos.x(goodDots);pixpos.y(goodDots)], sizes(goodDots), colors(:,goodDots),[0,0],1);

        %Draw the fixation point (and call Screen's Flip')
        fixationPoint(display);     

    end
    %clear the screen and leave the fixation point
    %drawFixation(display);         % original fixation: black square in larger white square
    fixationPoint(display);         % new fixation: small square

catch ME
    rethrow(ME)
    % Abort screen
    Screen('FillRect', Win, Parameters.Background, Rect);
    DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center'); 
    WaitSecs(2);
    ShowCursor;
    Screen('CloseAll');
    disp(' '); 
    disp('Experiment aborted by user!'); 
    disp(' ');
    KbQueueFlush;
    return
end
