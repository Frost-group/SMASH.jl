push!(LOAD_PATH,"./") # Temporary versions of modules in PWD
using SMASH

using Printf

# Test routines...
#f=open("testmd2-nonselective_XDATCAR","r")
f=open("POSCAR-MAPI-Cs") # single unit cell CsPbI3 test; symmetry broken
#f=open("POSCAR-MAPbI-2x2x2-Cubic","r") # Seems to work on Vasp5 POSCARs a.OK
t=SMASH.read_XDATCAR(f) #Returns type XDATCAR.Trajcetory

"Iterate over frames, calculate distances between Pb and I. Uses minimd PBCs!"
function PbIdistance(t; verbose::Bool=false )
    grandsum=0.0
    octahedra=0

    for i in 1:t.nframes # Iterate over all frames of trajectory
        @printf("\nFrame: %d . Hunting for octahedra...",i)
        Pbs=t.frames[i][t.atomlookup .=="Pb",:]
        Is=t.frames[i][t.atomlookup .=="I",:]

        for j=1:size(Pbs,1) # Iterate over Pb atoms
            Pb=Pbs[j,:]
            #display(Pb)
            @printf("\n\nPb %d: at [%f,%f,%f] Fractional",j,Pb[1],Pb[2],Pb[3])
            PbCartesian=fractionalToCartesian(Pb,t.cell)
            @printf(", [%0.3f,%0.3f,%0.3f] Cartesian.",
                PbCartesian[1],PbCartesian[2],PbCartesian[3])

            sumd=0.0
            octahedrapoints=Matrix(0,3)

            @printf("\nIodine: ")
            Icount=0
            for k=1:size(Is,1) # Iterate over I, using minimmum image convention distance to find iodide
                I=Is[k,:]
                #display(I)

                d=minimd(Pb,I,t.cell)
                #println("Pb: ",Pb," I: ",I," Diff: ",Pb-I, " Norm: ",norm(Pb-I))
                if (norm(d)<4) # MAGIC NUMBER; Pb-I distance angstroms
                    #@printf(" %0.3f",norm(minimd(Pb,I,t.cell)))
#                    @printf("\n I %d at \td=%0.3f \t[%0.3f,%0.3f,%0.3f,]",k,norm(d),d[1],d[2],d[3] )
                    octahedrapoints=[octahedrapoints; d']
                    sumd+=d

                    Icount=Icount+1
                    @printf(".");
                    if (verbose) print("\n",d) end # verbose coords, of each found Iodine
                end
            end

            # OK, now we have a set of Iodines which make up the octahedra around this Pb site
            # Everything is referenced to Pb at {0,0,0}, in Cartesian coordinates
            if (Icount==6) # if we've found 6 members of our octahedra
                centre,A,shapeparam=minimumVolumeEllipsoid(octahedrapoints,verbose=false)
                @printf("\nMinimum volume ellipsoid. Shapeparam: %0.4f Centre: [%0.3f,%0.3f,%0.3f], \td=%0.5f",
                    shapeparam,centre[1],centre[2],centre[3],norm(centre))
            else
                @printf("\nEeek! %d Iodine does not make an octahedra. Cowardly refusing to calculate an ellipsoid.",Icount)
            end

            meand=sumd/6;
            @printf("\n(Pb)-I6 'sumd' vector: \t[%0.3f,%0.3f,%0.3f] \td=%0.5f",
                meand[1],meand[2],meand[3],norm(meand))
            #@printf("\n(Pb)-I6 CoM: [%0.3f,%0.3f,%0.3f] ",sumd[1]/6,sumd[2]/6,sumd[3]/6)

            @printf("\ndot(sumd,ellipsoidcentre)/norm(sumd)^2 = %f ",
                dot(meand,centre)/norm(meand)^2)

            grandsum+=sumd
            octahedra+=1
        end
    end
    println("\nGrand sum: ",grandsum)
    println("Grandsum / number octahedra: ",grandsum/octahedra)
end

PbIdistance(t, verbose=false)


