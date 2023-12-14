### A Pluto.jl notebook ###
# v0.19.35

using Markdown
using InteractiveUtils

include("utils.jl")

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

# ╔═╡ 072d3236-d582-4c59-a895-8849a158461f

function teste(jogadores, ovrs)
	ordem = sortperm(ovrs)
	ordenado = jogadores[ordem]
	return hcat(ordenado[1:8], ordenado[9:16])
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

# ╔═╡ bd8a4c5d-2bd0-4678-9342-fd6e4fb0c158
teste([String(k) for k in keys(ovrs)], [v for v in values(ovrs)])