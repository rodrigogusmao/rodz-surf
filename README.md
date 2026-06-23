# rodz-surf

Sistema de aluguel de prancha de surf para FiveM, desenvolvido para o framework **Qbox** com suporte a `ox_lib`, `ox_target` e `mri_Qcarkeys`.

---

## Funcionalidades

- NPC fixo na praia para interação via `ox_target`
- Aluguel de prancha por valor configurável (cash)
- Spawna a prancha (veículo `surfboard`) diretamente na água
- Chaves temporárias via `mri_Qcarkeys` — a prancha fica bloqueada para outros jogadores
- Devolução da prancha na zona de spawn ao pressionar **E**
- Marker visual (cilindro azul) indicando o ponto de devolução
- Blip no mapa marcando a área de surf
- Validação server-side do saldo antes de debitar

---

## Dependências

| Resource | Obrigatório |
|---|---|
| `ox_lib` | ✅ |
| `ox_target` | ✅ |
| `qbx_core` | ✅ |
| `mri_Qcarkeys` | ✅ |

> O modelo de veículo `surfboard` precisa estar disponível no servidor (addon ou stream).

---

## Instalação

1. Copie a pasta `rodz-surf` para o diretório de resources do servidor.
2. Certifique-se de que todas as dependências acima estão rodando.
3. Adicione ao `server.cfg`:

```
ensure rodz-surf
```

4. Ajuste as coordenadas e o preço no `config.lua` conforme sua necessidade.

---

## Configuração

```lua
-- config.lua

Config.NPC = {
    coords = vector4(-1468.94, -1389.12, 1.57, 107.60),
    model  = 'a_m_y_beach_01',
}

Config.SpawnCoords = vector4(-1509.60, -1409.07, 0.55, 117.22)

Config.RentalPrice = 250
```

| Campo | Tipo | Descrição |
|---|---|---|
| `Config.NPC.coords` | `vector4` | Posição e heading do NPC de aluguel |
| `Config.NPC.model` | `string` | Model do NPC (qualquer ped do GTA V) |
| `Config.SpawnCoords` | `vector4` | Onde a prancha spawna na água |
| `Config.RentalPrice` | `number` | Valor em cash cobrado pelo aluguel |

As coordenadas padrão apontam para a **Praia de Vespucci** (sul de LS), com a prancha spawnando no mar.

---

## Como funciona

### Para o jogador

1. Encontra o NPC na praia (marcado no mapa como **Surf Area**).
2. Usa o `ox_target` para interagir → opção **"Alugar Prancha - $250"**.
3. O valor é descontado do cash. A prancha aparece na água no ponto configurado.
4. Entra na prancha — as chaves temporárias são concedidas automaticamente.
5. Para devolver, pilota a prancha de volta ao ponto de spawn (marker azul na água) e pressiona **E**.

### Fluxo técnico

```
[Client] ox_target onSelect
    → RentSurfboard()
        → CreateVehicle('surfboard', SpawnCoords)
        → SetVehicleNumberPlateText('SURFxxxx')
        → Entity.state 'keysIn' = true
        → mri_Qcarkeys:GiveTempKeys(plate)
        → TriggerServerEvent('rodz-surf:Buy', price)

[Server] rodz-surf:Buy
    → qbx_core:GetPlayer(src)
    → verifica cash >= price
    → Player.Functions.RemoveMoney('cash', price)

[Client] Thread de devolução
    → detecta veículo 'surfboard' sob o jogador
    → dist < 3.0 do SpawnCoords + tecla E (control 38)
    → TaskLeaveVehicle → DeleteVehicle
    → mri_Qcarkeys:RemoveTempKeys(plate)
```

---

## Estrutura de arquivos

```
rodz-surf/
├── fxmanifest.lua
├── config.lua
├── client/
│   └── main.lua    # NPC, aluguel, devolução, marker, blip
└── server/
    └── main.lua    # Validação e débito do cash
```

---

## Customização

**Trocar o NPC:** altere `Config.NPC.model` para qualquer hash de ped válido do GTA V.

**Mudar a localização:** ajuste `Config.NPC.coords` (NPC) e `Config.SpawnCoords` (prancha na água). O `w` do `vector4` é o heading (0–360°).

**Preço dinâmico:** `Config.RentalPrice` aceita qualquer valor inteiro positivo.

**Blip:** o sprite `409` corresponde ao ícone de surf/praia. A cor `0` é branco. Para alterar, edite as chamadas `SetBlipSprite` / `SetBlipColour` em `client/main.lua`.

---

## Limitações conhecidas

- Um jogador só pode ter **uma prancha por vez** (controlado pela flag `hasSurfboard` local).
- Caso o jogador desconecte com a prancha na água, ela permanece até o servidor reiniciar o resource.
- O débito acontece no client-event; não há callback de confirmação de criação do veículo antes do débito.

---

## Licença

Uso interno — É Os Cria RP.
