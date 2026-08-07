# Offline Survivor

Mod ID beta: `OfflineSurvivorBeta`

Quando um jogador desconecta, um corpo humano permanece no local usando a
aparencia do personagem. Os demais jogadores podem usar a acao **Revistar**
para acessar os itens permitidos pelo servidor.

## Recursos

- aparencia, roupas e itens equipados reproduzidos pelo modelo nativo;
- posicionamento no chao, cama ou sofa proximo;
- painel de revista com limite de itens e tempo de espera;
- configuracoes Sandbox aplicadas pelo servidor;
- suporte a servidor dedicado e multiplayer.

## Uso

Ative somente este mod para usar a variante padrao. Nao ative junto com
`OfflineSurvivorSilentDeathBeta`, pois as duas variantes controlam o mesmo
evento de desconexao. Copie a pasta `42.0` completa para o servidor e use o
Mod ID beta acima. Substitua tambem o `mod.info` da raiz, nao apenas os Lua;
uma instalacao antiga sem as opcoes atuais faz o servidor desativar recursos
novos, como morte por zumbis, no proximo reinicio.

Depois de atualizar arquivos Lua, reinicie o servidor e os clientes.
