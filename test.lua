local luadb = require('./init')
local db = luadb.new('campeonato')
local exists = db:exists('times')

db:FindAndSet('times', 'cruzeiro', {
    nome = 'cruzeiro',
    titulos = 5,
    serie = "A"
})

print("Exists? "..tostring(exists))
print("Titulos do cruzeiro: "..db:FindAndGet('times', 'cruzeiro').titulos)
print("Nome do cruzeiro: "..db:FindAndGet('times', 'cruzeiro').nome)
print("Serie do cruzeiro: "..db:FindAndGet('times', 'cruzeiro').serie)