%% -*- mode: nitrogen -*-

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

-module(settings).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Page
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

main() -> 
    case wf:q("of") of
        undefined -> wf:redirect("/");
        Project ->
            case wf:session(project) of
                Project ->
                    wf:state(project, Project),
                    case wf:user() of
                        undefined -> wf:redirect("/login?of="++Project);
                        _ -> #template { file="./site/templates/bare.html" }
                    end;
                _ ->
                    wf:redirect("/login?of="++Project)
            end
    end.

title() -> "Bismut settings".

body() ->
    Name = salode:load("data/"++wf:state(project)++"/name", "error"),
    PR = salode:load("data/" ++ wf:state(project) ++ "/people/" ++ wf:user() ++ "/people", "none"),
    [
        #panel{style="background-color:#eee; padding:11px;", body=[
            #link{body="<font face='sans-serif' size='5'>"++Name++":</font>", style="color:#000;", url="/"},
            tab(),
            #link{text="Tasks", url="/tasks?of="++wf:state(project)},
            tab(),
            "Settings",
            tab(),
            case wf:user() of
                undefined -> #link{text="Login", url="/login?of="++wf:state(project)};
                _ -> ["You ", #link{text="logged in", url="/login?of="++wf:state(project)} ," as: <b>" ++ wf:user() ++ "</b>."]
            end
        ]},
        #br{},
        author_panel(),
        #br{},
        #br{},
        change_password_panel(),
        case (PR == "add") or (PR == "change") of
            true -> [
                #br{},
                #br{},
                #panel{id=rights_panel, body=rights_panel()}];
            _ -> []
        end,
        case PR == "add" of
            true -> [
                #br{},
                #br{},
                add_panel()];
            _ -> []
        end,
        #br{},
        #br{},
        #br{},
        #br{},
        #br{},
        #br{},
        #br{},
        #br{},
        #br{}
    ].

tab() ->
    "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".

rights_panel() ->
    #panel{class="people_tab", body=[
        #span{text="Table of priviledges:", style="padding-left:11px; font-size:16pt;"},
        #br{},
        #br{},
        #table{style="padding:6px;", rows=[
            #tablerow{cells=[
                #tableheader{body=[]},
                #tableheader{body="<nobr>take tasks</nobr>", style="background-color:#ffd;"},
                #tableheader{body="comment", style="background-color:#ffd;"},
                #tableheader{body="repaint", style="background-color:#ffd;"},
                #tableheader{body="<nobr>remove tasks</nobr>", style="background-color:#ffd;"},
                #tableheader{body="<nobr>hide subtasks</nobr>", style="background-color:#fef;"},
                #tableheader{body="<nobr>add tasks</nobr>", style="background-color:#fef;"},
                #tableheader{body="<nobr>alter priviledges</nobr>", style="background-color:#eff;"}
            ]}
        ] ++  
        [
            begin
                UId = hd(lists:reverse(ling:split(CKey, "/"))),
                _Password = salode:load(CKey ++ "/password", "<error>"),
                #tablerow{cells=[
                    #tablecell{body=UId},
                    #tablecell{body=[
                        #dropdown{
                            id=UId++"_task_take",
                            value=salode:load("data/" ++ wf:state(project) ++ "/people/" ++ UId ++ "/task_take", "none"), 
                            postback={change_rights, "task_take", UId},
                            options=[
                                #option{text="free", value="free"},
                                #option{text="any", value="any"},
                                #option{text="none", value="none"}
                            ]
                        }
                    ], style="background-color:#ffd;"},
                    #tablecell{body=[
                        #dropdown{
                            id=UId++"_task_comment",
                            value=salode:load("data/" ++ wf:state(project) ++ "/people/" ++ UId ++ "/task_comment", "none"), 
                            postback={change_rights, "task_comment", UId},
                            options=[
                                #option{text="own", value="own"},
                                #option{text="any", value="any"},
                                #option{text="none", value="none"}
                            ]
                        }
                    ], style="background-color:#ffd;"},
                    #tablecell{body=[
                        #dropdown{
                            id=UId++"_task_repaint",
                            value=salode:load("data/" ++ wf:state(project) ++ "/people/" ++ UId ++ "/task_repaint", "none"), 
                            postback={change_rights, "task_repaint", UId},
                            options=[
                                #option{text="own", value="own"},
                                #option{text="any", value="any"},
                                #option{text="none", value="none"}
                            ]
                        }
                    ], style="background-color:#ffd;"},
                    #tablecell{body=[
                        #dropdown{
                            id=UId++"_task_delete",
                            value=salode:load("data/" ++ wf:state(project) ++ "/people/" ++ UId ++ "/task_delete", "none"), 
                            postback={change_rights, "task_delete", UId},
                            options=[
                                #option{text="own", value="own"},
                                #option{text="any", value="any"},
                                #option{text="none", value="none"}
                            ]
                        }
                    ], style="background-color:#ffd;"},
                    #tablecell{body=[
                        #dropdown{
                            id=UId++"_subtask_hide",
                            value=salode:load("data/" ++ wf:state(project) ++ "/people/" ++ UId ++ "/subtask_hide", "none"), 
                            postback={change_rights, "subtask_hide", UId},
                            options=[
                                #option{text="own", value="own"},
                                #option{text="any", value="any"},
                                #option{text="none", value="none"}
                            ]
                        }
                    ], style="background-color:#fef;"},
                    #tablecell{body=[
                        #dropdown{
                            id=UId++"_task_create",
                            value=salode:load("data/" ++ wf:state(project) ++ "/people/" ++ UId ++ "/task_create", "none"), 
                            postback={change_rights, "task_create", UId},
                            options=[
                                #option{text="any", value="any"},
                                #option{text="sub-tasks only", value="sub"},
                                #option{text="none", value="none"}
                            ]
                        }
                    ], style="background-color:#fef;"},
                    #tablecell{body=[
                        #dropdown{
                            id=UId++"_people",
                            value=salode:load("data/" ++ wf:state(project) ++ "/people/" ++ UId ++ "/people", "none"), 
                            postback={change_rights, "people", UId},
                            options=[
                                #option{text="add", value="add"},
                                #option{text="change", value="change"},
                                #option{text="none", value="none"}
                            ]
                        }
                    ], style="background-color:#eff;"}
                ]}
            end
            || CKey <- lists:usort( salode:ls("data/" ++ wf:state(project) ++ "/people") )]
        }
    ]}.

add_panel() ->
    #panel{style="padding:11px;", body=[
        #span{text="Adding a teammate:", style="font-size:16pt;"},
        #br{},
        #br{},
        #singlerow{cells=#tablecell{align="right", body=[
            "Teammate's login: ",
            #textbox{id=new_person_id},
            #br{},
            "Initial password: ",
            #textbox{id=new_person_password},
            #br{},
            "Teammate's priviledges: ",
            #dropdown{
                id=new_person_rights,
                options=[
                    #option{text="guest", value="guest"},
                    #option{text="tester", value="tester"},
                    #option{text="developer", value="dev"},
                    #option{text="manager", value="pm"},
                    #option{text="superuser", value="su"}
                ]
            },
            #br{},
            #button{text="Add", postback=add_new_person}
        ]}},
        #br{},
        #panel{body="You can reuse this form to reset the password.", style="font-size:9pt; width:45em;"}
    ]}.

change_password_panel() ->
    #panel{style="padding:11px;", body=[
        #span{text="Password change:", style="font-size:16pt;"},
        #br{},
        #br{},
        #singlerow{cells=#tablecell{align="right", body=[
            "New password: ",
            #password{id=new_password},
            #br{},
            "Once more, please: ",
            #password{id=new_password2},
            #br{},
            #button{text="Change", postback=change_password}
        ]}}
    ]}.

author_panel() ->
    AI = salode:load("data/" ++ wf:state(project) ++ "/people/" ++ wf:user() ++ "/info", ""),
    #panel{style="padding:11px;", body=[
        #span{text="About:", style="font-size:16pt;"},
        #br{},
        #br{},
        #singlerow{cells=#tablecell{align="right", body=[
            #textarea{id=author_info, style="width:365px; height:84px;", text=AI},
            #br{},
            #button{text="Write", postback=set_author_info}
        ]}},
        #br{},
        #panel{body="This text adds automatically to any task. You can put your system details here.", style="font-size:9pt; width:45em;"}
    ]}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

event(add_new_person) ->
    UId = wf:q(new_person_id),
    Password = wf:q(new_person_password),
    Rights = wf:q(new_person_rights),
    Project = wf:state(project),
    case UId of
        undefined -> wf:wire(#alert{text="You should have at least some name"});
        "" -> wf:wire(#alert{text="You should have at least some name"});
        _ -> 
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/password", Password),
            set_rights_preset(Project, UId, Rights)
    end,
    wf:update(rights_panel, rights_panel());

event(set_author_info) ->
    AI = wf:q(author_info),
    salode:save("data/" ++ wf:state(project) ++ "/people/" ++ wf:user() ++ "/info", AI);

event(change_password) ->
    P1 = wf:q(new_password),
    P2 = wf:q(new_password2),
    case P1 == P2 of 
        true ->
            salode:save("data/" ++ wf:state(project) ++ "/people/" ++ wf:user() ++ "/password", P1),
            wf:wire(#alert{text="Password changed."});
        _ ->
            wf:wire(#alert{text="New password differs from its own copy!"})
    end,
    wf:set(new_password, ""),
    wf:set(new_password2, "");

event({change_rights, Right, UId}) ->
    NewRight = wf:q(UId++"_"++Right),
    salode:save("data/" ++ wf:state(project) ++ "/people/" ++ UId ++ "/" ++ Right, NewRight).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

set_rights_preset(Project, UId, Preset) ->
    case Preset of
        "guest" ->
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_take", "none"),   % free, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_comment", "any"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_repaint", "none"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_delete", "none"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/subtask_hide", "none"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_create", "none"),   % any, sub, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/people", "none");  % add, change, none
        "tester" ->
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_take", "none"),   % free, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_comment", "own"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_repaint", "own"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_delete", "none"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/subtask_hide", "none"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_create", "sub"),   % any, sub, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/people", "none");  % add, change, none
        "dev" ->
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_take", "free"),   % free, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_comment", "any"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_repaint", "own"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_delete", "none"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/subtask_hide", "own"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_create", "sub"),   % any, sub, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/people", "none");  % add, change, none
        "pm" ->
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_take", "any"),   % free, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_comment", "any"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_repaint", "any"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_delete", "own"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/subtask_hide", "any"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_create", "any"),   % any, sub, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/people", "add");  % add, change, none
        "su" ->
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_take", "any"),   % free, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_comment", "any"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_repaint", "any"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_delete", "any"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/subtask_hide", "any"),   % own, any, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/task_create", "any"),   % any, sub, none
            salode:save("data/" ++ Project ++ "/people/" ++ UId ++ "/people", "add")  % add, change, none
    end.

