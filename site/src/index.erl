%% -*- mode: nitrogen -*-

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

-module(index).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Страница
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

main() -> #template { file="./site/templates/bare.html" }.

title() -> "Висмут".

body() ->
    #container_12 { body=[
        #grid_8 { alpha=true, prefix=2, suffix=2, omega=true, body=inner_body() }
    ]}.

inner_body() -> 
    wf:user(undefined),
    [
        #panel{style="background-color:#eee; padding:11px;", body=[
            "<font face='sans-serif' size='5'>Висмут</font>"
        ]},
        #br{},
        #br{},
        #panel{style="padding:11px;", body="Это колаборативный задачник. Веб-штука для планирования, обсуждения задач и&nbsp;трекинга багов. Вопросы, предложения и&nbsp;жалобы можете направлять по&nbsp;адресу: <a href='mailto:akalenuk@imp.lg.ua'>akalenuk@imp.lg.ua</a>."},
        #br{},
        #br{},
        #span{style="padding:11px; font-size:16pt;", text="Список задачников:"},
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
        #span{style="padding:11px; font-size:16pt;", text="Сделать новый задачник:"},
        #br{},
        #br{},
        #singlerow{style="padding-left:11px;", cells=#tablecell{align="right", body=[
            "Название в URL: ",
            #textbox{id=new_project_url},
            #br{},
            "Человеческое название: ",
            #textbox{id=new_project_name},
            #br{},
            "Описание для главной: ",
            #textbox{id=new_project_description},
            #br{},
            #br{},
            "Логин суперюзера: ",
            #textbox{id=new_project_su_login},
            #br{},
            "Пароль суперюзера: ",
            #textbox{id=new_project_su_password},
            #br{},
            #br{},
            "Код-приглашение: ",
            #textbox{id=new_project_invite},
            #br{},
            #button{text="Добавить", postback=add_new_project}
        ]}},
        #br{},
        #br{},
        #span{style="padding:11px; font-size:16pt;", text="Сорцы: "},
        #br{},
        #br{},
        #link{style="padding:11px;", text="https://github.com/akalenuk/bismut", url="https://github.com/akalenuk/bismut"},
        #panel{style="padding:11px; font-size:11pt;", body="Исходный код отдается по&nbsp;лицензии <a href='http://www.apache.org/licenses/LICENSE-2.0.html'>Apache&nbsp;2.0</a>. Если коротко: делайте с&nbsp;ним, что хотите, а&nbsp;я&nbsp;ни&nbsp;за&nbsp;что не&nbsp;отвечаю."},
        #panel{style="padding:11px; font-size:11pt;", body="Это сайт для <a href='http://nitrogenproject.com/'>&laquo;Нитрогена&raquo;</a>. Для того, чтобы запустить &laquo;Висмут&raquo; локально, надо поставить сам &laquo;Нитроген&raquo;, поместить сорцы в&nbsp;site/ и&nbsp;запустить веб-сервер согласно инструкции."},
        #br{},
        #br{}
    ].


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% События
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

event(add_new_project) ->
    URLId = wf:q(new_project_url),
    Name = wf:q(new_project_name),
    Description = wf:q(new_project_description),

    SULogin = wf:q(new_project_su_login),
    SUPassword = wf:q(new_project_su_password),

    Invite = wf:q(new_project_invite),

    case check_url_id_latin(URLId) of
        not_ok -> wf:wire(#alert{text="В URL можно только латиницу, цифры и дефис. Например, \"manhattan_project_1945\""});
        ok -> 
            case check_url_id_taken(URLId) of
                not_ok -> wf:wire(#alert{text="Такой URL уже занят."});
                ok ->
                    case length(Name) > 16*2 of % это неправильно, тут надо считать уникод
                        true -> wf:wire(#alert{text="Название может быть длинной только в 16 символов и меньше."});
                        _ ->
                            case length(Description) > 44*2 of % и это неправильно, тут надо считать уникод
                                true -> wf:wire(#alert{text="Описание может быть длинной только в 44 символа и меньше."});
                                _ ->
                                    case SULogin of 
                                        "" -> wf:wire(#alert{text="Логин суперюзера не может быть пустым."});
                                        _ ->
                                            case use_invite(Invite) of 
                                                not_ok -> wf:wire(#alert{text="Хм. Наверное, кто-то этот инвайт уже использовал"});
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Данные
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
        "Мне можно и без инвайта." -> ok; % для себя оставил лазейку
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


    


