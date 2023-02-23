local table_ = {}

table_.find = function(table, value)
    for k, v in pairs(table) do
        if type(v) == 'table' and type(value) == 'table' then
            if Calc.compareArray(v, value) then
                return k
            end
        elseif v == value then
            return k
        end
    end
    return nil
end

return table_