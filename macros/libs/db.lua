local path = os.getenv("APPDATA") .. "\\.minecraft\\db.sqlite3"

local db = {
    driver = luajava.bindClass("java.sql.DriverManager"),
    path = path
}

db.query = function(sql)
    local sql_connection = db.driver:getConnection("jdbc:sqlite:" .. db.path);
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
    local sql_connection = db.driver:getConnection("jdbc:sqlite:" .. db.path);
    local sql_statement = sql_connection:createStatement();
    sql_statement:executeUpdate(sql)
    sql_connection:close()
end

db.add_event = function(event)
    db.update("insert into events (event, created_at) values ('" .. event .. "', datetime('now'))")
end

db.get_command = function()
    local result = db.query("select * from commands order by priority asc, created_at asc limit 1")
    return result
end

db.delete_command = function(id)
    db.update("delete from commands where id = " .. id)
end

return db
