%% -*- mode: nitrogen -*-

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

-module(index).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% The page
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

main() -> #template { file="./site/templates/bare.html" }.

title() -> "Bismut".

body() ->
    #container_12 { body=[
        #grid_8 { alpha=true, prefix=2, suffix=2, omega=true, body=inner_body() }
    ]}.

inner_body() -> 
    wf:user(undefined),
    [
        #panel{style="background-color:#eee; padding:11px;", body=[
            "<font face='sans-serif' size='5'>Bismut</font>"
        ]},
        #br{},
        #br{},
        #panel{style="padding:11px;", body="This is a collaborative task tracker. Like a traditional bug tracker but with hierarhical items. If you get the concept but want something different, contact me at: <a href='mailto:akalenuk@gmail.com'>akalenuk@gmail.ua</a>."},
        #br{},
        #br{},
        #span{style="padding:11px; font-size:16pt;", text="Task books:"},
        #panel{style="padding:11px; line-height:20pt;", body=
            [begin
                TS = hd(lists:reverse(ling:split(Key, "/"))),
                case salode:load(Key ++ "/name", no_name) of 
                    no_name -> [];
                    Name ->
                        Comment = salode:load(Key ++ "/description", ""),
                        [
                            #link{url="/tasks?of="++TS, text=Name},
                            case Comment of
                                "" -> "";
                                _ -> ": " ++ Comment
                            end,
                            #br{}
                        ]
                end
            end
            || Key <- lists:usort(salode:ls("data"))]
        },
        #br{},
        #br{},
        #span{style="padding:11px; font-size:16pt;", text="Create a new task book:"},
        #br{},
        #br{},
        #singlerow{style="padding-left:11px;", cells=#tablecell{align="right", body=[
            "URL name: ",
            #textbox{id=new_project_url},
            #br{},
            "Readble name: ",
            #textbox{id=new_project_name},
            #br{},
            "Description: ",
            #textbox{id=new_project_description},
            #br{},
            #br{},
            "Superuser login: ",
            #textbox{id=new_project_su_login},
            #br{},
            "Superuser password: ",
            #textbox{id=new_project_su_password},
            #br{},
            #br{},
            "Invite code: ",
            #textbox{id=new_project_invite},
            #br{},
            #button{text="Add one", postback=add_new_project}
        ]}},
        #br{},
        #br{},
        #span{style="padding:11px; font-size:16pt;", text="Source code: "},
        #br{},
        #br{},
        #link{style="padding:11px;", text="https://github.com/akalenuk/bismut", url="https://github.com/akalenuk/bismut"},
        #panel{style="padding:11px; font-size:11pt;", body="Source code is licensed with <a href='http://www.apache.org/licenses/LICENSE-2.0.html'>Apache&nbsp;2.0</a>. TL&DR: you do whatever you want, I don't take any responsibility."},
        #panel{style="padding:11px; font-size:11pt;", body="This is a &laquo;<a href='http://nitrogenproject.com/'>Nitrogen</a>&raquo; site. To run your own instance, download Nitrogen, put the sources into the <pre>site/</pre> folder, and run the Nitrogen node by running <pre>bin/nitrogen console</pre>."},
        #br{},
        #br{}
    ].


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

event(add_new_project) ->
    URLId = wf:q(new_project_url),
    Name = wf:q(new_project_name),
    Description = wf:q(new_project_description),

    SULogin = wf:q(new_project_su_login),
    SUPassword = wf:q(new_project_su_password),

    Invite = wf:q(new_project_invite),

    case check_url_id_latin(URLId) of
        not_ok -> wf:wire(#alert{text="You should only use latin, numbers, and the underscore in the URL name. E. g. \"manhattan_project_1945\""});
        ok -> 
            case check_url_id_taken(URLId) of
                not_ok -> wf:wire(#alert{text="Sorry, this URL is taken."});
                ok ->
                    case length(Name) > 16*2 of % that's wrong, consuder UTF-8
                        true -> wf:wire(#alert{text="Sorry, the readable name should be short. 16 characters or less."});
                        _ ->
                            case length(Description) > 44*2 of % this is also wrong
                                true -> wf:wire(#alert{text="Sorry, the description should also be short. 44 symbols or less."});
                                _ ->
                                    case SULogin of 
                                        "" -> wf:wire(#alert{text="Sorry, the superuser login should not remain empty."});
                                        _ ->
                                            case use_invite(Invite) of 
                                                not_ok -> wf:wire(#alert{text="Sorry, seems like somebody already used this invite code."});
                                                ok ->
                                                    salode:save("data/"++URLId++"/name", Name),
                                                    salode:save("data/"++URLId++"/description", Description),
                                                    salode:save("data/"++URLId++"/people/"++SULogin++"/password", SUPassword),
                                                    settings:set_rights_preset(URLId, SULogin, "su"),
                                                    wf:redirect("/tasks?of="++URLId)
                                            end
                                    end
                            end
                    end
            end
    end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

check_url_id_latin([]) -> ok;
check_url_id_latin([H| T]) -> 
    case ((H >= $a) and (H =< $z)) or ((H >= $0) and (H =< $9)) or (H == $_) or (H == $-) of
        true -> check_url_id_latin(T);
        _ -> not_ok
    end.

check_url_id_taken(Id) ->
    L = salode:ls("data"),
    case lists:member("data/"++Id, L) of
        true -> not_ok;
        _ -> ok
    end.

use_invite(Invite) ->
    case Invite of 
        "Just let me in." -> ok; % this is a magic phrase to enter without invite
        _ ->
            L = salode:ls("data/invite_list"),
            case lists:member("data/invite_list/"++Invite, L) of
                true ->
                    salode:delete("data/invite_list/"++Invite),
                    ok;
                _ ->
                    not_ok
            end
    end.
