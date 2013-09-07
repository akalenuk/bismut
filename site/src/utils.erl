%   Copyright 2013 Alexandr Kalenuk (akalenuk@gmail.com)
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

color_to_word("white") -> "белый";
color_to_word("red") -> "красный";
color_to_word("green") -> "зеленый";
color_to_word("blue") -> "синий";
color_to_word("yellow") -> "желтый";
color_to_word(_) -> "неизвестный".

month_to_word(1) -> "января";
month_to_word(2) -> "февраля";
month_to_word(3) -> "марта";
month_to_word(4) -> "апреля";
month_to_word(5) -> "мая";
month_to_word(6) -> "июня";
month_to_word(7) -> "июля";
month_to_word(8) -> "августа";
month_to_word(9) -> "сентября";
month_to_word(10) -> "октября";
month_to_word(11) -> "ноября";
month_to_word(12) -> "декабря";
month_to_word(_) -> "непонятно".

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
