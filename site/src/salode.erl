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

-module(salode).
-compile(export_all).
-author("akalenuk@gmail.com").

save(Key, Value) ->
    Dir = ling:trim_from_last(Key, "/"),
    filelib:ensure_dir(Dir),
    ok = file:write_file(Key, term_to_binary(Value)).

load(Key) ->
    {ok, Bin} = file:read_file(Key),
    binary_to_term(Bin).
load(Key, Default) ->
    {Res, BinOrNot} = file:read_file(Key),
    case Res of
        error -> Default;
        ok -> binary_to_term(BinOrNot)
    end.

delete("") ->
    ok;
delete(Key) ->
    file:delete(Key),
    Cleanup = fun(CleanupFun, Dir) ->
        case file:del_dir(Dir) of
            ok -> CleanupFun(CleanupFun, ling:trim_from_last( ling:part(Dir, 1, -2), "/") );
            _ -> ok
        end
    end,
    Cleanup(Cleanup, ling:trim_from_last(Key, "/")).

ls() ->
    ls(".").
ls(Path) ->
    {Res, FilesOrNot} = file:list_dir(Path),
    case Res of
        error -> [];
        ok -> [Path ++ "/" ++ File || File <- FilesOrNot]
    end.

keys() ->
    keys(".").
keys(Path) ->
    {ok, Files} = file:list_dir(Path),
    ling:flatten([
        begin
            {ok, FileInfo} = file:read_file_info(Path ++ "/" ++ FileOrDirectory),
            case element(3, FileInfo) of
                regular ->
                    Path ++ "/" ++ FileOrDirectory;
                directory ->
                    keys(Path ++ "/" ++ FileOrDirectory);
                _ ->
                    []
            end
        end
        || FileOrDirectory <- Files
    ]).


test() ->
    T = [[],{},{2, "the text"},[3,{the_atom}]],
    save("dir/subdir/file", T),
    [
        load("dir/subdir/file") == T,
        keys("dir") == ["dir/subdir/file"],
        delete("dir/subdir/file") == ok
    ].
