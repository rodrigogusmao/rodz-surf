RegisterNetEvent('rodz-surf:Buy', function(price)
    local src    = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local cash = Player.PlayerData.money['cash'] or 0
    if cash >= price then
        Player.Functions.RemoveMoney('cash', price, 'aluguel-prancha-surf')
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'Surf', description = 'Dinheiro insuficiente.', type = 'error' })
    end
end)
