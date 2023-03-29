-- local path =  ...
-- local sql_driverManager = luajava.bindClass("java.sql.DriverManager")
-- local sql_connection = sql_driverManager:getConnection("jdbc:sqlite:" .. path);
-- local sql_statement = sql_connection:createStatement();

-- sql_statement:executeUpdate("drop table if exists person");
-- sql_statement:executeUpdate("create table person (id integer, name string)");
-- sql_statement:executeUpdate("insert into person values(1, 'leo')");
-- sql_statement:executeUpdate("insert into person values(2, 'yui')");
-- local rs = sql_statement:executeQuery("select * from person")
-- while rs:next() do
--     local id, name = rs:getInt("id"), rs:getString("name")
--     log({id,name})
-- end
local path =  string.gsub(debug.getinfo(1).source,"\\libs\\db.lua","\\db.sqlite3")
path = string.gsub(path,"@","")

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

db.pop_command = function()
    local result = db.query("select * from commands order by priority asc, created_at asc limit 1")
    if #result > 0 then
        db.update("delete from commands where id = " .. result[1].id)
    end
    return result
end

db.add_event = function(event)
    db.update("insert into events (event, created_at) values ('" .. event .. "', datetime('now'))")
end

return db
