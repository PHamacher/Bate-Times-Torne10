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
using PlutoUI

include("utils.jl")

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


