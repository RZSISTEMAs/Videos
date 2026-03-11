# Mod de Voo (Noclip Avançado) com Sistema de Sequestro

Este é um script Lua standalone para FiveM que permite ao jogador voar livremente pelo mapa de forma fluida, como um modo espectador (NoClip), mas mantendo o personagem visível e interativo. O grande diferencial deste mod é a habilidade de **agarrar e carregar NPCs ou outros jogadores** pelos ares.

## Funcionalidades Principais
* **Voo Livre e Suave:** Utilizando as setas direcionais, o jogador abandona as físicas de gravidade do GTA e voa perfeitamente na direção da câmera de jogo.
* **Sistema de "Sequestro" (Grab):** Ao apertar `E` próximo de qualquer NPC da cidade, o script usa a nativa `AttachEntityToEntity` para prender o civil no seu personagem. A I.A natural do NPC é paralisada temporariamente enquanto você voa pelo mapa carregando-o. O NPC pode ser solto a qualquer altura e momento.
* **Invencibilidade Automática:** Durante o voo ativo, o recurso previne que você tome dano caso colida com edifícios, tornando seu ped temporariamente invencível através de `SetEntityInvincible`.
* **Rastreador de Coordenadas Embutido:** Acompanha um pequeno utilitário integrado onde o comando `/coord` imprime a sua posição exata e ângulo num formato copo e cola de Lua no chat. Útil param mapear blips e garagens.

## Comandos do Jogo
* `/voar`: Comando principal para Ativar e Desativar o modo de voo.
* `/coord`: Imprime no chat local as suas coordenadas atuais `(vector3(x,y,z))` e `heading` da Câmera.

## Controles de Teclado (Enquanto Voando)
| Tecla | Ação |
| :--- | :--- |
| **`W` / `S`** | Move para Frente e para Trás seguindo a direção da câmera. |
| **`Shift Esquerdo`** | Turbina a velocidade do voo em 4x. |
| **`E`** | Agarra o Pedestre mais próximo (dentro de um raio de 5 metros). Se já estiver segurando alguém, aperta Novamente para **Soltar**. |
| **`Q`** | Interrompe o voo abruptamente (Função de Emergência para Cair/Aterissar no ponto atual). |

## Informações Técnicas para Devs
O script possui um `DrawRect` customizado que injeta HUD provisório na tela para te informar ativamente as teclas durante o uso. Além disso, utiliza chamadas `NetworkRequestControlOfEntity()` antes do anexo pra garantir que os pedestres sequestrados não sumam do cliente, estabilizando e evitando o "culling" desnecessário e o bug do despawn natural de NPCs de fundo.

### Instalação no Servidor
Adicione a pasta `voar` ou o respectivo nome de escolha diretamente no diretório local de seu servidor.
Então certifique-se de adicioná-la em seu arquivo principal de Server (Ex: *server.cfg*):
```
ensure voar
```
