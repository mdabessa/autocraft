local database = os.getenv('PG_DATABASE')
local user = os.getenv('PG_USER')
local password = os.getenv('PG_PASSWORD')

if not database or not user or not password then
    Logger.log("Database not configured!")
    return nil
end

local db = {
    DriverManager = luajava.bindClass("java.sql.DriverManager"),
    url = "jdbc:postgresql://localhost:5432/" .. database .. "?user=" .. user .. "&password=" .. password,
    conn = nil
}

db.query = function(sql)
    local sql_connection = db.DriverManager:getConnection(db.url);
    local sql_statement = sql_connection:createStatement();
    local rs = sql_statement:executeQuery(sql)
    local result = {}
    while rs:next() do
        local row = {}
        for i = 1, rs:getMetaData():getColumnCount() do
            local name = rs:getMetaData():getColumnName(i)
            row[name] = rs:getString(name)
        end
        table.insert(result, row)
    end

    sql_connection:close()
    return result
end

db.update = function(sql)
    local sql_connection = db.DriverManager:getConnection(db.url);
    local sql_statement = sql_connection:createStatement();
    sql_statement:executeUpdate(sql)
    sql_connection:close()
end

db.add_event = function(event, type)
    type = type or 'minecraft'
    db.update("insert into events (event, created_at, type) values ('" .. event .. "', now(), '" .. type .. "')")
end

db.get_command = function()
    local result = db.query("select * from commands order by priority asc, created_at asc limit 1")
    return result
end

db.delete_command = function(id)
    db.update("delete from commands where id = " .. id)
end

return db
