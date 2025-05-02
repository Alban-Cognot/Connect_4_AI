%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ALIA
%%% Hexanome : H4131
%%% Connect 4
%%% Due November 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% A Prolog Implementation of Puissance 4
%%% using the minimax strategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




:- use_module(library(ansi_term)).
print_colored_text(Color, Text):-
    ansi_format([fg(Color)], '~w', [Text]).
/*


The following conventions are used in this program...




Single letter variables represent:


L - a list
N - a number, position, index, or counter
V - a value (usually a string)
A - an accumulator
H - the head of a list
T - the tail of a list


For this implementation, these single letter variables represent:


P - a player number (1 or 2)
B - the board (a 42 item list representing a 6x7 matrix)
each "square" on the board can contain one of 3 values: y ,r, or e (for empty)
S - the position of a square on the board (1 - 42)
M - a mark on a square (y or r)
E - the mark used to represent an empty square ('e').
U - the eval_centre value of a board position
R - a random number
D - the depth of the minimax search tree (for outputting eval_centre values, and for debugging)
C - column number played 


Variables with a numeric suffix represent a variable based on another variable.
(e.g. B2 is a new board position based on B)




For predicates, the last variable is usually the "return" value.
(e.g. opponent_mark(P,M), returns the opposing mark in variable M)


Predicates with a numeric suffix represent a "nested" predicate.


e.g. myrule2(...) is meant to be called from myrule(...)
 and myrule3(...) is meant to be called from myrule2(...)




There are only two assertions that are used in this implementation


asserta( board(B) ) - the current board
asserta( player(P, Type) ) - indicates which players are human/computer.


*/




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% FACTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




next_player(1, 2).  %%% determines the next player after the given player
next_player(2, 1).


inverse_mark('y', 'r'). %%% determines the opposite of the given mark
inverse_mark('r', 'y').




player_mark(1, 'y').%%% the mark for the given player
player_mark(2, 'r').




opponent_mark(1, 'r').  %%% shorthand for the inverse mark of the given player
opponent_mark(2, 'y').


blank_mark('e').%%% the mark used in an empty square


maximizing('y').%%% the player playing y is always trying to maximize the eval_centre of the board position
minimizing('r').%%% the player playing r is always trying to minimize the eval_centre of the board position


corner_square(1, 1).%%% map corner squares to board squares
corner_square(2, 7).
corner_square(3, 36).
corner_square(4, 42).




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MAIN PROGRAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


run :-
hello,  %%% Display welcome message, initialize game




play(1, S),%%% Play the game starting with player 1


goodbye(S) %%% Display end of game message
.


run :-
goodbye(0)
.


cls:-
    write('\33\[2J').

hello :-
initialize,
cls,
nl,
nl,
nl,
write('Welcome to Connect 4.'),
read_players,
output_players
.


initialize :-
random_seed,  %%% use current time to initialize random number generator
blank_mark(E),
asserta( board([E,E,E,E,E,E,E, E,E,E,E,E,E,E, E,E,E,E,E,E,E, E,E,E,E,E,E,E, E,E,E,E,E,E,E, E,E,E,E,E,E,E]) )  %%% create a blank board
.


goodbye(S) :-
board(B),
output_board(B),
nl,
nl,
retract(board(_)),
retract(player(_,_)),
read_play_again(V), !,
(V == 'Y' ; V == 'y'),
!,
run
.


read_play_again(V) :-
nl,
nl,
write('Play again (Y/N)? '),
read(V),
(V == 'y' ; V == 'Y' ; V == 'n' ; V == 'N'), !
.


read_play_again(V) :-
nl,
nl,
write('Please enter Y or N.'),
read_play_again(V)
.


read_players :-
nl,
nl,
write('Number of human players? '),
read(N),
set_players(N)
.


set_players(0) :-
asserta( player(1, computer) ),
asserta( player(2, computer) ), !
.


set_players(1) :-
nl,
write('Is human playing Y or R (Y moves first)? '),
read(M),
human_playing(M), !
.


set_players(2) :-
asserta( player(1, human) ),
asserta( player(2, human) ), !
.


set_players(N) :-
nl,
write('Please enter 0, 1, or 2.'),
read_players
.


human_playing(M) :-
(M == 'y' ; M == 'Y'),
asserta( player(1, human) ),
asserta( player(2, computer) ), !
.


human_playing(M) :-
(M == 'r' ; M == 'R'),
asserta( player(1, computer) ),
asserta( player(2, human) ), !
.


human_playing(M) :-
nl,
write('Please enter Y or R.'),
set_players(1)
.


play(P, S) :- %S is the last play
board(B), !,
output_board(B), !,
make_move(P, B, S1), !,
not(game_over(P, B, S1)), !,
next_player(P, P2), !,
play(P2, S1), !
.


%.......................................
% square
%.......................................
% The mark in a square(N) corresponds to an item in a list, as follows:


square(B,N,M):-get_item(B,N,V),V=M.


%.......................................
% falling position
%.......................................
% fall(B,C,H) gives the height H of the token when it falls in column C of the board B, if this column is not full


fall(B, C, H) :-
    fall2(B, C, 1, H1),
    H = H1 - 1,!,
    H > 0
    .


fall2(B, C, K, H) :-
    I is C + (K - 1) * 7,
    fall3(B, C, K, H, I)
    .


fall3(B, C, K, H, I) :-
    I < 43,
    get_item(B, I, V),
    fall4(B, C, K, H, V)
    .


fall3(B, C, K, H, I) :-
    H = 7
    .


fall4(B, C, K, H, V) :-
    blank_mark(V),
    K1 is K + 1,
    fall2(B, C, K1, H)
    .


fall4(B, C, K, H, V) :-
    H = K
    .


%.......................................
% win
%.......................................
% Players win by having their mark in one of the following square configurations:
%
win(B,M,S):-
    winCol(B,M,S).
win(B,M,S):-
    winRow(B,M,S).
win(B,M,S):-
    winDiag1(B,M,S).
win(B,M,S):-
    winDiag2(B,M,S).
winCol(B,M,S1):-
    down(S1,S2),
    square(B,S2,M),
down(S2,S3),
    square(B,S3,M),
down(S3,S4),
    square(B,S4,M).
winRow(B,M,S1):-
    lookLeft(B,M,S1,Nl),!,
    lookRight(B,M,S1,Nr),!,
    N is Nr+Nl,N>4.


% lookLeft for winRow
lookLeft(B,M,S,Nl):-
    left(S,S1),
leftVerif(B,M,S1,1,Nl).
leftVerif(B,M,S,N,N):-
    not(square(B,S,M)).
leftVerif(B,M,S,N,N):-
    V is S mod 7,
    V == 0.
leftVerif(B,M,S,N,Nl):-
    N1 is N+1,
    left(S,S1),
    leftVerif(B,M,S1,N1,Nl).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%lookright for winRow
lookRight(B,M,S,Nl):-
    right(S,S1),
rightVerif(B,M,S1,1,Nl).
rightVerif(B,M,S,N,N):-
    not(square(B,S,M)).
rightVerif(B,M,S,N,N):-
    V is S mod 7,
    V == 1.
rightVerif(B,M,S,N,Nr):-
    N1 is N+1,
    right(S,S1),
    rightVerif(B,M,S1,N1,Nr).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
winDiag1(B,M,S):-
    lookUpLeft(B,M,S,Nl),!,
    lookDownRight(B,M,S,Nr),!,
    N is Nr+Nl, N > 4.
lookUpLeft(B,M,S,Nl):-
    upLeft(S,S1),
upLeftVerif(B,M,S1,1,Nl).
upLeftVerif(B,M,S,N,N):-
    not(square(B,S,M)).
upLeftVerif(B,M,S,N,N):-
    V is S mod 7,
    V == 0.
upLeftVerif(B,M,S,N,Nl):-
    N1 is N+1,
    upLeft(S,S1),
upLeftVerif(B,M,S1,N1,Nl).
lookDownRight(B,M,S,Nl):-
    downRight(S,S1),
downRightVerif(B,M,S1,1,Nl).
downRightVerif(B,M,S,N,N):-
    not(square(B,S,M)).
downRightVerif(B,M,S,N,N):-
    V is S mod 7,
    V == 1.
downRightVerif(B,M,S,N,Nl):-
    N1 is N+1,
    downRight(S,S1),
downRightVerif(B,M,S1,N1,Nl).
winDiag2(B,M,S):-
    lookUpRight(B,M,S,Nr),!,
    lookDownLeft(B,M,S,Nl),!,
    N is Nr+Nl, N > 4.
lookUpRight(B,M,S,Nr):-
upRight(S,S1),
upRightVerif(B,M,S1,1,Nr).  
upRightVerif(B,M,S,N,N):-
    not(square(B,S,M)).
upRightVerif(B,M,S,N,N):-
    V is S mod 7,
    V == 1.  
upRightVerif(B,M,S,N,Nr):-
    N1 is N+1,
    upRight(S,S1),
    upRightVerif(B,M,S1,N1,Nr).
lookDownLeft(B,M,S,Nr):-
downLeft(S,S1),
downLeftVerif(B,M,S1,1,Nr).
downLeftVerif(B,M,S,N,N):-
    not(square(B,S,M)).
downLeftVerif(B,M,S,N,N):-
    V is S mod 7,
    V == 0.    
downLeftVerif(B,M,S,N,Nr):-
    N1 is N+1,
    downLeft(S,S1),
    downLeftVerif(B,M,S1,N1,Nr).
%.......................................
% utils
%.......................................
down(X,X1):-
    X1 is X+7.
left(X,X1):-
    X1 is X-1.
right(X,X1):-
    X1 is X+1.
upLeft(X,X1):-
    X1 is X-8.
downRight(X,X1):-
    X1 is X+8.
upRight(X,X1):-
    X1 is X-6.
downLeft(X,X1):-
    X1 is X+6.
%.......................................
% move
%.......................................
% applies a move on the given board
% (put mark M in square S on board B and return the resulting board B2)
%


move(B,C,M,B2,S) :-
    fall(B, C, H),
    S is C + (H - 1) * 7,
    set_item(B,S,M,B2)
    .


%.......................................
% game_over
%.......................................
% determines when the game is over
%
game_over(P, B, S) :-
    game_over2(P, B, S)
.


game_over2(P, B, S) :-
    player_mark(P, M),  %%% game is over if you win
    win(B, M, S),
    cls,
    nl,
    nl,
    write('Player '),
    write(M),
    write(' is the winner !'),
    nl,
    nl
    .


game_over2(P, B, S) :-
    blank_mark(E),
    not(square(B,S,E))
    .


%.......................................
% make_move
%.......................................
% requests next move from human/computer,
% then applies that move to the given board
%


make_move(P, B, S) :-
    player(P, Type),
    make_move2(Type, P, B, B2, S),
    retract( board(_) ),
    asserta( board(B2) )
    .


make_move2(human, P, B, B2,S) :-
    nl,
    nl,
    write('Player '),
    write(P),
    write(' move? '),
    read(C),
    fall(B, C, _),
    player_mark(P, M),
    move(B, C, M, B2, S), !,
    cls
    .


make_move2(human, P, B, B2,S) :-
    nl,
    nl,
    write('Please don t select a full column.'),
    make_move2(human,P,B,B2,S)
    .


make_move2(computer, P, B, B2, S) :-
    nl,
    nl,
    cls,
    write('Computer is thinking about next move...'),
    nl,
    player_mark(P, M),!,
    moves(B,-10,ListMoves),
    best(5,B,M,ListMoves,S, -10000, 10000, C1, (C, U)),
    move(B,C,M,B2,S),!,
    nl,
    nl,
    write('Computer places '),
    write(M),
    write(' in column '),
    write(C),
    write('.')
    .


%.......................................
% moves
%.......................................
% retrieves a list of available moves (empty squares) on a board.
%


moves(B,S, L) :-
    (S == -10 ;
    (square(B,S,M),
    not(win(B, M, S)))),
    C is 7,!,
    findall_(C,B,[],L),!,
    L \= []
    .
findall_(7,B,L1,L):-
    fall(B,7,_),
    findall_(1,B,[7|L1],L)
    .
findall_(7,B,L1,L):-
    findall_(1,B,L1,L)
    .
findall_(1,B,L1,L):-
    fall(B,1,_),
    findall_(6,B,[1|L1],L)
    .
findall_(1,B,L1,L):-
    findall_(6,B,L1,L)
    .
findall_(6,B,L1,L):-
    fall(B,6,_),
    findall_(2,B,[6|L1],L)
    .
findall_(6,B,L1,L):-
    findall_(2,B,L1,L)
    .
findall_(2,B,L1,L):-
    fall(B,2,_),
    findall_(5,B,[2|L1],L)
    .
findall_(2,B,L1,L):-
    findall_(5,B,L1,L)
    .
findall_(5,B,L1,L):-
    fall(B,5,_),
    findall_(3,B,[5|L1],L)
    .
findall_(5,B,L1,L):-
    findall_(3,B,L1,L)
    .
findall_(3,B,L1,L):-
    fall(B,3,_),
    findall_(4,B,[3|L1],L)
    .
findall_(3,B,L1,L):-
    findall_(4,B,L1,L)
    .
findall_(4,B,L1,L):-
    fall(B,4,_),
    findall_(0,B,[4|L1],L)
    .
findall_(4,B,L1,L):-
    findall_(0,B,L1,L)
    .
findall_(0,B,L,L).

%.......................................
% best
%.......................................
% determines the best move in a given list of moves by recursively calling minimax
%


% if there is more than one move in the list...

best(D,B,M,[],S,Alpha,Beta,Move,(Move, Alpha) ):-
    maximizing(M)
    .

best(D,B,M,[],S,Alpha,Beta,Move,(Move, Beta) ).

best(D,B,M,[C1|T],S,Alpha, Beta, Move1, BestMove ) :-
    move(B,C1,M,B2,S1), %%% apply the first move (in the list) to the board,
    inverse_mark(M,M2),
    minimax(D,B2,M2,_C,S1,U1,Alpha, Beta ),  %%% recursively search for the eval_centre value of that move,
    pre_cut_off(M, C1, U1, D, Alpha, Beta, T, B, Move1, BestMove )  ,
    output_value(D,C1,U1)
    .


%.......................................
% minimax
%.......................................
% The minimax algorithm always assumes an optimal opponent.
% For tic-tac-toe, optimal play will always result in a tie, so the algorithm is effectively playing not-to-lose.


% For the opening move against an optimal player, the best minimax can ever hope for is a tie.
% So, technically speaking, any opening move is acceptable.
% Save the user the trouble of waiting  for the computer to search the entire minimax tree
% by simply selecting a random square.


minimax(D,[E,E,E,E,E,E,E, E,E,E,E,E,E,E, E,E,E,E,E,E,E, E,E,E,E,E,E,E, E,E,E,E,E,E,E, E,E,E,E,E,E,E],M,C,S,U, Alpha, Beta ) :-
    blank_mark(E),
    C is 4,
    !
    .

minimax(0,B,M,C,S,U,Alpha, Beta ) :-
    !,
    eval_global(B,S,U)
    .

minimax(D,B,M,C,S,U,Alpha, Beta ) :-
    D2 is D - 1,
    moves(B,S,ListMoves),  %%% get the list of available moves
    best(D2,B,M,ListMoves,S, Alpha, Beta, nil, (C, U) )  %%% recursively determine the best available move
    .
% if there are no more available moves,
% then the minimax value is the eval_global of the given board position
minimax(D,B,M,C,S,U,Alpha, Beta ) :-
   eval_global(B,S,U).

%.......................................
% cut_off
%.......................................

%cut_off is for alpha-beta pruning
pre_cut_off(M, Move, Value, D, Alpha, Beta, ListMoves, B, Move1, BestMove ):-
    maximizing(M),
    cut_off_max(M, Move, Value, D, Alpha, Beta, ListMoves, B, Move1, BestMove )
    .

pre_cut_off(M, Move, Value, D, Alpha, Beta, ListMoves, B, Move1, BestMove ):-
    cut_off_min(M, Move, Value, D, Alpha, Beta, ListMoves, B, Move1, BestMove )
    .

cut_off_max(M, Move, Value, D, Alpha, Beta, ListMoves, B, Move1, (Move, Value) ):-
    Value >= Beta.
cut_off_max(M, Move, Value, D, Alpha, Beta, ListMoves, B,Move1, BestMove ):-
    Alpha < Value,
    Value < Beta,
    best(D, B, M, ListMoves, S, Value, Beta,Move,BestMove)
    .
cut_off_max(M, Move, Value, D, Alpha, Beta, ListMoves, B, Move1, BestMove ):-
    Value =< Alpha,
    best(D, B, M, ListMoves, S, Alpha, Beta, Move1, BestMove )
    .

cut_off_min(M, Move, Value, D, Alpha, Beta, ListMoves, B, Move1, (Move, Value) ):-
    Value =< Alpha.
cut_off_min(M, Move, Value, D, Alpha, Beta, ListMoves, B, Move1, BestMove ):-
    Alpha < Value,
    Value < Beta,
    best(D, B, M, ListMoves, S, Alpha, Value, Move, BestMove )
    .
cut_off_min(M, Move, Value, D, Alpha, Beta, ListMoves, B, Move1, BestMove ):-
    Value >= Beta,
    best(D, B, M, ListMoves, S, Alpha, Beta, Move1, BestMove )
    .

%.......................................
% EVALS
%.......................................
% determines the value of a given board position
%

eval_global(B,S,U) :-
    square(B,S,y),
    win(B,y,S),
    U = 1000,
    !
    .


eval_global(B,S,U) :-
    square(B,S,r),
    win(B,r,S),
    U = (-1000),
    !
    .



eval_global(B,S,U):-
    eval_centre(B,U_centre),
    !,
    evalPosition(B,U_align),
    !,
    U is U_centre + U_align,
    !
    .






eval_centre(B,U) :-
    U1 = 0,
    eval_centre2(B,B, U1, 1, 1, U)
    .


eval_centre2(B,[], U1, Poids,  Increment, U1).


eval_centre2(B, L, U1, 0,  Increment, U):-
    Increment1 is 1,
    Poids is Increment1,
    eval_centre2(B, L, U1, Poids,  Increment1, U)
    .
eval_centre2(B,[X|Tail], U1, Poids,  Increment, U):-
    Poids \== 4,
    eval_centre3(B,[X|Tail], U1, Poids,  Increment,U)
    .
eval_centre2(B,[X|Tail], U1, Poids,  Increment, U):-
    Increment1 is -1,
    eval_centre3(B,[X|Tail], U1, Poids, Increment1, U)
    .
eval_centre3(B,[X|Tail], U1, Poids, Increment, U):-
    X == y,    
    U2 is U1 + Poids,
    Poids1 is Poids + Increment,
    eval_centre2(B,Tail, U2, Poids1,  Increment, U)
    .
eval_centre3(B,[X|Tail], U1, Poids,  Increment, U):-
    X == r,
    U2 is U1 - Poids,
    Poids1 is Poids + Increment,
    eval_centre2(B,Tail, U2, Poids1,  Increment, U)
    .
eval_centre3(B,[X|Tail], U1, Poids,  Increment, U):-
    Poids1 is Poids + Increment,
    eval_centre2(B,Tail, U1, Poids1,  Increment, U)
    .
eval_centre4(B,[X|Tail], U1, Poids,  Increment, U):-    
    U2 is U1 + Poids,
    Poids1 is Poids + Increment,
    eval_centre2(B,Tail, U2, Poids1,  Increment, U)
    .

%.......................................
% evaluation of the alignments
%.......................................


evalPosition(B, Eval) :-

    % columns
    
    get_item(B, 36, FirstMarkCol),
    evalRecursivity(B, [29, 22, 15, 8, 1, -1, 37, 30, 23, 16, 9, 2, -1, 38, 31, 24, 17, 10, 3, -1, 39, 32, 25, 18, 11, 4, -1, 40, 33, 26, 19, 12, 5, -1, 41, 34, 27, 20, 13, 6, -1, 42, 35, 28, 21, 14, 7, -1], 0, 0, FirstMarkCol, EvalYellowCol, 0, r),
    evalRecursivity(B, [29, 22, 15, 8, 1, -1, 37, 30, 23, 16, 9, 2, -1, 38, 31, 24, 17, 10, 3, -1, 39, 32, 25, 18, 11, 4, -1, 40, 33, 26, 19, 12, 5, -1, 41, 34, 27, 20, 13, 6, -1, 42, 35, 28, 21, 14, 7, -1], 0, 0, FirstMarkCol, EvalRedCol, 0, y),
    EvalCol is EvalYellowCol - EvalRedCol,
    
   

    % rows
    
    get_item(B, 1, FirstMarkRow),
    evalRecursivity(B, [2, 3, 4, 5, 6, 7, -1, 8, 9, 10, 11, 12, 13, 14, -1, 15, 16, 17, 18, 19, 20, 21, -1, 22, 23, 24, 25, 26, 27, 28, -1, 29, 30, 31, 32, 33, 34, 35, -1, 36, 37, 38, 39, 40, 41, 42, -1], 0, 0, FirstMarkRow, EvalYellowRow, 0, r),
    evalRecursivity(B, [2, 3, 4, 5, 6, 7, -1, 8, 9, 10, 11, 12, 13, 14, -1, 15, 16, 17, 18, 19, 20, 21, -1, 22, 23, 24, 25, 26, 27, 28, -1, 29, 30, 31, 32, 33, 34, 35, -1, 36, 37, 38, 39, 40, 41, 42, -1], 0, 0, FirstMarkRow, EvalRedRow, 0, y),
    EvalRow is EvalYellowRow - EvalRedRow,
   
  

    % ascending diagonals
    
    get_item(B, 22, FirstMarkDiag1),
    evalRecursivity(B, [16, 10, 4, -1, 29, 23, 17, 11, 5, -1, 36, 30, 24, 18, 12, 6, -1, 37, 31, 25, 19, 13, 7, -1, 38, 32, 26, 20, 14, -1, 39, 33, 27, 21, -1], 0, 0, FirstMarkDiag1, EvalYellowDiag1, 0, r),
    evalRecursivity(B, [16, 10, 4, -1, 29, 23, 17, 11, 5, -1, 36, 30, 24, 18, 12, 6, -1, 37, 31, 25, 19, 13, 7, -1, 38, 32, 26, 20, 14, -1, 39, 33, 27, 21, -1], 0, 0, FirstMarkDiag1, EvalRedDiag1, 0, y),
    EvalDiag1 is EvalYellowDiag1 - EvalRedDiag1,
    
   

    % descending diagonals
  
    get_item(B, 15, FirstMarkDiag2),
    evalRecursivity(B, [23, 31, 39, -1, 8, 16, 24, 32, 40, -1, 1, 9, 17, 25, 33, 41, -1, 2, 10, 18, 26, 34, 42, -1, 3, 11, 19, 27, 35, -1, 4, 12, 20, 28, -1], 0, 0, FirstMarkDiag2, EvalYellowDiag2, 0, r),
    evalRecursivity(B, [23, 31, 39, -1, 8, 16, 24, 32, 40, -1, 1, 9, 17, 25, 33, 41, -1, 2, 10, 18, 26, 34, 42, -1, 3, 11, 19, 27, 35, -1, 4, 12, 20, 28, -1], 0, 0, FirstMarkDiag2, EvalRedDiag2, 0, y),
    EvalDiag2 is EvalYellowDiag2 - EvalRedDiag2,
   

    Eval is EvalRow + EvalCol + EvalDiag1 + EvalDiag2,
    !
    .




%.......................................
% generic algorithm for the evaluation
% give it the traversal of the grid (with the bounds), and the opposite mark
% it will evaluate all the potential sequences
%.......................................

% endpoint
evalRecursivity(_, [], _, _, _, Eval1, Eval1, _).
    
% iteration
evalRecursivity(B, [Pos1|Tail], Len, LenMark, Mark, Eval, Eval1, OppositeMark) :-
    (Mark \= OppositeMark -> 
        (Mark \= e -> 
            LenMark1 is LenMark + 1 ; 
            LenMark1 is LenMark), 
        Len1 is Len + 1 ;
    (Len1 is Len,
    LenMark1 is LenMark)),
    (Pos1 = -1 -> evalAdd(B, Tail, Len1, LenMark1, Pos1, NumCol, Mark, Mark1, Eval, Eval1, OppositeMark) ; 
                  (get_item(B, Pos1, Mark1), evalCompare(B, Tail, Len1, LenMark1, Pos1, NumCol, Mark, Mark1, Eval, Eval1, OppositeMark))),
    !
    .

% considering the new mark
evalCompare(B, Tail, Len, LenMark, Pos, NumCol, Mark, Mark1, Eval, Eval1, OppositeMark) :-
    (Mark1 = OppositeMark -> evalAdd(B, Tail, Len, LenMark, Pos, NumCol, Mark, OppositeMark, Eval, Eval1, OppositeMark) ;
                             evalRecursivity(B, Tail, Len, LenMark, Mark1, Eval, Eval1, OppositeMark)),
    !
    .

% calculating the new evaluation
evalAdd(B, Tail, Len, LenMark, Pos, NumCol, Mark, Mark1, Eval, Eval1, OppositeMark) :-
    ((Len < 4 ; LenMark < 2) -> NewEval is Eval1 ;
                                NewEval is Eval1 + 2**LenMark),
    evalRecursivity(B, Tail, 0, 0, Mark1, Eval, NewEval, OppositeMark),
    !
    .


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


output_players :-
nl,
player(1, V1),
write('Player 1 is '),   %%% either human or computer
write(V1),


nl,
player(2, V2),
write('Player 2 is '),   %%% either human or computer
write(V2),
!
.


output_winner(B,S) :-
win(B,y,S),
write('Y wins.'),
!
.


output_winner(B,S) :-
win(B,r,S),
write('R wins.'),
!
.


output_winner(B,S) :-
write('No winner.')
.


output_board(B) :-
nl,
nl,
write('| 1 | 2 | 3 | 4 | 5 | 6 | 7 |'),
nl,
write('-----------------------------'),
nl,
write('|'),
output_square(B,1),
write('|'),
output_square(B,2),
write('|'),
output_square(B,3),
write('|'),
output_square(B,4),
write('|'),
output_square(B,5),
write('|'),
output_square(B,6),
write('|'),
output_square(B,7),
write('|'),
nl,
write('-----------------------------'),
nl,
write('|'),
output_square(B,8),
write('|'),
output_square(B,9),
write('|'),
output_square(B,10),
write('|'),
output_square(B,11),
write('|'),
output_square(B,12),
write('|'),
output_square(B,13),
write('|'),
output_square(B,14),
write('|'),
nl,
write('-----------------------------'),
nl,
write('|'),
output_square(B,15),
write('|'),
output_square(B,16),
write('|'),
output_square(B,17),
write('|'),
output_square(B,18),
write('|'),
output_square(B,19),
write('|'),
output_square(B,20),
write('|'),
output_square(B,21),
write('|'),
nl,
write('-----------------------------'),
nl,
write('|'),
output_square(B,22),
write('|'),
output_square(B,23),
write('|'),
output_square(B,24),
write('|'),
output_square(B,25),
write('|'),
output_square(B,26),
write('|'),
output_square(B,27),
write('|'),
output_square(B,28),
write('|'),
nl,
write('-----------------------------'),
nl,
write('|'),
output_square(B,29),
write('|'),
output_square(B,30),
write('|'),
output_square(B,31),
write('|'),
output_square(B,32),
write('|'),
output_square(B,33),
write('|'),
output_square(B,34),
write('|'),
output_square(B,35),
write('|'),
nl,
write('-----------------------------'),
nl,
write('|'),
output_square(B,36),
write('|'),
output_square(B,37),
write('|'),
output_square(B,38),
write('|'),
output_square(B,39),
write('|'),
output_square(B,40),
write('|'),
output_square(B,41),
write('|'),
output_square(B,42),
write('|'),
nl,
write('-----------------------------'), !
.


output_board :-
board(B),
output_board(B), !
.


output_square(B,S) :-
square(B,S,M),
write(' '),
output_square2(S,M),
write(' '), !
.


output_square2(S, E) :-
blank_mark(E),
write("*"), !  %%% if square is empty, output the square number
.


output_square2(S, r) :-
print_colored_text(red, r), !  %%% if square is marked, output the mark
.
output_square2(S, y) :-
print_colored_text(yellow, y), !  %%% if square is marked, output the mark
.


output_value(D,C,U) :-
D == 5,
nl,
write('Column '),
write(C),
write(', eval_centre: '),
write(U), !
.


output_value(D,C,U) :-
true
.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PSEUDO-RANDOM NUMBERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%.......................................
% random_seed
%.......................................
% Initialize the random number generator...
% If no seed is provided, use the current time
%


random_seed :-
random_seed(_),
!
.


random_seed(N) :-
nonvar(N),
% Do nothing, SWI-Prolog does not support seeding the random number generator
!
.


random_seed(N) :-
var(N),
% Do nothing, SWI-Prolog does not support seeding the random number generator
!
.


%.......................................
% random_int_1n
%.......................................
% returns a random integer from 1 to N
%
random_int_1n(N, V) :-
V is random(N) + 1,
!
.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LIST PROCESSING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

member([V|T], V).
member([_|T], V) :- member(T,V).

append([], L, L).
append([H|T1], L2, [H|T3]) :- append(T1, L2, T3).

%.......................................
% set_item
%.......................................
% Given a list L, replace the item at position N with V
% return the new list in list L2
%

set_item(L, N, V, L2) :-
set_item2(L, N, V, 1, L2)
.

set_item2( [], N, V, A, L2) :-
N == -1,
L2 = []
.

set_item2( [_|T1], N, V, A, [V|T2] ) :-
A = N,
A1 is N + 1,
set_item2( T1, -1, V, A1, T2 )
.

set_item2( [H|T1], N, V, A, [H|T2] ) :-
A1 is A + 1,
set_item2( T1, N, V, A1, T2 )
.
%.......................................
% get_item
%.......................................
% Given a list L, retrieve the item at position N and return it as value V
%
get_item(L, N, V) :-
get_item2(L, N, 1, V)
.
get_item2( [], _N, _A, V) :-
V = [], !,
fail
.

get_item2( [H|_T], N, A, V) :-
A = N,
V = H
.
get_item2( [_|T], N, A, V) :-
A1 is A + 1,
get_item2( T, N, A1, V)
.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% End of program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%