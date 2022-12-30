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

-module(login).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").

main() -> 
    case wf:q("of") of
        undefined -> wf:redirect("/");
        Project ->
            wf:state(project, Project),
            #template { file="./site/templates/bare.html" }
    end.

title() -> "Bismut log in".

body() -> 
    Name = salode:load("data/"++wf:state(project)++"/name", "error"),
    [
        #table{style="height:100%; width:100%; ", rows=[
            #tablerow{cells=[#tablecell{colspan=3, body=" "}]},
            #tablerow{cells=[
                #tablecell{body=" "},
                #tablecell{align=center, body=[
                    #singlerow{cells=#tablecell{body=
                        #panel{style="text-align:right; border:1px solid #ccc; padding:11px; border-radius:3px;", body=[
                            #panel{style="width:100%; background-color:#eee; padding:11px; margin-left:-11px; margin-top:-11px; text-align:left;", body=[
                                "<font face='sans-serif' size='5'>"++Name++":</font>"
                            ]},
                            #br{},
                            #span{text="Login: "},
                            #textbox{id=login, postback=login},
                            #br{},
                            #span{text="Password: "},
                            #password{id=password, postback=login},
                            #br{},
                            #br{},
                            case wf:user() of
                                undefined -> #button{id=login_button, text="Log in", postback=login};
                                _ -> [
                                        #button{id=login_button, text="Re-log in", postback=login},
                                        #button{id=login_button, text="Log out", postback=logoff}
                                    ]
                            end
                        ]}
                    }}
                ]},
                #tablecell{body=" "}
            ]},
            #tablerow{cells=[#tablecell{colspan=3, body=" "}]}
        ]}
    ].

event(login) ->
    Login = wf:q(login),
    Password = wf:q(password),
    case Login of
        "" -> wf:wire(#alert{text="You should have at least some kind of login."});
        _ -> 
            RealPassword = salode:load("data/" ++ wf:state(project) ++ "/people/" ++ Login ++ "/password", no_password),
            case RealPassword of
                Password -> 
                    wf:user(Login),
                    wf:config_default(session_timeout, 1440),
                    wf:session(project, wf:q("of")),
                    wf:redirect("/tasks?of=" ++ wf:state(project));
                no_password -> wf:wire(#alert{text="Wrong login."});
                _ -> wf:wire(#alert{text="Wrong password."})
            end
    end;

event(logoff) ->
    wf:user(undefined),
    wf:redirect("/tasks").
