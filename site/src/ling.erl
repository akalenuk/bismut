%   Copyright 2022 Oleksandr Kalenuk (akalenuk@gmail.com)
%
%   Licensed under the Apache License, Version 2.0 (the "License");
%   you may not use this file except in compliance with the License.
%   You may obtain a copy of the License at
%
%       http://www.apache.org/licenses/LICENSE-2.0
%
%   Unless required by applicable law or agreed to in writing, software
%   distributed under the License is distributed on an "AS IS" BASIS,
%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%   See the License for the specific language governing permissions and
%   limitations under the License.

-module(ling).
-compile(export_all).
-author("akalenuk@gmail.com").

%common
split(String, Separator) ->
    Pos = string:str(String, Separator),
    case Pos of
        0 ->
            [String];
        _ ->
            [string:left(String, Pos-1)] ++ split(string:right(String, length(String) - length(Separator) - Pos + 1), Separator)
    end.

join(String, Separator) ->
    string:join(String, Separator).

part([], _, _) ->
    [];
part(List, From, To) ->
    N = fun(X) ->
        case X<0 of
            true ->
                XX = length(List) + 1 + X,
                case XX<1 of
                    true -> 1;
                    false -> XX
                end;
            false ->
                case X > length(List) of
                    true -> length(List);
                    false -> X
                end
        end
    end,
    RealFrom = N(From),
    RealTo = N(To),
    case RealTo<RealFrom of
        true -> "";
        false -> string:sub_string(List, N(From), N(To))
    end.

clean(String, Dirt) ->
    join(split(String, Dirt), "").

replace(String, Dirt, Icecream) ->
    join(split(String, Dirt), Icecream).

replace_a_lot(String, []) ->
    String;
replace_a_lot(String, [H| T]) ->
    {Before, After} = H,
    replace_a_lot( replace(String, Before, After), T).

flatten([]) -> [];
flatten([H| T]) ->
    case H of
        [] -> flatten(T);
        _ ->
            case is_list(hd(H)) of
                false ->
                    [H] ++ flatten(T);
                true ->
                    flatten(H) ++ flatten(T)
            end
    end.

same_shit(A, B) ->
    case length(A) == length(B) of
        true ->
            A_in_B = lists:usort([lists:member(Ai, B) || Ai <- A]) == [true],
            B_in_A = lists:usort([lists:member(Bi, A) || Bi <- B]) == [true],
            A_in_B and B_in_A;
        false ->
            false
    end.

% rare
replace_in_or_out_brackets(String, Dirt, Icecream, Brackets, InOrOut) ->
    OB = part(Brackets, 1, 1),
    CB = part(Brackets, 2, 2),
    OpenTagPairs = split(String, CB), % bla bla bla <a href='#'
    join([   
        begin
            OutIn = split(OTPair, OB),
            case length(OutIn) of
                0 ->
                    "";
                1 -> 
                    OTPair;
                2 ->
                    case InOrOut of
                        in ->
                            NewOutIn = [hd(OutIn)] ++ [replace(hd(tl(OutIn)), Dirt, Icecream)];
                        out ->
                            NewOutIn = [replace(hd(OutIn), Dirt, Icecream)] ++ [hd(tl(OutIn))]
                    end,
                    join(NewOutIn, OB);
                _ ->
                    throw(wtf_error)
            end
        end
         || OTPair <- OpenTagPairs
    ], CB).

replace_out_brackets(String, Dirt, Icecream, Brackets) ->
    replace_in_or_out_brackets(String, Dirt, Icecream, Brackets, out).

replace_in_brackets(String, Dirt, Icecream, Brackets) ->
    replace_in_or_out_brackets(String, Dirt, Icecream, Brackets, in).


trim_to_first([], _) ->
    [];
trim_to_first(String, First) ->
    case part(String, 1, length(First)) == First of
        false ->
            trim_to_first(tl(String), First);
        true ->
            String
    end.

trim_from_last(String, Last) ->
    lists:reverse(trim_to_first(lists:reverse(String), Last)).

do_with_tokens(String, Fun, []) ->
    Fun(String);
do_with_tokens(String, Fun, [SeparatorsH | SeparatorsT]) ->
    join([do_with_tokens(S, Fun, SeparatorsT) || S <- split(String, SeparatorsH)], SeparatorsH).

a_href(String) ->
    case part(String, 1, 7) == "http://" of 
        true ->
            "<a href='" ++ String ++ "'>" ++ String ++ "</a>";
        false ->
            String
    end.

test() ->
    [
        % common
        split("dirt and dirty things. <dirt href='dirtydirt'>!", "dirt") == 
            [""," and ","y things. <", " href='","y","'>!"],

        join([""," and ","y things. <", " href='","y","'>!"], "icecream") ==
            "icecream and icecreamy things. <icecream href='icecreamyicecream'>!",

        clean("dirt and dirty things. <dirt href='dirtydirt'>!", "dirt") ==
            " and y things. < href='y'>!",

        replace("dirt and dirty things. <dirt href='dirtydirt'>!", "dirt", "icecream") ==
            "icecream and icecreamy things. <icecream href='icecreamyicecream'>!",

        replace_a_lot("dirt and dirty things. <dirt href='dirtydirt'>!", [
            {"dirt", "icecream"},
            {"and", "but"},
            {"thing", "stuff"},
            {"href", "src"}
        ]) == "icecream but icecreamy stuffs. <icecream src='icecreamyicecream'>!",

        same_shit(["1","2","3"], ["3","1","2"]) == true,
        same_shit(["1","2","3"], ["3","2"]) == false,
        same_shit(["1","2","3"], ["3","2","2"]) == false,

        part("1234567890", 2, -2) == "23456789",
        part("1234567890", 2, 5) == "2345",
        part("1234567890", -5, -1) == "67890",
        part("1234567890", 3, 3) == "3",
        part("1234567890", -15, 15) == "1234567890",
        part("1234567890", 15, -15) == "",

        flatten(["1",["2","3"],"4",[["5",["6",["7","8"]]],"9"],"0"]) == ["1","2","3","4","5","6","7","8","9","0"],

        % rare
        replace_in_brackets("dirt and dirty things. <dirt href='dirtydirt'>!", "dirt", "icecream", "<>") ==
            "dirt and dirty things. <icecream href='icecreamyicecream'>!",

        replace_out_brackets("dirt and dirty things. <dirt href='dirtydirt'>!", "dirt", "icecream", "<>") ==
            "icecream and icecreamy things. <dirt href='dirtydirt'>!",

        trim_to_first("dirt and dirty things. <dirt href='dirtydirt'>!", "<") ==
            "<dirt href='dirtydirt'>!",

        trim_from_last("dirt and dirty things. <dirt href='dirtydirt'>!", "<") ==
            "dirt and dirty things. <",
 
        do_with_tokens("Here: http://synrc.com!", fun a_href/1, [" ", ",", "?", "!"]) ==
            "Here: <a href='http://synrc.com'>http://synrc.com</a>!"
    ].
