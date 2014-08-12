# S*M*A*S*H
# Reconstituting the Glazer tilt notation for Perovskites from sampling molecular dynamics.
# VASP (electronic structure package) XDATCAR (ab-initio molecular dynamics file format) reader
#
# Jarvist Moore Frost, University of Bath
# File begun 2014-07-12

type Trajectory
    
end

function readnlines(f,n)
    local lines=""
    local i=1
    for i=1:n
        lines=lines*readline(f)
    end
    return (lines)
end

function read_XDATCAR(f::IOStream)
    l=readline(f) #Title
    l=readline(f) #Always a '1' ?
    
    cell=readdlm(IOBuffer(readnlines(f,3)))
    println(cell)

    atomlookup=readdlm(IOBuffer(readnlines(f,2)))
    println(atomlookup)

    atoms=int(sum(atomlookup[2,1:end])) #quite ugly; but works

    println("$atoms atoms in XDATCAT frames")
    #frames=readdlm(f , dlm=(r"\r?\n?",r"Direct configuration=?"))
    #print(frames)

    nframe=0
    while !eof(f) 
        nframe=nframe+1

        stepsizeline=readline(f)

        frame=readdlm(IOBuffer(readnlines(f,atoms)))
#        print(frame)
    end
    println("read_XDATCAR: $nframe Green Bottles...")
end

# Test routines...
f=open("testmd2-nonselective_XDATCAR","r")
read_XDATCAR(f)
