local entities = getEntityList()
for i = 1, #entities do
    local entity = getEntity(entities[i].id)
    Logger.log(entity.name)
end