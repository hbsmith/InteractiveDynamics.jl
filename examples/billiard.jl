using DynamicalBilliards, InteractivePlotting, Makie, MakieLayout

# %% test
dt = 0.001
tail = 500 # multiple of dt
N = 100

bd = billiard_stadium(1.0f0, 1.0f0)
bd = Billiard(bd..., Disk(SVector(0.5f0, 0.5f0), 0.2f0))
cs = [Makie.RGBAf0(i/N, 0, 1 - i/N, 0.25) for i in 1:N]
ps = [Particle(1, 0.6f0 + 0.0005f0*i, 0) for i in 1:N]
ps = [MagneticParticle(1, 0.6f0 + 0.0005f0*i, 0, 1.0f0) for i in 1:N]
# scale_plot=false
scene, layout = layoutscene(resolution = (800, 800))
ax = layout[1:3, 1] = LAxis(scene)
ax.autolimitaspect = 1
# bdplot!(ax, bd[1])
# bdplot!(ax, bd[2])
# bdplot!(ax, bd[3])
# bdplot!(ax, bd[4])
# bdplot!(ax, bd[5])
bdplot!(ax, bd)

allparobs = [ParObs(p, bd, tail) for p in ps]

for (i, p) in enumerate(allparobs)
    lines!(ax, p.tail, color = cs[i])
end

runtoggle = LToggle(scene, active = false)
runtext = LText(scene, "run:")
layout[4, 1] = grid!(hcat(runtext, runtoggle), width = Auto(false), height = Auto(false))

# Toggle test
on(runtoggle.active) do act
    @async while runtoggle.active[]
        for i in 1:N
            p = ps[i]
            parobs = allparobs[i]
            animstep!(p, bd, dt, parobs)
        end
        yield()
        isopen(scene) || break
    end
end


# layout[4, 1] = controlgrid = GridLayout(width = Auto(false), height = Auto(false))
# runbutton = LButton(scene, label = "run")
# stopbutton = LButton(scene, label = "stop")
# doesitrun = Observable(false)
# controlgrid[1, 1:2] = [runbutton, stopbutton]
#
# on(runbutton.clicks) do c
#     doesitrun[] = true
# end
# on(stopbutton.clicks) do c
#     doesitrun[] = false
# end
# on(doesitrun) do run
#     if doesitrun[]
#         for j in 1:1000
#             for i in 1:N
#                 p = ps[i]
#                 parobs = allparobs[i]
#                 animstep!(p, bd, dt, parobs)
#             end
#             yield()
#             isopen(scene) || break
#         end
#     end
# end


# #
# for _ in 1:1000
#     for i in 1:N
#         p = ps[i]
#         parobs = allparobs[i]
#         animstep!(p, bd, dt, parobs)
#     end
#     yield()
# end

# initialize all the stuff
scene

# %%
using BenchmarkTools, DataStructures
# TODO: try https://juliacollections.github.io/DataStructures.jl/latest/circ_buffer/
n = 100
x = [Point2f0(0.5, 0.5) for i in 1:n]
@btime (popfirst!(v); push!(v, Point2f0(1.0, 1.0))) setup=(v=copy(x));
@btime popfirst!(push!(v, Point2f0(1.0, 1.0))) setup=(v=copy(x));

cb = CircularBuffer{Point2f0}(n)
append!(cb, x)

@btime push!(c, Point2f0(0.1, 0.1)) setup = (c=copy(cb))

# TODO: Don't update plots in every step. This will allow smaller `dt`, (higher resolution)
# but not updating at every dt. instead every 10 dt or so.
# Establish a benchmarking scenario of 1000 particles with 100 tail
# BUT this is not possible with the circular datastrcuture... I need to append at aevery point
# But I can update the plot stuff at NOT every point. This will mean that the
# particle pos and tail and the actual plotted observables are different and instead
# once every time the update happens.
