%   Copyright 2022 Olexandr Kalenuk (akalenuk@gmail.com)
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

-module(utils).
-compile(export_all).

date_to_list({D1, D2, D3}) ->
    integer_to_list(D1) ++ "_" ++ integer_to_list(D2) ++ "_" ++ integer_to_list(D3).

list_to_date(L) ->
    Ds = string:tokens(L, "_"),
    list_to_tuple([list_to_integer(D) || D <- Ds]).

% kind of presudo-localization?
color_to_word("white") -> "white";
color_to_word("red") -> "red";
color_to_word("green") -> "green";
color_to_word("blue") -> "blue";
color_to_word("yellow") -> "yellow";
color_to_word(_) -> "unrecognizeable".

month_to_word(1) -> "Jan";
month_to_word(2) -> "Feb";
month_to_word(3) -> "Mar";
month_to_word(4) -> "Apr";
month_to_word(5) -> "May";
month_to_word(6) -> "Jun";
month_to_word(7) -> "Jul";
month_to_word(8) -> "Aug";
month_to_word(9) -> "Sep";
month_to_word(10) -> "Oct";
month_to_word(11) -> "Nov";
month_to_word(12) -> "Dec";
month_to_word(_) -> "no month".

integer_to_2list(I) ->
    case I < 10 of
        true -> "0" ++ integer_to_list(I);
        _ -> integer_to_list(I)
    end.

time_to_word(Timestamp) ->
    {{Y, M, D}, {Ho, Mi, _Se}} = calendar:now_to_local_time(Timestamp),
    integer_to_list(D)++" "++month_to_word(M)++" "++integer_to_list(Y)++" "++
    integer_to_list(Ho)++":"++integer_to_2list(Mi).

test() ->
    N = now(),
    [
        date_to_list({1, 2, 3}) == "1_2_3",
        list_to_date( date_to_list(N) ) == N
    ].
