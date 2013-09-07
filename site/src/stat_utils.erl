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

-module(stat_utils).
-compile(export_all).

-define(COLORS, ["red", "yellow", "green", "blue", "white"]).
    
count_tasks_in( Key, Color ) ->
    case salode:load( Key ++ "/color", none ) of
	Color -> 1;
	none -> 0;
        Other -> case Color of
            any -> 1;
            _ -> 0
        end
    end + lists:sum([count_tasks_in( SubTask, Color ) || SubTask <- salode:ls( Key ++ "/tasks" )]).

count_tasks( Project, Color ) ->
    Key = "data/" ++ Project,
    count_tasks_in( Key, Color ).

stat_by_color( Project ) ->
    [{Col, count_tasks(Project, Col)} || Col <- ?COLORS].
    
stat() ->
    Stats = [{
         Key, 
         [{Col, count_tasks_in(Key, Col)} || Col <- ?COLORS], 
         count_tasks_in(Key, any)
     }
    || Key <- salode:ls("data")],
    {Stats, lists:sum([N || {_, _, N} <- Stats]) }.