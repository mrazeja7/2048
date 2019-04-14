% create map, initialize colors and draw the screen for the first time.

map = ones(4)*NaN;
map = spawn_number(map);
map = spawn_number(map);
score = 0;

% https://tex.stackexchange.com/questions/174806/how-can-i-create-a-template-for-2048-game-situations
hexcolors = ["CCC0B3","EEE4DA","EDE0C8","F2B179", ...
             "F59563","F67C5F","F65E3B","EDCF72", ...
             "EDCC61","EDC850","EDC53F","EDC22E","3E3933",...% first 3 lines = numbers
             "FBF7F2","BBADA0","776E65", "F9F6F2"]; % base, background, dark text, light text
colors = [];

for i = hexcolors
    colors = cat(1,colors, hex2rgb(i{1}));
end
colors = colors ./255;

game_data = {map, score, colors};

screenPos = [500 250 768 768];

fig = figure('name','mrazeja7_2048', 'NumberTitle','off', 'Menu', 'none', ...
             'Units', 'pixels', 'Position', screenPos);
set(fig, 'KeypressFcn', @handleGame);
set(fig, 'UserData', game_data);

draw_board(game_data);
% end of initialization, the game is controlled by the handleGame function
% from this point on.

function rgb = hex2rgb(hexString)
	if size(hexString,2) ~= 6
        disp(hexString)
		error('invalid input: not 6 characters');        
	else
		r = double(hex2dec(hexString(1:2)));
		g = double(hex2dec(hexString(3:4)));
		b = double(hex2dec(hexString(5:6)));
		rgb = [r, g, b];
	end
end

function handleGame(~,E)
    data = get(gcbf, 'UserData');
    matrix = data{1};
    old = matrix;
    score = data{2};
    switch E.Key
        case 'downarrow'
            [matrix, score] = move_down(matrix, score);
        case 'uparrow'
            [matrix, score] = move_up(matrix, score);
        case 'leftarrow'
            [matrix, score] = move_left(matrix, score);
        case 'rightarrow'
            [matrix, score] = move_right(matrix, score);
        otherwise
            % if any other key is pressed, don't do anything.
            return;
    end
    
    % only spawn a new number if movement was made
    if (~isequaln(old, matrix)) % ignore the fact that NaN != NaN
        matrix = spawn_number(matrix);
    end
    
    data{1} = matrix;
    data{2} = score;
    
    draw_board(data);
    
    set(gcbf, 'UserData', data);
end

function draw_board(data)
    clf;
    
    square_size = 1.5;
    grid_size = 0.05;
    matrix = data{1};
    matrix = rot90(matrix, -1);
    colors = data{3};
    base_color = colors(14,:);
    bg_color = colors(15,:);
    fontsize = 30;
    
    axis equal;
    hold on;
    
    game_position = [0.75 0.75 4.5 5.5].*square_size;
    board_position = [1 1 4 4].*square_size;
    
    % background for the whole app
    rectangle('Position', game_position, ...
                'Curvature',0, 'FaceColor', base_color, 'EdgeColor', 'none');
    
    %background for the board
    rectangle('Position', board_position, ...
                'Curvature',0.03, 'FaceColor', bg_color, 'EdgeColor', 'none');
    
    for i = 1:1:4
        for j = 1:1:4
            if (~isnan(matrix(i,j)))
                number = int2str(matrix(i,j));
                color_id = round(log2(matrix(i,j)));
            else
                number = '';
                color_id = 0;
            end
            
            square_color = colors(color_id+1,:);
            
            if (color_id <= 2); font_color = colors(16,:); else font_color = colors(17,:); end;
            rectangle('Position', ...
                [i+grid_size j+grid_size 1-2*grid_size 1-2*grid_size].*square_size, ...
                'Curvature',0.08, 'FaceColor', square_color, 'EdgeColor', 'none');
            text((i+0.5)*square_size,(j+0.5)*square_size,number, ...
                'FontSize', fontsize, 'FontName', 'Helvetica', ...
                'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
                'verticalAlignment', 'middle', 'Color', font_color);
        end
    end
    
    % score banner    
    score = data{2};
    scoretxt = {'SCORE', int2str(score)};
    
    scorebox_size = [1.25 0.85].*square_size;
    scorebox_pos = [3.75 5.15].*square_size;
    scoretext_pos = (scorebox_pos + scorebox_size./2);
    
    rectangle('Position',(cat(2, scorebox_pos, scorebox_size)), ...
        'Curvature',0.1, 'FaceColor', bg_color, 'EdgeColor', 'none');
    
    text(scoretext_pos(1), scoretext_pos(2), scoretxt, 'FontName', 'Helvetica', ...
         'FontWeight', 'bold', 'FontSize', fontsize/2, 'HorizontalAlignment', 'center', ...
          'verticalAlignment', 'middle', 'Color', colors(17,:));
      
    check_game_over(data);
    check_game_won(data);
      
    axis off;
end

function won = check_game_won(data)
    matrix = data{1};
    won = 0;
    if (max(matrix(:)) == 2048)
        disp('you win!');
        won = 1;
    end
end

function over = check_game_over(data)
    matrix = data{1};
    over = 1;
    % check if there are any free spaces left (if yes - game isn't over)
    if (sum(isnan(matrix(:))) == 0)
        %draw_game_over([1 1 1 1], 0);
        % check for possible moves - are any two blocks the same value?
        for i = 1:1:4
            for j = 1:1:4
                % easiest way to avoid bad indexes
                try above = matrix(i-1,j); catch above = NaN; end;
                try below = matrix(i+1,j); catch below = NaN; end;
                try left = matrix(i,j-1);  catch left = NaN;  end;
                try right = matrix(i,j+1); catch right = NaN; end;                    
                
                if ((matrix(i,j) == above) | ...
                    (matrix(i,j) == below) | ...
                    (matrix(i,j) == left)  | ...
                    (matrix(i,j) == right))
                    % some moves still possible
                    over = 0;
                    disp('There are still possible moves');
                    return;
                end                
            end
        end
    else
        over = 0;
        return;
    end
    disp('Game over!');
end

function draw_game_over(game_position, won)
    if (won ~= 0)
        color = 'black';
    else
        color = 'yellow';
    end
    
    rectangle('Position', game_position, 'FaceColor', color);
end

function [newmatrix, newscore] = move_left(matrix, score)
    rotated = rot90(matrix, 2);
    [result, newscore] = move_right(rotated, score);
    newmatrix = rot90(result, 2);
end

function [newmatrix, newscore] = move_up(matrix, score)
    rotated = rot90(matrix, -1);
    [result, newscore] = move_right(rotated, score);
    newmatrix = rot90(result, 1);
end

function [newmatrix, newscore] = move_down(matrix, score)
    rotated = rot90(matrix, 1);
    [result, newscore] = move_right(rotated, score);
    newmatrix = rot90(result, -1);
end

function [ret, score] = move_right(matrix, score)
    % prevent blocks from merging multiple times in one move
    merged = zeros(4);
    for i = 1:1:4
        reps = 3;
        % blocks might move more than one spot at a time (not more than 3
        % times though)
        while (reps > 0)
            for j = 3:-1:1
                if (isnan(matrix(i,j+1)))
                    % shift
                    matrix(i,j+1) = matrix(i,j);
                    matrix(i,j) = NaN;
                elseif ((matrix(i,j+1) == matrix(i,j)) ...
                        && merged(i,j+1) ~= 1 && merged(i,j) ~= 1)
                    
                    % merge
                    matrix(i,j+1) = 2*matrix(i,j+1);
                    matrix(i,j) = NaN;
                    merged(i,j+1) = 1;
                    % adjust score
                    score = score + matrix(i,j+1);
                end
            end
            reps = reps - 1;
        end
    end    
    ret = matrix;
end

function mat = spawn_number(matrix)
    % puts a 2 in a random unoccupied spot
    free_spaces = isnan(matrix);
    free_spaces = (free_spaces .* rand(4));
    [~,index] = max(free_spaces(:));
    matrix(index) = 2;
    mat = matrix;
end
