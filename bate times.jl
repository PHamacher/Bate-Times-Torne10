### A Pluto.jl notebook ###
# v0.19.35

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 489f24d9-91a3-4053-8f4e-c168c83ebe1e
using PlutoUI, JuMP, GLPK

# ╔═╡ 072d3236-d582-4c59-a895-8849a158461f
begin
function soma_ovrs(dic_jog_ovr::Dict{String,Float64},todos::NamedTuple)
    ovrs = []
    soma = 0
    for t in todos
        pos = []
        for el in t
            push!(pos,dic_jog_ovr[el])
        end
        push!(ovrs,pos)
        soma += sum(pos)
    end
    return soma, ovrs
end
function build_klis(todos::NamedTuple)
    Klis = []
    for pos in keys(todos)
        push!(Klis,collect(1:length(todos[pos])))
    end
    return Klis
end
function modelagem(todos::NamedTuple, Klis::Array, P::Array{Int64,1}, n_pos::Array{Int64,1}, ovrs::Array{Any,1}, media::Float64, junta::Array, separa::Array, minutos_max::Float64)
    # modelo = Model(optimizer_with_attributes(GLPK.Optimizer,"tm_lim" => 60000*minutos_max))
    modelo = Model(GLPK.Optimizer)
    x = @variable(modelo, [i=1:length(todos),Klis[i],P], binary=true)

    @variable(modelo, s[P] >= 0) # Força do time
    @variable(modelo, z[P] >= 0) # Abs(desvio do time)
    @variable(modelo, α)

    #@objective(modelo, Min, sum(z[j] for j in P))
    @objective(modelo, Min, α)

    for n in 1:length(todos)
        @constraint(modelo, [j in P], sum(x[n,i,j] for i in Klis[n]) == length(Klis[n])/length(P)) # número de (posição) em cada time
        @constraint(modelo, [i in Klis[n]], sum(x[n,i,j] for j in P) == 1) # número de times de cada (posição)
    end

    @constraint(modelo, [j in P], s[j] ==  sum(sum(ovrs[k][i]*x[k,i,j] for i in Klis[k]) for k in n_pos))#sum(ovr_g[i]*g[i,j] for i in Kg) + sum(ovr_d[i]*d[i,j] for i in Kd) + sum(ovr_m[i]*m[i,j] for i in Km) + sum(ovr_a[i]*a[i,j] for i in Ka)) # força da equipe
    @constraint(modelo, [j in P], media - s[j] <= z[j])
    @constraint(modelo, [j in P], s[j] - media <= z[j])

    @constraint(modelo, [j in P], z[j] <= α)

    if junta[1] != []
    for el in junta
        juntos(el[1],el[2],todos,P,modelo,x)
    end
    end
    if separa[1] != []
    for el in separa
        separados(el[1],el[2],todos,P,modelo,x)
    end
    end

    @time(optimize!(modelo))
    return modelo, JuMP.value.(s), JuMP.value.(x)
end
function monta_times(todos::NamedTuple, Klis::Array, P::Array{Int64,1}, n_pos::Array{Int64,1}, x::JuMP.Containers.SparseAxisArray)
    tam = 0
    for pos in todos
        tam += length(pos)
    end    
    times = Array{String}(undef, Int(tam/length(P)),0)
    for p in P
        a = Array{String}(undef, Int(tam/length(P)),1)
        loc = 1
        for n in n_pos
            v=[]
            for k in Klis[n]
                push!(v,x[n,k,p])
            end
            ps = todos[n][convert(BitArray,v)]
            a[loc:loc+length(ps)-1,1] = ps
            loc += length(ps)
        end
        times = hcat(times,a)
    end
    return times
end
function modela(dic_jog_ovr::Dict{String,Float64},todos::NamedTuple,n_times::Int64;separa=[[]],junta=[[]],minutos_max=1/12)
    soma, ovrs = soma_ovrs(dic_jog_ovr,todos)
    Klis = build_klis(todos)
    P, media, n_pos = collect(1:n_times), soma/n_times, collect(1:length(todos))
    modelo, forças, x = modelagem(todos, Klis, P, n_pos, ovrs, media, junta, separa, minutos_max)
    times = monta_times(todos, Klis, P, n_pos, x)
   return times, forças
end
function separados(j1::String, j2::String, todos::NamedTuple, P::Array{Int64,1}, modelo::Model, x::JuMP.Containers.SparseAxisArray)
    x1, x2 = 0,0
    for i in 1:length(todos)
        if j1 in todos[i]
            x1 = i
        end
        if j2 in todos[i]
            x2 = i
        end
    end
    @constraint(modelo, [j in P], x[x1,findall(x->x==j1, todos[x1])[1],j] +  x[x2,findall(x->x==j2, todos[x2])[1],j] <= 1) # Xodó e Coelho separados
    return
end
function juntos(j1::String, j2::String, todos::NamedTuple, P::Array{Int64,1}, modelo::Model, x::JuMP.Containers.SparseAxisArray)
    x1, x2 = 0,0
    for i in 1:length(todos)
        if j1 in todos[i]
            x1 = i
        end
        if j2 in todos[i]
            x2 = i
        end
    end
    @constraint(modelo, [j in P], x[x1,findall(x->x==j1, todos[x1])[1],j] == x[x2,findall(x->x==j2, todos[x2])[1],j])
    return
end

end

# ╔═╡ 0116805a-7570-422c-a8ab-53e5f2495f8f
jogadores = ["Murilo", "Almeida", "Felipe", "Coelho", "Vinisk", "Hama", "Bob", "Tuca", "Cingo", "Elabras", "Lucca", "Miguel", "Sommer", "Mello", "Joe M", "Joebo"]

# ╔═╡ 351a66fa-4b63-4400-ac87-f16e7a5ba7d1
function set_ovrs(jogs::Vector)
	
	return PlutoUI.combine() do Child
		
		inputs = [
			md""" $(jog): $(
				Child(jog, NumberField(0:100, default=50))
			)"""
			
			for jog in jogs
		]
		
		md"""
		#### Escolha o nível dos jogadores na sua opinião
		$(inputs)
		"""
	end
end

# ╔═╡ 3c87fb68-0509-4b7e-9b4a-5eb4a6e14bca
@bind ovrs set_ovrs(jogadores)

# ╔═╡ 226965ca-3aac-4e68-a721-2f248bf8ea23
dict_torneio = Dict([String(keys(ovrs)[i]) => Float64(values(ovrs)[i]) for i in 1:16])

# ╔═╡ 194912d9-d821-4577-9c0a-e2763425c752
todos = (t = [String(k) for k in keys(ovrs)],)

# ╔═╡ dd670401-82e6-43e5-a89d-1f5917309152
times,forças=modela(dict_torneio, todos, 4)

# ╔═╡ 58b35263-d61e-418b-b3b7-2e22605c715b
md"""
## Os seguintes times foram selecionados:
### Time 1
$(times[:,1])
### Time 2
$(times[:,2])
### Time 3
$(times[:,3])
### Time 4
$(times[:,4])
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
GLPK = "60bf3e95-4087-53dc-ae20-288a0d20c6a6"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
GLPK = "~1.1.3"
JuMP = "~1.17.0"
PlutoUI = "~0.7.54"
"""

