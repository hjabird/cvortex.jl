##############################################################################
#
# VortexParticle.jl
#
# Part of CVortex.jl
# Representation of a vortex particle.
#
# Copyright 2019 HJA Bird
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to 
# deal in the Software without restriction, including without limitation the 
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
##############################################################################

"""
Representation of a vortex particle.

coord is a particle's position.
vorticity is the particle's vorticity
volume is the volume of the particle. This is only important for 
viscous vortex particle strength exchange methods (not included in this
wrapper)
"""
struct VortexParticle
    coord :: Vec3f
    vorticity :: Vec3f
    volume :: Float32
end

function VortexParticle(coord::Vec3f, vort::Vec3f)
    return VortexParticle(coord, vort, 0.0)
end

function VortexParticle(coord::Vector{<:Real}, vort::Vector{<:Real}, vol::Real)
	@assert(length(coord)==3)
	@assert(length(vort)==3)
    return VortexParticle(Vec3f(coord), Vec3f(vort), vol)
end

function VortexParticle(coord::Vector{<:Real}, vort::Vector{<:Real})
	@assert(length(coord)==3)
	@assert(length(vort)==3)
    return VortexParticle(coord, vort, 0.0)
end

"""
	Compute the velocity induced in the flow field by vortex particles.

    Arg1:   Position of inducing particles
    Arg2:   Vorticity of inducing particles
    Arg3:   Measurement points 
    Arg4:   Regularisation kernel (VortFunc_winckelmans for example)
    Arg5:   Regularisation distance
"""
function particle_induced_velocity(
    inducing_particle_position :: Vector{<:Real},
    inducing_particle_vorticity :: Vector{<:Real},
	measurement_point :: Vector{<:Real},
	kernel :: VortexFunc,
	regularisation_radius :: Real)
    
    inducing_particle = VortexParticle(
        inducing_particle_position, 
        inducing_particle_vorticity, 0.0)
    mes_pnt = Vec3f(measurement_point)
	ret = Vec3f(0., 0., 0.)
	#=
	cvtx_Vec3f cvtx_Particle_ind_vel(
		const cvtx_Particle *self, 
		const cvtx_Vec3f mes_point, 
		const cvtx_VortFunc *kernel,
		float regularisation_radius);
	=#
	ret = ccall(
			("cvtx_Particle_ind_vel", libcvortex), 
			Vec3f, 
			(Ref{VortexParticle}, Vec3f, Ref{VortexFunc}, Cfloat),
			inducing_particle, mes_pnt, kernel, regularisation_radius
			)
	return [ret.x, ret.y, ret.z]
end

function particle_induced_velocity(
    inducing_particle_position :: Matrix{<:Real},
    inducing_particle_vorticity :: Matrix{<:Real},
	measurement_point :: Vector{<:Real},
	kernel :: VortexFunc,
	regularisation_radius :: Real)
    
    @assert(
        size(inducing_particle_position)[1]==size(inducing_particle_vorticity)[1], 
        "size[1] of inducing_particle_position matrix should be the same"*
		" as size[1] of inducing_particle_vorticity matrix.")
	
	np = size(inducing_particle_position)[1]
    inducing_particles = map(
        i->VortexParticle(
            inducing_particle_position[i, :], 
            inducing_particle_vorticity[i, :], 0.0),
        1:np)
    mes_pnt = Vec3f(measurement_point)
	
	pargarr = Vector{Ptr{VortexParticle}}(undef, length(inducing_particles))
	for i = 1 : length(pargarr)
		pargarr[i] = Base.pointer(inducing_particles, i)
	end
	ret =Vec3f(0., 0., 0.)
	#=
	cvtx_Vec3f cvtx_ParticleArr_ind_vel(
		const cvtx_Particle **array_start,
		const int num_particles,
		const cvtx_Vec3f mes_point,
		const cvtx_VortFunc *kernel,
		float regularisation_radius);
	=#		
	ret = ccall(
			("cvtx_ParticleArr_ind_vel", libcvortex), 
			Vec3f, 
			(Ref{Ptr{VortexParticle}}, Cint, Vec3f, Ref{VortexFunc}, Cfloat),
			pargarr, np, mes_pnt, kernel,	regularisation_radius)
	return [ret.x, ret.y, ret.z]
end

function particle_induced_velocity(
    inducing_particle_position :: Matrix{<:Real},
    inducing_particle_vorticity :: Matrix{<:Real},
	measurement_points :: Matrix{<:Real},
	kernel :: VortexFunc,
	regularisation_radius :: Real)
    
    @assert(
        size(inducing_particle_position)[1]==size(inducing_particle_vorticity)[1], 
        "size[1] of inducing_particle_position matrix should be the same"*
        " as size[1] of inducing_particle_vorticity matrix.")
    @assert(size(measurement_points)[2]==3, "size(mesurement_points) "*
		"is expected to be (M,3). Actually ", size(measurement_points), ".")
		
	np = size(inducing_particle_position)[1]
	ni = size(measurement_points)[1]
    inducing_particles = map(
        i->VortexParticle(
            inducing_particle_position[i, :], 
            inducing_particle_vorticity[i, :], 0.0),
        1:np)
    mes_pnt = map(i->Vec3f(measurement_points[i,:]), 1:ni)
	
	pargarr = Vector{Ptr{VortexParticle}}(undef, np)
	for i = 1 : length(pargarr)
		pargarr[i] = Base.pointer(inducing_particles, i)
	end
	ret = Vector{Vec3f}(undef, ni)
	#=
	void cvtx_ParticleArr_Arr_ind_vel(
		const cvtx_Particle **array_start,
		const int num_particles,
		const cvtx_Vec3f *mes_start,
		const int num_mes,
		cvtx_Vec3f *result_array,
		const cvtx_VortFunc *kernel,
		float regularisation_radius);
	=#	
	ccall(
		("cvtx_ParticleArr_Arr_ind_vel", libcvortex), 
		Cvoid, 
		(Ptr{Ptr{VortexParticle}}, Cint, Ptr{Vec3f}, 
			Cint, Ref{Vec3f}, Ref{VortexFunc}, Cfloat),
		pargarr, np, mes_pnt, ni, ret, kernel, regularisation_radius)
	return Matrix{Float32}(ret)
end


"""
	Rate of change of vorticity induced on vortex particles by element in the 
	flowfield.

    Arg1:   Position of inducing particles
    Arg2:   Vorticity of inducing particles
    Arg3:   Position of induced particles
    Arg4:   Vorticity of induced particles
    Arg5:   Regularisation kernel (VortFunc_winckelmans for example)
    Arg6:   Regularisation distance
"""
function particle_induced_dvort(
    inducing_particle_position :: Vector{<:Real},
    inducing_particle_vorticity :: Vector{<:Real},
    induced_particle_position :: Vector{<:Real},
    induced_particle_vorticity :: Vector{<:Real},
	kernel :: VortexFunc,
	regularisation_radius :: T)  where T <: Real
	
    inducing_particle = VortexParticle(
        inducing_particle_position, 
        inducing_particle_vorticity, 0.0)
	induced_particle = VortexParticle(
		induced_particle_position, 
		induced_particle_vorticity, 0.0)
	ret = Vec3f(0., 0., 0.)
	#=
	cvtx_Vec3f cvtx_Particle_ind_dvort(
		const cvtx_Particle *self, 
		const cvtx_Particle *induced_particle,
		const cvtx_VortFunc *kernel,
		float regularisation_radius);
	=#
	ret = ccall(
			("cvtx_Particle_ind_dvort", libcvortex), 
			Vec3f, 
			(Ref{VortexParticle}, Ref{VortexParticle}, Ref{VortexFunc}, Cfloat),
			inducing_particle, induced_particle, kernel, regularisation_radius
			)
	return ret
end

function particle_induced_dvort(
    inducing_particle_position :: Matrix{<:Real},
    inducing_particle_vorticity :: Matrix{<:Real},
    induced_particle_position :: Vector{<:Real},
    induced_particle_vorticity :: Vector{<:Real},
	kernel :: VortexFunc,
	regularisation_radius :: T)  where T <: Real
		
	@assert(
		size(inducing_particle_position)==size(inducing_particle_vorticity), 
		"size of inducing_particle_position matrix should be the same"*
		" as size of inducing_particle_vorticity matrix.")
	
	np = size(induced_particle_position)[1]
	inducing_particles = map(
		i->VortexParticle(
			inducing_particle_position[i, :], 
			inducing_particle_vorticity[i, :], 0.0),
		1:np)
	induced_particle = VortexParticle(
		induced_particle_position, 
		induced_particle_vorticity, 0.0)

	
	pargarr = Vector{Ptr{VortexParticle}}(undef, np)
	for i = 1 : length(pargarr)
		pargarr[i] = Base.pointer(inducing_particles, i)
	end
	ret = Vec3f(0., 0., 0.)
	#=
	cvtx_Vec3f cvtx_ParticleArr_ind_dvort(
		const cvtx_Particle **array_start,
		const int num_particles,
		const cvtx_Particle *induced_particle,
		const cvtx_VortFunc *kernel,
		float regularisation_radius)
	=#
	ret = ccall(
			("cvtx_ParticleArr_ind_dvort", libcvortex), 
			Vec3f, 
			(Ref{Ptr{VortexParticle}}, Cint, Ref{VortexParticle}, Ref{VortexFunc}, Cfloat),
			pargarr, np, induced_particle, kernel, regularisation_radius
			)
	return Vector{Float32}(ret)
end

function particle_induced_dvort(
    inducing_particle_position :: Matrix{<:Real},
    inducing_particle_vorticity :: Matrix{<:Real},
    induced_particle_position :: Matrix{<:Real},
    induced_particle_vorticity :: Matrix{<:Real},
	kernel :: VortexFunc,
	regularisation_radius :: T)  where T <: Real
		
	@assert(
		size(inducing_particle_position)==size(inducing_particle_vorticity), 
		"size of inducing_particle_position matrix should be the same"*
		" as size of inducing_particle_vorticity matrix.")
	@assert(
		size(induced_particle_position)==size(induced_particle_vorticity), 
		"size of induced_particle_position matrix should be the same"*
		" as size of induced_particle_vorticity matrix.")
	
	np = size(inducing_particle_position)[1]
	ni = size(induced_particle_position)[1]
	inducing_particles = map(
		i->VortexParticle(
			inducing_particle_position[i, :], 
			inducing_particle_vorticity[i, :], 0.0),
		1:np)
	induced_particles = map(
		i->VortexParticle(
			inducing_particle_position[i, :], 
			inducing_particle_vorticity[i, :], 0.0),
		1:ni)

	pargarr = Vector{Ptr{VortexParticle}}(undef, length(inducing_particles))
	for i = 1 : length(pargarr)
		pargarr[i] = Base.pointer(inducing_particles, i)
	end
	indarg = Vector{Ptr{VortexParticle}}(undef, ni)
	for i = 1 : length(indarg)
		indarg[i] = Base.pointer(induced_particles, i)
	end
	ret = Vector{Vec3f}(undef, ni)
	#=
	void cvtx_ParticleArr_Arr_ind_dvort(
		const cvtx_Particle **array_start,
		const int num_particles,
		const cvtx_Particle **induced_start,
		const int num_induced,
		cvtx_Vec3f *result_array,
		const cvtx_VortFunc *kernel,
		float regularisation_radius)
	=#
	ccall(
		("cvtx_ParticleArr_Arr_ind_dvort", libcvortex), 
		Cvoid, 
		(Ptr{Ptr{VortexParticle}}, Cint, Ptr{Ptr{VortexParticle}}, Cint, 
			Ptr{Vec3f}, Ref{VortexFunc}, Cfloat),
		pargarr, length(inducing_particles), indarg, length(induced_particles),
			ret, kernel, regularisation_radius
		)
	return Matrix{Float32}(ret)
end
