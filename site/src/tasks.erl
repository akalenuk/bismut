%% -*- mode: nitrogen -*-

%   Copyright Oleksandr Kalenuk (akalenuk@gmail.com)
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

-module(tasks).
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
                    case wf:user() of
                        undefined -> wf:redirect("/login?of="++Project);
                        UId -> 
                            wf:state(can_take, salode:load("data/" ++ Project ++ "/people/" ++ UId ++ "/task_take", "none")),   % free, any, none
                            wf:state(can_comment, salode:load("data/" ++ Project ++ "/people/" ++ UId ++ "/task_comment", "none")),   % own, any, none
                            wf:state(can_repaint, salode:load("data/" ++ Project ++ "/people/" ++ UId ++ "/task_repaint", "none")),   % own, any, none
                            wf:state(can_delete, salode:load("data/" ++ Project ++ "/people/" ++ UId ++ "/task_delete", "none")),   % own, any, none

                            wf:state(can_hide, salode:load("data/" ++ Project ++ "/people/" ++ UId ++ "/subtask_hide", "none")),   % own, any, none
                            wf:state(can_create, salode:load("data/" ++ Project ++ "/people/" ++ UId ++ "/task_create", "none")),   % any, sub, none

                            wf:state(project, Project),
                            wf:state(user, wf:user()),	% somehow session timeout setup doesn't work, this is a hack

                            #template { file="./site/templates/bare.html" }
                    end;
                _ ->
                     wf:redirect("/login?of="++Project)
            end
    end.

title() -> "Task book".

body() ->
    Name = salode:load("data/"++wf:state(project)++"/name", "error"),
    [
        #panel{style="background-color:#eee; padding:11px;", body=[
            #link{body="<font face='sans-serif' size='5'>"++Name++":</font>", style="color:#000;", url="/"},
            tab(),
            "Tasks",
            tab(),
            #link{text="Settings", url="/settings?of="++wf:state(project)},
            tab(),
            case wf:state(user) of
                undefined -> #link{text="Login", url="/login?of="++wf:state(project)};
                _ -> ["You ", #link{text="logged in", url="/login?of="++wf:state(project)} ," as: <b>" ++ wf:state(user) ++ "</b>."]
            end
        ]},
        #br{},
        #panel{style="margin:5px;", body=
            #panel{id=wf:state(project) ++ "_children", body = [task_panel(Key) || Key <- lists:usort( salode:ls("data/" ++ wf:state(project) ++ "/tasks") )]}
        },
        #br{},
        #panel{id=wf:state(project) ++ "_new_task_panel", body = []}, 
        case (wf:state(can_create) == "any") of
            true ->
                ["<center>",
                #button{id=wf:state(project) ++ "_new_task_panel_button", text="Add a major task", postback={open_task_panel, "data/" ++ wf:state(project)}},
                "</center>"];
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

task_panel(Key) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    wf:state("open_" ++ TS, "false"),
    {Before, After, Color, Expand, Taken, Deleted} = load_task_head(Key),
    case Deleted of 
        true -> "";
        false ->
            #panel{id = TS ++ "_panel", class = "task task_" ++ Color, body = [
                    #link{class="inner_title", body = "<nobr>" ++ Before ++ " &rarr; " ++ After ++ "</nobr>", postback={change_open, Key}},
                    "<!-- task_id: "++ TS ++" -->",
                    case Taken of
                        "" -> [];
                        _ -> #span{style="font-size:10pt;", body=" (взял <b>" ++ Taken ++ "</b>)"}
                    end,
                    #panel{id = TS ++ "_details", body = []},
                    #panel{id = TS ++ "_children", body = case Expand of
                            true -> [task_panel(CKey) || CKey <- lists:usort( salode:ls(Key ++ "/tasks") )];
                            _ -> []
                        end
                    }
                ]
            }
    end.

task_open_panel(Key) -> 
    {Info, Expand, Taken, Author} = load_task_details(Key),
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    SubTaskCount = length([1 || SKey <- salode:ls(Key ++ "/tasks"), salode:load(SKey ++ "/deleted", false) /= true]),
    [
        #panel{style = "width:48em; font-size:11pt;", body=[
                "<pre width=80>",Info,"</pre>"
            ]
        },
        #panel{id=TS ++ "_comments_panel", style="max-width:48em; font-size:10pt; padding-left:2em;", body=[comments_list(Key)]},
        #panel{id=TS ++ "_new_comment_panel", body=[]},
        #br{},

        case (wf:state(can_take) == "any") or (wf:state(can_take) == "free") of
            true ->
                [case Taken of 
                    "" -> #button{text="Take", postback={take_task, Key, wf:state(user)}};
                    _ -> case wf:state(user) == Taken of
                            true -> #button{text="Give away", postback={take_task, Key, ""}};
                            _ -> case (wf:state(can_take) == "any") of
                                    true -> #button{text="Take", postback={take_task, Key, ""}};
                                    _ -> []
                                end
                        end
                end,
                "&nbsp;&nbsp;"];
            _ -> []
        end,

        case (wf:state(can_comment) == "any") or ((wf:state(can_comment) == "own") and (Author == wf:state(user))) of
            true ->
                [#button{text="Comment", postback={open_comment, Key}},
                "&nbsp;&nbsp;"];
            _ -> []
        end,

        case (wf:state(can_repaint) == "any") or ((wf:state(can_repaint) == "own") and (Author == wf:state(user))) of
            true ->
                [#dropdown { id=TS ++ "_task_repaint_color", options=[
                    #option { text="White", value=white },
                    #option { text="Green", value=green },
                    #option { text="Yellow", value=yellow },
                    #option { text="Red", value=red },
                    #option { text="Blue", value=blue }
                ]},
                #button{text="repaint", postback={repaint_task, Key}},
                "&nbsp;&nbsp;"];
            _ -> []
        end,

        case (wf:state(can_delete) == "any") or ((wf:state(can_delete) == "own") and (Author == wf:state(user))) of
            true ->
                #button{text="Remove", postback={delete_task, Key}};
            _ -> []
        end,

        tab(),

        case (wf:state(can_hide) == "any") or ((wf:state(can_hide) == "own") and (Author == wf:state(user))) of
            true ->
                [case SubTaskCount of
                    0 -> [];
                    _ ->
                        case Expand of
                            true -> #button{text="Hide subtasks ("++ integer_to_list(SubTaskCount) ++ ")", postback={change_expand, Key, false}};
                            _ -> #button{text="Show subtasks (" ++ integer_to_list(SubTaskCount) ++ ")", postback={change_expand, Key, true}}
                        end
                end,
                "&nbsp;&nbsp;"];
            _ -> []
        end,

        case (wf:state(can_create) == "any") or (wf:state(can_create) == "sub") of
            true ->
                #button{id=TS ++ "_new_task_panel_button", text="Add a subtask", postback={open_task_panel, Key}};
            _ -> []
        end,

        #br{},
        #panel{id=TS ++ "_new_task_panel", body = []}
    ].

comments_list(Key) ->
    [   
        begin
            {Author, Time, Comment} = salode:load(CKey, ""),
            #panel{style="margin-top:4px; margin-bottom-4px; color:#646464;", body=[
                    "<b>",Author,"</b> ", 
                    utils:time_to_word(Time), " ",
                    Comment
                ]
            }
        end
    || CKey <- lists:usort( salode:ls(Key ++ "/comments") )].


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

event({take_task, Key, To}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    change_taken(Key, To),
    case To of
        "" -> salode:save(Key ++ "/comments/" ++ utils:date_to_list(now()), {wf:state(user), now(), "<i>Gave away the task</i>"});
        _ -> salode:save(Key ++ "/comments/" ++ utils:date_to_list(now()), {wf:state(user), now(), "<i>Took the task</i>"})
    end,
    %[event({take_task, CKey, To}) || CKey <- lists:usort( salode:ls(Key ++ "/tasks") )],
    wf:replace(TS ++ "_panel", task_panel(Key));

event({change_expand, Key, To}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    change_expand(Key, To),
    wf:replace(TS ++ "_panel", task_panel(Key));

event({delete_task, Key}) ->
    wf:wire(#confirm{text="Do you really want to remove the task completely?", postback={do_delete_task, Key}});

event({do_delete_task, Key}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    mark_deleted(Key),
    wf:replace(TS ++ "_panel", []);

event({repaint_task, Key}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    Color = wf:q(TS ++ "_task_repaint_color"),
    change_color(Key, Color),
    salode:save(Key ++ "/comments/" ++ utils:date_to_list(now()), {wf:state(user), now(), "<i>Repainted " ++ utils:color_to_word(Color) ++ ".</i>"}),
    wf:replace(TS ++ "_panel", task_panel(Key));

event({open_task_panel, Key}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    wf:wire(TS ++ "_new_task_panel_button", #hide{}),
    wf:update(TS ++ "_new_task_panel", [
        #br{},
        #br{},
        #table{rows=[
            #tablerow{cells=[
                #tablecell{class="table_label", body="Before: "},
                #tablecell{body=
                    #textbox{id=TS ++ "_task_before_text", style="width:35em;"}
                }
            ]},
            #tablerow{cells=[
                #tablecell{class="table_label", body="After: "},
                #tablecell{body=
                    #textbox{id=TS ++ "_task_after_text", style="width:35em;"}
                }
            ]},
            #tablerow{cells=[
                #tablecell{class="table_label", body="Details: "},
                #tablecell{body=
                    #textarea{id=TS ++ "_task_info_text", style="width:35em; height:5em;"}
                }
            ]},
            #tablerow{cells=[
                #tablecell{class="table_label", body="Color: "},
                #tablecell{body=
                    #dropdown { id=TS ++ "_task_color", options=[
                        #option { text="White", value=white },
                        #option { text="Green", value=green },
                        #option { text="Yellow", value=yellow },
                        #option { text="Red", value=red },
                        #option { text="Blue", value=blue }
                    ]}
                }
            ]},
            #tablerow{cells=[
                #tablecell{body=[]},
                #tablecell{body=[
                    #button{text="Add", postback={add_task, Key}},
                    #button{text="Don't add", postback={hide_add_task, Key}}
                ]}
            ]}
        ]},
        #br{},
        #br{}
    ]);

event({hide_add_task, Key}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    wf:wire(TS ++ "_new_task_panel_button", #show{}),
    wf:update(TS ++ "_new_task_panel", []);

event({add_task, Key}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    event({hide_add_task, Key}),
    Before = wf:q(TS ++ "_task_before_text"),
    After = wf:q(TS ++ "_task_after_text"),
    Info = wf:q(TS ++ "_task_info_text"),
    Color = wf:q(TS ++ "_task_color"),
    save_task(Key, Before, After, Info, Color),
    case TS == wf:state(project) of
        true -> []; % major task don't need the sub- button update
        false -> wf:update(TS ++ "_details", task_open_panel(Key)) % sub- button update
    end,
    wf:update(TS ++ "_children", [task_panel(LKey) || LKey <- lists:usort( salode:ls(Key ++ "/tasks") )]);

event({open_comment, Key}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    wf:update(TS ++ "_new_comment_panel", [
        #singlerow{cells=#tablecell{align="right", body=[
            #textarea{id=TS ++ "_comment_text", style="width:35em; height:5em;"},
            #br{},
            #button{text="Add", style="", postback={add_comment, Key}},
            #button{text="Don't add", style="", postback={close_comment, Key}},
            #br{},
            #br{}
        ]}}
    ]),
    wf:wire("$('.wfid_"++TS++"_comment_text').focus();");

event({close_comment, Key}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    wf:update(TS ++ "_new_comment_panel", []);

event({add_comment, Key}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    Text = wf:q(TS ++ "_comment_text"),
    salode:save(Key ++ "/comments/" ++ utils:date_to_list(now()), {wf:state(user), now(), "<i>Commented:</i><pre width=80>" ++ Text ++ "</pre>"}),
    wf:update(TS ++ "_new_comment_panel", []),
    wf:update(TS ++ "_comments_panel", comments_list(Key));

event({change_open, Key}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    event(case wf:state("open_" ++ TS) of
        "true" -> {hide, Key};
        _ -> {expand, Key}
    end);

event({expand, Key}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    wf:state("open_" ++ TS, "true"),
    wf:update(TS ++ "_details", task_open_panel(Key));

event({hide, Key}) ->
    TS = hd(lists:reverse(ling:split(Key, "/"))),
    wf:state("open_" ++ TS, "false"),
    wf:update(TS ++ "_details", []).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

save_task(Path, Before, After, Info, Color) ->
    RP = Path ++ "/tasks/" ++ utils:date_to_list(now()) ++ "/",
    salode:save(RP ++ "before", Before),
    salode:save(RP ++ "after", After),
    salode:save(RP ++ "info", Info),
    salode:save(RP ++ "color", Color),
    salode:save(RP ++ "author", wf:state(user)),
    salode:save(RP ++ "comments/" ++ utils:date_to_list(now()), {wf:state(user), now(), "<i>Repainted " ++ utils:color_to_word(Color) ++ ". </i>" ++
        case salode:load("data/" ++ wf:state(project) ++ "/people/" ++ wf:state(user) ++ "/info", "") of
            "" -> "";
            AuthorInfo -> "<i> About:<pre width=80>"++AuthorInfo++"</pre></i>"
        end
    }).

change_color(Path, Color) ->
    RP = Path ++ "/",
    salode:save(RP ++ "color", Color).

change_expand(Path, To) ->
    RP = Path ++ "/",
    salode:save(RP ++ "expand", To).

change_taken(Path, To) ->
    RP = Path ++ "/",
    salode:save(RP ++ "taken", To).

mark_deleted(Path) ->
    RP = Path ++ "/",
    salode:save(RP ++ "deleted", true).

load_task_head(Path) ->
    RP = Path ++ "/",
    Before = salode:load(RP ++ "before", ""),
    After = salode:load(RP ++ "after", ""),
    Color = salode:load(RP ++ "color", gray),
    Expand = salode:load(RP ++ "expand", true),
    Taken = salode:load(RP ++ "taken", ""),
    Deleted = salode:load(RP ++ "deleted", false),
    {Before, After, Color, Expand, Taken, Deleted}.

load_task_details(Path) ->
    RP = Path ++ "/",
    Info = salode:load(RP ++ "info", ""),
    Expand = salode:load(RP ++ "expand", true),
    Taken = salode:load(RP ++ "taken", ""),
    Author = salode:load(RP ++ "author", ""),
    {Info, Expand, Taken, Author}.
