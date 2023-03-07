local entities = getEntityList()
for i = 1, #entities do
    local entity = getEntity(entities[i].id)
    if string.find(entity.name, 'item') then
        log(entity.name)
    end
end