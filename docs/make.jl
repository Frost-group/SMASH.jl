using SMASH
using Documenter

DocMeta.setdocmeta!(SMASH, :DocTestSetup, :(using SMASH); recursive=true)

makedocs(;
    modules=[SMASH],
    authors="Jarvist Moore Frost",
    repo="https://github.com/Frost-group/SMASH.jl/blob/{commit}{path}#{line}",
    sitename="SMASH.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Frost-group.github.io/SMASH.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Frost-group/SMASH.jl",
    devbranch="main",
)
