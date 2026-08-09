--[[
    Zim Pie - o menu circular estilo The Sims.

    Primeira expansao do The Zims. A base entrega o desenho (disco, pilula,
    arco, degrade), o tema, a cabeca 3D e a janela do K; aqui mora so o que e
    do menu: a geometria da roda e a re-skin do ISContextMenu.

    ESTE ARQUIVO AINDA E O ESQUELETO. O codigo do menu continua dentro do The
    Zims e sera movido em etapas - ver PLANO-SEPARACAO.md. Enquanto isso, este
    mod so prova que carrega, que acha a base e que consegue registrar a
    propria aba. Ativar os dois ao mesmo tempo agora NAO duplica o menu, porque
    daqui nao sai nenhum envelope de ISContextMenu.

    O `require=\TheZims` no mod.info faz o jogo carregar a base primeiro, mas
    isso vale para a lista de mods, nao para a ordem dos .lua entre mods.
]]

--[[
    O AVISO DE BASE AUSENTE MUDOU DE HORA, E ISSO CONSERTOU UM DEFEITO.

    Este arquivo comecava conferindo `TheZims` e dando `return` com uma
    mensagem no console. O raciocinio escrito aqui dizia que a checagem "existe
    de verdade e nao e paranoia" -- e estava exatamente ao contrario: era ela
    que garantia a falha em vez de evita-la.

    `TheZims` e uma global que so nasce quando o Lua da base roda. Para quem
    tivesse o Zim Pie antes do The Zims na lista de mods, este arquivo
    carregava com ela ainda nil, imprimia "The Zims nao encontrado" e desistia
    -- com o The Zims instalado e marcado, ali do lado. O jogador lia no
    console que faltava um mod que ele tinha.

    Agora a pergunta e feita no OnGameStart, que acontece depois de TODO o Lua
    de TODOS os mods ter carregado. Nesse instante a resposta e confiavel: se
    `TheZims` nao existe ali, ele realmente nao esta instalado.
]]

ZimPie = ZimPie or {}
ZimPie.VERSAO = "1.1"

--- Nome da aba dentro da janela do K. Tem que bater com o campo `aba` da
--- entrada correspondente em TheZims.FAMILIA, senao o botao "Abrir opcoes" da
--- prateleira nao acha para onde ir.
ZimPie.ABA = "Zim Pie"

local function log(txt)
    print("[ZimPie] " .. tostring(txt))
end
ZimPie.log = log

--[[
    Registra a aba na janela da base.

    A assinatura de registrarSecao nao mudou por causa desta separacao - o Zim
    Actions usa a mesma e nao precisou de uma linha de alteracao.

    `construir` recebe (janela, x, y, largura) e devolve o y final. Todo widget
    criado com janela:addChild vai para a aba automaticamente: a base envolve o
    addChild durante esta chamada. Nao ha nada a fazer aqui alem de criar.
]]
local function construirSecao(janela, x, y, largura)
    local rot = ISLabel:new(x, y, 22,
        getText("IGUI_ZimPie_Placeholder") or "Zim Pie",
        0.82, 0.80, 0.76, 1, UIFont.Small, true)
    rot:initialise()
    janela:addChild(rot)
    return y + 26
end

--[[
    NAO registrar secao por enquanto.

    A base ainda constroi a aba "ZimPie" com todos os ajustes do menu (passo 4
    do PLANO-SEPARACAO.md e que move isso para ca). Registrar aqui tambem
    criava DOIS cartoes "Zim Pie" na coluna - um da base, um deste esqueleto.

    Quando os ajustes migrarem, este arquivo volta a registrar e a base para de
    criar o dela. `construirSecao` fica pronta esperando por isso.
]]
local _ = construirSecao

log("carregado - v" .. ZimPie.VERSAO)

--[[
    A checagem que antes matava o arquivo, agora na hora certa.

    OnGameStart roda depois de todo o Lua de todos os mods. Se `TheZims` nao
    existe aqui, a base realmente falta -- e ai o aviso e verdadeiro e util.

    Nao ha `return` nem desligamento: o ZimPie_Patch ja instala os substitutos
    sempre e devolve o menu vanilla sozinho quando `isZimMenu()` responde nao,
    que e o que acontece sem a base. Este print e informacao para quem abrir o
    console, nao um interruptor.
]]
Events.OnGameStart.Add(function()
    if TheZims then return end
    print("[ZimPie] The Zims nao encontrado. O Zim Pie e uma DLC e precisa da " ..
          "base para desenhar: assine The Zims e marque OS DOIS na lista de " ..
          "mods. O menu de contexto continua funcionando normalmente ate la.")
end)
