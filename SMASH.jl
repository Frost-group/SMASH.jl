# S*M*A*S*H - module and XDATCAR Reader
# Reconstituting the Glazer tilt notation for Perovskites from sampling molecular dynamics.
# VASP (electronic structure package) XDATCAR (ab-initio molecular dynamics file format) reader
#
# Jarvist Moore Frost, University of Bath
# File begun 2014-07-12
# Addition of minimum volume ellipsoid ~ March 2017

module SMASH

using DelimitedFiles, Printf

export atomic, Trajectory
export fractionalToCartesian, minimd # Helper fns for minimum image convention
export minimumVolumeEllipsoid # New 2017! Minimum volume ellipsoid

atomic=["H", "He", 
"Li", "Be", "B", "C", "N", "O", "F", "Ne", 
"Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar", 
"K", "Ca", "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn", "Ga", "Ge", "As", "Se", "Br", "Kr", 
"Rb","Sr","Y","Zr","Nb","Mo","Tc","Ru", "Rh", "Pd", "Ag", "Cd", "In", "Sn", "Sb", "Te","I", "Xe", 
"Cs","Ba",
"La","Ce","Pr","Nd","Pm","Sm","Eu","Gd","Tb","Dy","Ho","Er","Tm","Yb","Lu",
"Hf","Ta","W","Re","Os","Ir","Pt", "Au", "Hg", "Tl", "Pb", "Bi","Po","At","Rn","Fr","Ra"]
# indices are atomic number...

# Print our (Atomic Number) table
#for Z in 1:length(atomic)
#    println(Z," ",atomic[Z])
#end

#NB: need to read moar on constructors...
mutable struct Trajectory
   cell
   natoms::Int
   frames
   nframes::Int
   atomlookup::Array
end

function readnlines(f,n)
    local lines=""
    local i=1
    for i=1:n
        lines=lines*readline(f,keep=false) # keep newlines in input stream
    end
    return (lines)
end

#readmatrix(f, nlines) = DelimitedFiles.readdlm(IOBuffer(string([readline(f) for i in 1:nlines])))
readmatrix(f, nlines) = DelimitedFiles.readdlm(IOBuffer(readnlines(f,nlines)))

# XDATCAR LOOKS LIKE THIS: 

# Perovskite_MD
#           1
#    12.580170    0.000078   -0.039648
#     0.000077   12.547782   -0.000152
#    -0.039643   -0.000153   12.594017
#   C    N    H    Pb   I
#   8   8  48   8  24
#Direct configuration=    50
#   0.43568603  0.50228894  0.53798652
#   0.03842720  0.49679247  0.48113604

function read_XDATCAR(f::IOStream; supercell::Bool=true) 
    println("Reading trajectory from ")
    display(f)
    println()

    t=Trajectory([],0,[],0,[]) 
    
    l=readline(f) #Title
    l=readline(f) #Always a '1' ?
    
    t.cell=readdlm(IOBuffer(readnlines(f,3))) #Unit cell spec (3x3 matrix of basis vectors)
    println("Unitcell: ")
    println(t.cell)

    atomnames=readmatrix(f,1) # Ref to POTCAR; AtomName and #ofatoms
    atomnums=readmatrix(f,1)
#   C     N     H     Pb    I
#   1     1     6     1     3

    t.natoms=Int(sum(atomnums)) #Total atoms in supercell

    for (count,specie) in zip(atomnums,atomnames) # Each Atom... 
        for i=1:count # For i number of each atoms
            push!(t.atomlookup,specie)
        end
    end
    println(t.atomlookup)
    # --> "C","N","H","H,"H","H","H","H","Pb","I","I","I"

    #frames=readdlm(f , dlm=(r"\r?\n?",r"Direct configuration=?"))
    #print(frames)
    
    t.nframes=0
    while !eof(f) 
        t.nframes=t.nframes+1

        stepsizeline=readline(f) # Just dropped
        coords=readmatrix(f,t.natoms) # natoms set of fractinal {a,b,c} coords
       
        show(coords)
        println("<- coords")

        if (supercell)
            supercellcoords=coords
            for cell in [1 0 0; 0 1 0; 0 0 1; 0 1 1; 1 0 1; 1 1 0; 1 1 1]
                boosted=coords .+ cell
#                show(boosted)
                supercellcoords=vcat(supercellcoords,boosted)
            end
            
            show(supercellcoords)
            print("<- supercellcoords <- length(")
            show(length(supercellcoords)/3)
            println(")")

            push!(t.frames,supercellcoords)
        else
            push!(t.frames,coords)   # Fractional coordinates!
        end
#       print(frame)
    end
   
    if (supercell)
        lu=t.atomlookup
        t.atomlookup=vcat(lu,lu,lu,lu,lu,lu,lu,lu)

        show(t.atomlookup)
        println("<- t.atomlookup")
        show(length(t.atomlookup))

        t.natoms=8 * t.natoms
        t.cell=2. * t.cell
    end

    println("Trajectory read, containing ",t.nframes," frames")

    return t
end

"fractionToCartesian(a,unitcell)

Fractional to Cartesian coordinates for vector a."
function fractionalToCartesian(a,unitcell)
    b=unitcell*a
end

"minimimum distance image convention; using a unitcell=3x3, with a and b vectors in fractional coords"
function minimd(a, b, unitcell; verbose::Bool=false)

    if verbose # pretty-print the call signature
        println("minimd(a,b,unitcell) with variables: \n")
        display(a)
        display(b)
        display(unitcell)
    end

    # Rewrote in a more sane order, via short note of W.Smith; and some googling
    d=b-a # b and a are fractional
    d=d-round.(d) # Minimum image convention in fractional space
    d=unitcell*d # Project back to real space; i.e. Angstrom
    if verbose
        display(d)
    end
    d # returns in units of the unitcell; i.e. Angstrom
end

"""
 minimumVolumeEllipsoid(points; tolerance=1e-3, verbose::Bool=true)

Calculates the minimum volume ellipsoid for the submitted point cloud.
Dimension of problem and Number of points discovered by inspection of
point cloud.

This method uses the Khachiyan algorithm, solving the dual problem in N+1 dimensions.

Khachiyan 1996 is pretty impenetrable:
http://dx.doi.org/10.1006/jagm.1996.0062
But these slides (see page 17) are fairly understandable:
https://people.orie.cornell.edu/miketodd/ublndeta.pdf
   - here I use variable names as in the above talk.

It was implemented with considerable assistance by reading J.Cumby's source code for PIEFACE:
https://github.com/jcumby/PIEFACE/blob/372b6ff6166e4996d86084a3116a8b606c25acfa/pieface/ellipsoid.py#L54-L71
Nb: Python/Numpy has crazy definiton of dotproduct = matrix multiplication. 8-[

Cumby's Python implementation seems heavily influenced by Nina Moshtagh's Matlab implementation:
https://uk.mathworks.com/matlabcentral/fileexchange/9542-minimum-volume-enclosing-ellipsoid
https://doi.org/10.1.1.116.7691
   - My implementation follows Moshtagh closely, as I find the code  well documented & the Matlab syntax is very close to Julia.
"""
function minimumVolumeEllipsoid(points; tolerance=1e-3, verbose::Bool=true, veryverbose::Bool=false)
    # N - number of points; D - dimension of problem, by inspection of point cloud
    (N,D)=size(points)

    X=Array{Float64}(points) # Forces into Float64 repr (from Any)
    X=hcat(X,ones(N))' # Lift D-dimension vectors into a higher dimensional space; i.e. pad each D-dimension tuple with 1.0
    # And then transpose to match the expected ordering for the linear algebra below
    if verbose
        println("Padded set of vectors lifted into higher dimension (X): ")
        display(X)
    end

    err = 1e7
    u = zeros(N).+(1/N) # Starts with u=eye(N)/N ; the uniform distribution

    count=1

    while err>tolerance
        V=X*(diagm(u)*X')
        #display(V)
        M=diag(X'*(inv(V)*X))
        #display(M)

                (maximum,j)=findmax(M)
        delta = (maximum - D - 1) / ((D + 1) * (maximum - 1))

        new_u = (1.0 - delta) * u
        new_u[j] += delta
        err = norm(new_u - u)

        count=count+1
        u=new_u

        if veryverbose
            println("indmax(M)=$j, maximum=M[j]=$maximum")
            println("Delta: $delta (should be >0)")
            println("Err: $err")
            println("Loops: $count")
        end
    end

    if verbose
        println("CONVERGED TO MINIMUM VOLUME")
    end

# Comment from Moshtagh's code:
# %%%%%%%%%%%%%%%%%%% Computing the Ellipse parameters%%%%%%%%%%%%%%%%%%%%%%
# % Finds the ellipse equation in the 'center form':
# % (x-c)' * A * (x-c) = 1
# % It computes a dxd matrix 'A' and a d dimensional vector 'c' as the center
# % of the ellipse.
    P=points'
    U=diagm(u)

    centre = P*u
    A = 1/D * inv(P*U*P' - (P*u)*(P*u)')
    U, s, rotation = svd(A)

    if verbose
        println("Centre of ellipse: $centre")
        println("The 'A' matrix for ellipse, centre-form (x-c)'*A*(x-c)=1:")
        display(A)
        println("\nSVD decomposition, svd(A):")

        println("U:")
        display(U)
        println("\nSigma:")
        display(s)
        println("\nRotation matrix:")
        display(rotation)
    end

    radii = 1.0./sqrt.(s)

    vol=4/3*pi*prod(radii)
    sphereradius=prod(radii)^(1/3)

    # Ellipsoid shape measure r3/r2 - r2/r1
    # Nb: As haven't crosschecked SVD definition of radii + comparison to numpy, could be back to front here
    shapeparam=radii[3]/radii[2] - radii[2]/radii[1]

    if verbose
        println("\nradii: $radii")
        println("Volume ellipsoid: $vol Equivalent Sphere radius: $sphereradius")
        println("Ellipsoid shape measure r3/r2 - r2/r1 (Care! definitons.) $shapeparam")
    end

    return centre,A,shapeparam
end

# Print SMASH titles...
function print_titles()
    SMASH=Any[ Any["System","Systematic","Sub","Simulated","Standard","Symbiotic"],
            Any["Method","Mash","Martian","Metrication","Molecular","Mutual"],
            Any["Analysis","Analytic","Ability","And","Atomic","Aristotype"],
            Any["Subtype","Suitable","Sublime","Subtle"],
            Any["Holonomy","Homeotype","Hypothetic"]]
    TILT=   Any["(+)","(-)","(0)"]

    println("Reconstituting the Glazer tilt notation for Perovskites from sampling molecular dynamics")
    print("S*M*A*S*H: ")
    for WORDS in SMASH
        print(  WORDS[1+rand(UInt32)%length(WORDS)]," ",
                 TILT[1+rand(UInt32)%length( TILT)]," " )
    end
    println()
end
# Quite enough of that; let's get on with the real work...

print_titles()
end # module
