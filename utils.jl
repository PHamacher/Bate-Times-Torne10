using Pkg
Pkg.add("JuMP")
Pkg.add("GLPK")
using JuMP, GLPK

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

