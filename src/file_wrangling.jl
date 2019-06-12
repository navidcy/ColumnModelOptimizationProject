function iterations(datapath)
    file = jldopen(datapath, "r")
    iters = parse.(Int, keys(file["timeseries/t"]))
    close(file)
    return iters
end

function times(datapath)
    iters = iterations(datapath)
    t = zeros(length(iters))
    jldopen(datapath, "r") do file
        for (i, iter) in enumerate(iters)
            t[i] = file["timeseries/t/$iter"]
        end
    end
    return t
end

function getdata(varname, datapath, i; reversed=false)
    iter = iterations(datapath)[i]
    file = jldopen(datapath, "r")
    var = file["timeseries/$varname/$iter"]
    close(file)

    # Drop extra singleton dimensions if they exist
    if ndims(var) > 1
        droplist = []
        for d = 1:ndims(var)
           size(var, d) == 1 && push!(droplist, d)
       end
       var = dropdims(var, dims=Tuple(droplist))
    end

    reversed && reverse!(var)

    return var
end

function getconstant(varname, datapath)
    file = jldopen(datapath, "r")
    var = file["constants/$varname"]
    close(file)
    return var
end

function getbc(varname, datapath::String)
    file = jldopen(datapath, "r")
    var = file["boundary_conditions/$varname"]
    close(file)
    return var
end


function getbc(varname, side, datapath::String)
    file = jldopen(datapath, "r")
    var = file["boundary_conditions/$side/$varname"]
    close(file)
    return var
end


function getic(varname, datapath::String)
    file = jldopen(datapath, "r")
    var = file["initial_condition/$varname"]
    close(file)
    return var
end

function getgridparams(datapath::String)
    file = jldopen(datapath, "r")
    N = file["grid/Nz"]
    L = file["grid/Lz"]
    close(file)
    return N, L
end


function getdataparams(datapath)
    data_params = Dict{Symbol, Any}()
    constants = Dict{Symbol, Float64}()

    jldopen(datapath, "r") do file
        data_params[:N] = file["grid/N"]
        data_params[:L] = file["grid/L"]

        data_params[:Fb] = file["boundary_conditions/Fb"]
        data_params[:Fu] = file["boundary_conditions/Fu"]
        data_params[:Bz] = file["initial_condition/Bz"]

        for c in (:ρ₀, :cP, :g, :α, :f)
            constants[c] = file["constants/$c"]
        end
    end

    return data_params, constants
end
