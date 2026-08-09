--[[
    Aviso de "a base esta sozinha".

    POR QUE ISTO EXISTE

    O menu circular saiu do The Zims e virou o Zim Pie. Quem ja era inscrito
    recebe as duas pastas no mesmo download -- os dois mods viajam no mesmo item
    da Workshop -- mas o Zim Pie NAO se ativa sozinho:

      * `require=` no mod.info nao ativa nada. Ele so aparece na aba
        Dependencies da tela de mods. Conferido no jogo inteiro: as unicas duas
        leituras de getRequire() sao para EXIBIR texto.
      * o save guarda uma lista explicita de mods ativos. Um mod baixado que
        nao esta nela simplesmente nao carrega.

    Entao existe um estado real em que o jogador atualiza, entra no jogo, e o
    menu sumiu sem explicacao. Do ponto de vista dele o mod quebrou. Este
    arquivo e o que transforma isso numa instrucao de uma linha.

    Some sozinho quando qualquer DLC estiver ativa, e nao volta.
]]

if isServer() then return end

TheZims = TheZims or {}

local MOSTRADO = false

--[[
    As DLC ESSENCIAIS estao todas ativas?

    Nao e "alguma DLC ativa". Quem tivesse o Zim Actions marcado passava nesse
    teste e nunca era avisado de que o menu sumiu -- justamente o caso de quem
    atualiza vindo da versao antiga, que tinha o menu embutido.

    Devolve tambem a primeira essencial que falta, para o texto do aviso poder
    nomea-la em vez de falar por generalidade.
]]
local function faltaEssencial()
    local ok, faltando = pcall(function()
        local ativos = {}
        local lista = getActivatedMods()
        for i = 0, lista:size() - 1 do ativos[lista:get(i)] = true end

        for _, d in ipairs(TheZims.FAMILIA or {}) do
            if d.essencial and not ativos[d.id] then return d end
        end
        return nil
    end)
    return ok and faltando or nil
end

local function txt(chave, padrao)
    local ok, s = pcall(getText, chave)
    if ok and s and s ~= chave then return s end
    return padrao
end

--[[
    Um modal, e nao um texto no canto.

    O jogador acabou de perder um recurso que usava; um aviso discreto seria
    perdido justamente por quem mais precisa dele. O modal aparece UMA vez por
    sessao e so enquanto o problema existir -- assim que ele marcar o Zim Pie na
    lista, nunca mais aparece.
]]
local function avisar()
    if MOSTRADO then return end
    MOSTRADO = true

    local falta = faltaEssencial()
    if not falta then return end

    --[[
        UMA VEZ, E NUNCA MAIS.

        A primeira versao avisava a cada partida enquanto faltasse a DLC. Isso
        e cobranca, nao aviso: quem decidiu jogar so com a base -- ou nem quer o
        menu circular -- passaria a fechar um modal toda vez que entrasse.

        Aqui a marca fica no .ini do jogador. Ele e informado uma vez de que a
        peca existe e onde encontra-la; dai em diante o assunto morre, e o
        cartao na janela K continua la para quem mudar de ideia.
    ]]
    if TheZims.PREF and TheZims.PREF.avisoDlcVisto then return end
    pcall(function()
        TheZims.PREF.avisoDlcVisto = true
        TheZims.salvarPrefs()
    end)

    print("[TheZims] DLC do menu ausente: " .. tostring(falta.id) ..
          ". Avisando uma vez; nao repete.")

    pcall(function()
        local texto = txt("IGUI_TheZims_SozinhoAviso",
            "O menu circular virou um mod separado: The Zims - Menu Style DLC." ..
            " <LINE> <LINE>Assine-o na Workshop e marque na lista de mods para o" ..
            " menu voltar - suas configuracoes continuam guardadas. <LINE> <LINE>" ..
            "O The Zims sozinho e so a base e nao desenha nada no mundo.")

        local largura, altura = 480, 240
        local modal = ISModalRichText:new(
            getCore():getScreenWidth() / 2 - largura / 2,
            getCore():getScreenHeight() / 2 - altura / 2,
            largura, altura, texto, false)
        modal:initialise()
        modal:addToUIManager()

        --[[
            Fechado o aviso, a JANELA ABRE sozinha na estante.

            Ler que existe uma DLC e diferente de ver o cartao dela com o botao
            "Obter na Steam" na frente. O texto explica; a janela resolve.

            Abre so aqui, no estado quebrado. Abrir para todo mundo pegaria
            tambem quem ja arrumou, e virava estorvo a cada partida - e um
            prazo fixo ("por dois dias") nao serve, porque quem instalar depois
            do prazo nao veria nada, e e justamente quem mais precisa.

            O gancho: o modal fecha por `destroy`, e envolver a funcao DA
            INSTANCIA nao toca na classe nem em nenhum outro dialogo do jogo.
        ]]
        local fecharOriginal = modal.destroy
        modal.destroy = function(m)
            fecharOriginal(m)
            pcall(function()
                if not TheZims.alternarJanela or TheZimsOptions.instancia then return end
                TheZims.alternarJanela()

                --[[
                    Abre JA no cartao que falta, nao no Sobre.

                    O modal acabou de dizer "assine o Menu Style DLC"; cair na
                    pagina de apresentacao obrigaria a pessoa a procurar o
                    cartao certo entre cinco. Aqui ela ja chega na pagina dele,
                    com o aviso de nao instalado e o botao da Steam a vista.

                    Primeira DLC ausente da lista, e nao um id fixo: se um dia
                    o Menu Style for o unico presente e outra faltar, a janela
                    abre na que importa.
                ]]
                local j = TheZimsOptions.instancia
                if not j then return end
                for _, aba in ipairs(j.abas or {}) do
                    if aba.id == falta.id or aba.id == falta.aba then
                        j:mostrarAba(aba.id)
                        return
                    end
                end
            end)
        end
    end)
end

--[[
    OnGameStart e nao OnGameBoot: no boot a lista de mods ativos do save ainda
    nao vale, e o aviso sairia mesmo para quem tem tudo certo.
]]
Events.OnGameStart.Add(avisar)
