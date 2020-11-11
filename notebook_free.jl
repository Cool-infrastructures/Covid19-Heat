### A Pluto.jl notebook ###
# v0.12.6

using Markdown
using InteractiveUtils

# ╔═╡ b107cb1e-1c54-11eb-22ef-41d2bebdb1c9
begin
	import Dates
	import CSV
	import XLSX
	using DataFrames
	import Plots
	using StatsPlots
end

# ╔═╡ c5fc428a-1c55-11eb-357f-19111a1c3338
	absolute_path = joinpath(pwd(), "data", "Cool Infrastructures Pakistan Raw Data Wave 1.csv")    

# ╔═╡ adc5a67e-245b-11eb-2600-05e4ca4fa4bb
df = DataFrames.DataFrame(CSV.read(absolute_path))

# ╔═╡ b4383a3e-245c-11eb-3b3c-b988004e28b1
names(df)

# ╔═╡ b83c8c88-1c56-11eb-0537-f13eb6b2a3c8
@df df scatter(:AgeGroup, :Gender, markersize = 3)

# ╔═╡ 91721962-1c56-11eb-071c-d5de01efb374
@df df groupedhist(:Rooms, group = :Gender, bar_position = :dodge, bar_width=0.5)

# ╔═╡ dd03fd90-1c5a-11eb-3090-e970f0680194
head(df)

# ╔═╡ 8d6274f6-1ddb-11eb-0ff7-a730441537cb
@df df scatter(:Gender, :WallMaterial)

# ╔═╡ Cell order:
# ╠═b107cb1e-1c54-11eb-22ef-41d2bebdb1c9
# ╠═c5fc428a-1c55-11eb-357f-19111a1c3338
# ╠═adc5a67e-245b-11eb-2600-05e4ca4fa4bb
# ╠═b4383a3e-245c-11eb-3b3c-b988004e28b1
# ╠═b83c8c88-1c56-11eb-0537-f13eb6b2a3c8
# ╠═91721962-1c56-11eb-071c-d5de01efb374
# ╠═dd03fd90-1c5a-11eb-3090-e970f0680194
# ╠═8d6274f6-1ddb-11eb-0ff7-a730441537cb
