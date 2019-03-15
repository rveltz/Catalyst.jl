function maketype(abstracttype,
                  name,
                  f,
                  f_func,
                  f_symfuncs,
                  g,
                  g_func,
                  jumps,
                  regular_jumps,
                  jump_rate_expr,
                  jump_affect_expr,
                  p_matrix,
                  syms,
                  scale_noise;
                  params = Symbol[],
                  jac = nothing,
                  paramjac = nothing,
                  jac_prototype = nothing,
                  symjac=Matrix{ExprValues}(undef,0,0),
                  reactions=Vector{ReactionStruct}(undef,0),
                  syms_to_ints = OrderedDict{Symbol,Int}(),
                  params_to_ints = OrderedDict{Symbol,Int}(),
                  odefun = nothing,
                  sdefun = nothing,
                  make_polynomial = nothing,
                  fixed_concentrations = Dict{Symbol,Polynomial}(),
                  homotopy_continuation_template = nothing,
                  equilibratium_polynomial = nothing,
                  is_polynomial_system = true,
                  has_temporary_polynomial = true,
                  polyvars_vars = nothing,
                  polyvars_t = nothing,
                  polyvars_params = nothing
                  )

    typeex = :(mutable struct $name <: $(abstracttype)
        f::Union{Function,Nothing}
        f_func::Union{Vector{ExprValues},Nothing}
        f_symfuncs::Union{Matrix{SymEngine.Basic},Nothing}
        g::Union{Function,Nothing}
        g_func::Union{Vector{ExprValues},Nothing}
        jumps::Union{Tuple{Vararg{DiffEqJump.AbstractJump}},Nothing}
        regular_jumps::Union{RegularJump,Nothing}
        jump_rate_expr::Union{Tuple{ExprValues,Vararg{ExprValues}},Nothing}
        jump_affect_expr::Union{Tuple{Vector{Expr},Vararg{Vector{Expr}}},Nothing}
        p_matrix::Union{Array{Float64,2},Nothing}
        syms::Vector{Symbol}
        params::Vector{Symbol}
        jac::Union{Function,Nothing}
        paramjac::Union{Function,Nothing}
        jac_prototype::Nothing
        symjac::Union{Matrix{ExprValues},Nothing}
        reactions::Vector{ReactionStruct}
        syms_to_ints::OrderedDict{Symbol,Int}
        params_to_ints::OrderedDict{Symbol,Int}
        scale_noise::Symbol
        odefun::Union{ODEFunction,Nothing}
        sdefun::Union{SDEFunction,Nothing}
        make_polynomial::Union{Function,Nothing}
        fixed_concentrations::Dict{Symbol,Polynomial}
        homotopy_continuation_template::Union{Tuple{Array{Complex{Float64},1},Array{Array{Complex{Float64},1},1}},Nothing}
        equilibratium_polynomial::Union{Vector,Nothing}
        is_polynomial_system::Bool
        has_temporary_polynomial::Bool
        polyvars_vars::Union{Vector{PolyVar{true}},Nothing}
        polyvars_t::Union{PolyVar{true},Nothing}
        polyvars_params::Union{Vector{PolyVar{true}},Nothing}
    end)
    # Make the default constructor
    constructorex = :($(name)(;
                $(Expr(:kw,:f,f)),
                $(Expr(:kw,:f_func,f_func)),
                $(Expr(:kw,:g,g)),
                $(Expr(:kw,:g_func,g_func)),
                $(Expr(:kw,:jumps,jumps)),
                $(Expr(:kw,:regular_jumps,regular_jumps)),
                $(Expr(:kw,:jump_rate_expr,jump_rate_expr)),
                $(Expr(:kw,:jump_affect_expr,jump_affect_expr)),
                $(Expr(:kw,:p_matrix,p_matrix)),
                $(Expr(:kw,:f_symfuncs,f_symfuncs)),
                $(Expr(:kw,:syms,syms)),
                $(Expr(:kw,:params,params)),
                $(Expr(:kw,:symjac,symjac)),
                $(Expr(:kw,:jac,jac)),
                $(Expr(:kw,:paramjac,paramjac)),
                $(Expr(:kw,:jac_prototype,jac_prototype)),
                $(Expr(:kw,:reactions,reactions)),
                $(Expr(:kw,:syms_to_ints, syms_to_ints)),
                $(Expr(:kw,:params_to_ints, params_to_ints)),
                $(Expr(:kw,:scale_noise, Meta.quot(scale_noise))),
                $(Expr(:kw,:odefun, odefun)),
                $(Expr(:kw,:sdefun, sdefun)),
                $(Expr(:kw,:make_polynomial, make_polynomial)),
                $(Expr(:kw,:fixed_concentrations, fixed_concentrations)),
                $(Expr(:kw,:homotopy_continuation_template, homotopy_continuation_template)),
                $(Expr(:kw,:equilibratium_polynomial, equilibratium_polynomial)),
                $(Expr(:kw,:is_polynomial_system, is_polynomial_system)),
                $(Expr(:kw,:has_temporary_polynomial, has_temporary_polynomial)),
                $(Expr(:kw,:polyvars_vars, polyvars_vars)),
                $(Expr(:kw,:polyvars_t, polyvars_t)),
                $(Expr(:kw,:polyvars_params, polyvars_params))) =
                $(name)(
                        f,
                        f_func,
                        f_symfuncs,
                        g,
                        g_func,
                        jumps,
                        regular_jumps,
                        jump_rate_expr,
                        jump_affect_expr,
                        p_matrix,
                        syms,
                        params,
                        jac,
                        paramjac,
                        jac_prototype,
                        symjac,
                        reactions,
                        syms_to_ints,
                        params_to_ints,
                        scale_noise,
                        odefun,
                        sdefun,
                        make_polynomial,
                        fixed_concentrations,
                        homotopy_continuation_template,
                        equilibratium_polynomial,
                        is_polynomial_system,
                        has_temporary_polynomial,
                        polyvars_vars,
                        polyvars_t,
                        polyvars_params
                        )) |> esc

    # Make the type instance using the default constructor
    typeex,constructorex
end

# type function expressions
function gentypefun_exprs(name; esc_exprs=true, gen_inplace=true, gen_outofplace=true, gen_constructor=true)
    exprs = Vector{Expr}(undef,0)

    ## Overload the type so that it can act as a function.
    if gen_inplace
        overloadex = :(((f::$name))(du, u, p, t::Number) = (f.f(du, u, p, t); nothing))
        push!(exprs,overloadex)
    end

    ## Add a method which allocates the `du` and returns it instead of being inplace
    if gen_outofplace
        overloadex = :(((f::$name))(u,p,t::Number) = (du=similar(u); f(du,u,p,t); du))
        push!(exprs,overloadex)
    end

    # export type constructor
    if gen_constructor
        def_const_ex = :(($name)())
        push!(exprs,def_const_ex)
    end

    # escape expressions for macros
    if esc_exprs
        for i in eachindex(exprs)
            exprs[i] = exprs[i] |> esc
        end
    end

    exprs
end

######################## functions to extend a network ####################

"""
    addspecies!(network, speciessym::Symbol)

Given an AbstractReaction network, add the species corresponding to the passed
in symbol to the network (if it is not already defined). 
""" 
function addspecies!(rn::DiffEqBase.AbstractReactionNetwork, sp::Symbol)
    if !haskey(speciesmap(rn), sp)        
        push!(species(rn), sp)
        sidx = numspecies(rn) + 1
        push!(speciesmap(rn), sp => sidx)
    end
    nothing
end

"""
    addspecies!(network, speciesname::String)

Given an AbstractReaction network, add the species with name given by the passed
in string to the network (if it is not already defined.
"""
addspecies!(rn::DiffEqBase.AbstractReactionNetwork, speciesname::String) = addspecies!(rn, Symbol(speciesname))

"""
    addparam!(network, param::Symbol)

Given an AbstractReaction network, add the parameter corresponding to the passed
in symbol to the network (if it is not already defined).
"""
function addparam!(rn::DiffEqBase.AbstractReactionNetwork, param::Symbol)
    if !haskey(paramsmap(rn), param)
        push!(params(rn), param)
        pidx = numparams(rn) + 1
        push!(paramsmap(rn), param => pidx)
    end
    nothing
end

"""
    addparam!(network, paramname::String)

Given an AbstractReaction network, add the parameter with name given by the
passed in string to the network (if it is not already defined).
"""
addparam!(rn::DiffEqBase.AbstractReactionNetwork, param::String) = addparam!(rn, Symbol(param))

"""
    add_scale_noise_param!(network, scale_noise::Symbol)

Given an AbstractReaction network, add the parameter corresponding to the passed
in symbol to the network (if it is not already defined), and register it as the
noise scaling coefficient.
"""
function add_scale_noise_param!(rn::DiffEqBase.AbstractReactionNetwork, scale_noise::Symbol)    
    rn.scale_noise = scale_noise

    if !haskey(paramsmap(rn), scale_noise)
        push!(params(rn), scale_noise)
        pidx = numparams(rn) + 1
        push!(paramsmap(rn), scale_noise => pidx)
    end
    nothing
end

"""
    add_scale_noise_param!(network, scale_noise_name::String)

Given an AbstractReaction network, add the parameter with the passed in string
as its name to the network (if it is not already defined), and register it as
the noise scaling coefficient.
"""
add_scale_noise_param!(rn::DiffEqBase.AbstractReactionNetwork, scale_noise_name::String) = add_scale_noise_param!(rn, Symbol(scale_noise_name))

"""
    addreaction!(network, rateexpr::Union{Expr,Symbol,Int,Float64}, rxexpr::Expr)

Given an AbstractReaction network, add a reaction with the passed in rate and
reaction expressions. i.e. a reaction of the form
```julia
k*X, 2X + Y --> 2W
```
would have `rateexpr=:(k*X)` and `rxexpr=:(2X + Y --> W)`, 
```julia
10.5, 0 --> X
```
would have `rateexpr=10.5` and `rxexpr=:(0 --> X)`, and
```julia
k, X+X --> Z
```
would have `rateexpr=:k` and `rxexpr=:(X+X --> Z)`.

All normal DSL reaction definition notation should be supported.
"""
function addreaction!(rn::DiffEqBase.AbstractReactionNetwork, rateexpr::ExprValues, rxexpr::Expr)
    ex = Expr(:block, :(($rateexpr, $rxexpr)))
    newrxs = get_reactions(ex)
    foreach(rx -> push!(rn.reactions,ReactionStruct(rx, species(rn))), newrxs)
    nothing
end

"""
    addreaction!(network, rateexpr::Union{Expr,Symbol,Int,Float64}, substrates, products)

Given an AbstractReaction network, add a reaction with the passed in rate,
`rateexpr`, substrate stoichiometry, and product stoichiometry. Stoichiometries
are represented as tuples of `Pair{Symbol,Int}`. i.e. a reaction of the form
```julia
k*X, 2X + Y --> 2W
```
would have `rateexpr=:(k*X)`, `substrates=(:X=>2, :Y=>2)`` and
`products=(W=>2,)`, 
```julia
10.5, 0 --> X
```
would have `rateexpr=10.5`, `substrates=()` and `products=(:X=>1,)`, and
```julia
k, X+X --> Z
```
would have `rateexpr=:k`, `substrates=(:X=>2,)` and `products=(:Z=>2,)`.

All normal DSL reaction definition notation should be supported for the
`rateexpr`.
"""
function addreaction!(rn::DiffEqBase.AbstractReactionNetwork, rateexpr::ExprValues, 
                                        subs::Tuple{Vararg{Pair{Symbol,Int}}}, 
                                        prods::Tuple{Vararg{Pair{Symbol,Int}}}) where {T <: Number}

    substrates = ReactantStruct[ReactantStruct(p[1],p[2]) for p in subs]
    dependents = Symbol[p[1] for p in subs]
    products = ReactantStruct[ReactantStruct(p[1],p[2]) for p in prods]
    rate_DE = mass_rate_DE(substrates, true, rateexpr)
    rate_SSA = mass_rate_SSA(substrates, true, rateexpr)   
    
    # resolve dependents from rateexpr
    if rateexpr isa Number
        ismassaction = true        
    elseif rateexpr isa Symbol
        if haskey(speciesmap(rn), rateexpr)
            ismassaction = false
            if rateexpr ∉ dependents
                push!(dependents, rateexpr)
            end
        elseif haskey(paramsmap(rn), rateexpr)
            ismassaction = true
        else
            error("rateexpr is a symbol that is neither a species or parameter.")
        end
    else # isa Expr

        # mimicing ReactionStruct constructor for now, but this should be optimized...
        newdeps = unique!(recursive_content(rate_DE, species(rn), Vector{Symbol}()))
        ismassaction = length(newdeps)==length(intersect!(dependents, newdeps)) ? true : false
        dependents = newdeps
    end
    
    push!(rn.reactions, ReactionStruct(substrates, products, rateexpr, rate_DE, rate_SSA, dependents, ismassaction))
    nothing
end


############## Adding ODES/SDE/Jumps for problems ################

"""
    addodes!(network; build_jac=true, build_symfuncs=true)

Extend an `AbstractReactionNetwork` generated with the `@min_reaction_network`
or `@empty_reaction_network` macros with everything needed to use ODE solvers.

Optional kwargs can be used to disable the construction of additional ODE solver
components.
"""
function addodes!(rn::DiffEqBase.AbstractReactionNetwork; kwargs...)
    @unpack reactions, syms_to_ints, params_to_ints, syms = rn

    (f_expr, f, f_rhs, symjac, jac, paramjac, f_symfuncs) = genode_exprs(reactions, syms_to_ints, params_to_ints, syms; kwargs...)
    rn.f          = eval(f)
    rn.f_func     = f_rhs
    rn.jac        = eval(jac)
    rn.paramjac   = eval(paramjac)
    rn.symjac     = eval(symjac)
    rn.f_symfuncs = f_symfuncs
    rn.odefun     = ODEFunction(rn.f; jac=rn.jac, jac_prototype=nothing, paramjac=rn.paramjac, syms=rn.syms)

    # functor for evaluating f
    functor_exprs = gentypefun_exprs(typeof(rn), esc_exprs=false, gen_constructor=false)
    eval( expr_arr_to_block(functor_exprs) )

    nothing
end

"""
    addsdes!(network; build_jac=true, build_symfuncs=true)

Extend an `AbstractReactionNetwork` generated with the `@min_reaction_network`
or `@empty_reaction_network` macros with everything needed to use SDE solvers.
    
Optional kwargs can be used to disable the construction of additional SDE solver
components.
"""
function addsdes!(rn::DiffEqBase.AbstractReactionNetwork)
    @unpack reactions, syms_to_ints, params_to_ints, scale_noise = rn

    # first construct an ODE reaction network
    if rn.f == nothing
        addodes!(rn)
    end

    (g_expr, g, g_funcs, p_matrix) = gensde_exprs(reactions, syms_to_ints, params_to_ints, scale_noise)
    rn.g        = eval(g)
    rn.g_func   = g_funcs
    rn.p_matrix = p_matrix
    rn.sdefun   = SDEFunction(rn.f, rn.g; jac=rn.jac, jac_prototype=nothing, paramjac=rn.paramjac, syms=rn.syms)

    nothing
end

"""
    addjumps!(network; build_jumps=true, build_regular_jumps=true, minimal_jumps=false)

Extend an `AbstractReactionNetwork` generated with the `@min_reaction_network`
or `@empty_reaction_network` macros with everything needed to use jump SSA solvers.
    
Optional kwargs can be used to disable the construction of additional jump solver
components.

Keyword arguments:

* `build_jumps`: if true jump rates and affects will be calculated for use in
  DiffEqJump SSAs.

* `build_regular_jumps`: if true a `RegularJump` representation of the
  stochastic chemical kinetics model will be calculated for use in τ-leaping
  methods.

* `minimal_jumps`: if true `ConstantRate` jumps are only constructed for
  non-mass action jumps. (Note, mass action jumps are still resolved within any
  jump simulation. This option simply speeds up the construction of the jump
  problem since it avoids building redundant `ConstantRate` jumps that encode
  `MassActionJump`s, which are subsequently ignored within jump simulations.)
""" 
function addjumps!(rn::DiffEqBase.AbstractReactionNetwork;
                                    build_jumps=true,
                                    build_regular_jumps=true,
                                    minimal_jumps=false)

    @unpack reactions, syms_to_ints, params_to_ints = rn

    # parse the jumps
    (jump_rate_expr, jump_affect_expr, jumps, regular_jumps) = get_jumps(reactions,
                                                                    syms_to_ints,
                                                                    params_to_ints;
                                                                    minimal_jumps=minimal_jumps)

    rn.jump_rate_expr   = jump_rate_expr
    rn.jump_affect_expr = jump_affect_expr
    rn.jumps            = build_jumps ? eval(jumps) : nothing
    rn.regular_jumps    = build_regular_jumps ? eval(regular_jumps) : nothing

    nothing
end

function addequi!(rn::DiffEqBase.AbstractReactionNetwork)
    @unpack params, reactions, syms_to_ints, params_to_ints, scale_noise = rn

    # first construct an ODE reaction network (required for getting f_func).
    if rn.f == nothing
        addodes!(rn)
    end

    equipol_maker = get_equilibration(params,syms_to_ints,rn.f_func)

    rn.make_polynomial = eval(equipol_maker)
    rn.polyvars_vars = (@polyvar internal___polyvar___x[1:length(syms_to_ints)])[1]
    rn.polyvars_t = (@polyvar internal___polyvar___t)[1]
    rn.polyvars_params = (@polyvar internal___polyvar___p[1:length(params)])[1]

    nothing
end
