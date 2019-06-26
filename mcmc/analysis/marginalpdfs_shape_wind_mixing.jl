using
    PyPlot, PyCall, Printf,
    Dao, JLD2, Statistics,
    OceanTurb, OffsetArrays, LinearAlgebra

@use_pyplot_utils
OceanTurbPyPlotUtils.usecmbright()

using
    ColumnModelOptimizationProject,
    ColumnModelOptimizationProject.ModularKPPOptimization

alpha = 0.2
bins = 200
chaindir = "/Users/gregorywagner/Projects/ColumnModelOptimizationProject.jl/mcmc/data"

chainnames = (
    "mcmc_exp_batch_e1.0e-04_dt5.0_Δ2.jld2",
    #"mcmc_shape_simple_flux_Fb0e+00_Fu-1e-04_Nsq1e-06_Lz64_Nz128_e1.0e-05_dt5.0_Δ2.jld2",
    )

Δ, N² = [], []

markers = [
    "*",
    "*",
    "*",
]

legendkw = Dict(
    :markerscale=>1.2, :fontsize=>10,
    :loc=>"upper left", :bbox_to_anchor=>(1.1, 1.0),
    :frameon=>true, :framealpha=>1.0)

markerstyle = Dict(
     :linestyle => "None",
    :markersize => 6,
    )

chainpath = joinpath(chaindir, chainnames[1])
@load chainpath chain
C₀ = chain[1].param
paramnames = propertynames(C₀)
nparams = length(paramnames)

defaultcolors = plt.rcParams["axes.prop_cycle"].by_key()["color"]

fig, axs = subplots(nrows=nparams, figsize=(10, 6))

for (i, ax) in enumerate(axs)
    p = paramnames[i]
    sca(ax)
    xlabel(latexparams[p])
    OceanTurbPyPlotUtils.removespines("top", "right", "left")
    ax.tick_params(left=false, labelleft=false)
end

ρCmax = zeros(nparams)
C★ = [zeros(nparams) for name in chainnames]

get_Δ(nll) = nll.model.grid.Δc
get_Δ(nll::BatchedNegativeLogLikelihood) = nll.batch[1].model.grid.Δc
get_N²(nll) = nll.data.bottom_Bz
get_N²(nll::BatchedNegativeLogLikelihood) = nll.batch[1].data.bottom_Bz

for (i, name) in enumerate(chainnames)
    global C₀

    c = defaultcolors[i]

    chainpath = joinpath(chaindir, name)
    @load chainpath chain
    C₀ = chain[1].param

    opt = optimal(chain)
    @show name
    @show length(chain)
    @show chain.acceptance
    @show opt.param

    try
        push!(Δ, chain.nll.model.grid.Δc)
        push!(N², chain.nll.data.bottom_Bz)
    catch
        push!(Δ, chain.nll.batch[1].model.grid.Δc)
        push!(N², chain.nll.batch[1].data.bottom_Bz)
    end

    after = 1
    samples = Dao.params(chain, after=after)

    for (j, Cname) in enumerate(paramnames)

        C = map(x->getproperty(x, Cname), samples)
        C★[i][j] = getproperty(opt.param, Cname)

        sca(axs[j])
        ρCj, _, _ = plt.hist(C, bins=bins, alpha=alpha, density=true, facecolor=c)

        ρCmax[j] = max(ρCmax[j], maximum(ρCj))
    end
end

for (i, name) in enumerate(chainnames)
    c = defaultcolors[i]

    for (j, Cname) in enumerate(paramnames)

        if j == 1
            lbl₀ = "Large et al. (1994)"
            lbl★ = @sprintf(
                "\$ N^2 = %.0e \\, \\mathrm{s^{-2}}\$, \$ \\Delta = %.0f \$ m", N²[i], Δ[i])
        else
            lbl₀ = ""
            lbl★ = ""
        end


        sca(axs[j])
        i == 1 && plot(C₀[j], 1.1ρCmax[j], label=lbl₀, marker="o", color="0.1",
                        linestyle="None", markersize=4, alpha=0.8)

        marker = markers[i]
        plot(C★[i][j], 1.1ρCmax[j], marker; label=lbl★, color=c, markerstyle...)

    end
end

sca(axs[1])
legend(; legendkw...)

tight_layout()
gcf()
