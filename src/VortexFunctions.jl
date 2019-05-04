##############################################################################
#
# VortexFunctions.jl
#
# Part of cvortex.jl
# Get vortex regularisation methods.
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
	A 3D vortex regularisation fuction

	The method by which the singular nature of a vortex particle is handelled.
	Generally, this structure is best obtained via VortFunc_*. For example
	VortFunc_singular(), VortFunc_planetary(), VortFunc_winckelmans() or
	VortFunc_gaussian().

	Exposure of this allows the use of user kernels in the CPU multithreaded
	implementations in cvortex. If you're interested in this, looking at the
	cvortex library and the source of cvortex.jl is suggested to understand
	the required functions signitures. 
"""
struct VortexFunc
	g_fn :: Ptr{Cvoid}			# Actually float(*g_fn)(float rho)
	zeta_fn :: Ptr{Cvoid}		# Actually float(*zeta_fn)(float rho)
	combined_fn :: Ptr{Cvoid}	# Actually void(*combined_fn)(float rho, float* g, float* zeta)
	eta_fn :: Ptr{Cvoid}		# Actually float(*eta_fn)(float rho)
	cl_kernel_name_ext :: NTuple{32, Cchar}	# Char[32]
end

#= Functions to to get VortexFunc structures =#
function VortFunc_singular()
	ret = ccall(("cvtx_VortFunc_singular", libcvortex), VortexFunc, ())
	return ret;
end
function VortFunc_winckelmans()
	ret = ccall(("cvtx_VortFunc_winckelmans", libcvortex), VortexFunc, ())
	return ret;
end
function VortFunc_planetary()
	ret = ccall(("cvtx_VortFunc_planetary", libcvortex), VortexFunc, ())
	return ret;
end
function VortFunc_gaussian()
	ret = ccall(("cvtx_VortFunc_gaussian", libcvortex), VortexFunc, ())
	return ret;
end
