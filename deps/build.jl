@info "Building Astellarn..."
@info "Setting flags and outputs..."

const builddir = (@__DIR__)
isdir(builddir) || mkdir(builddir)

const CFLAGS = `-std=c99 -O2 -Wall -D TB_NO_THREADS -fPIC -shared`
input = builddir*"/tbprobe.c"
output = builddir*"/tbprobe.so"

@info "Setting flags and outputs complete."

@info "Building fathom's tbprobe..."
cmd = `gcc $(CFLAGS) -I.. $input -o $output`
run(cmd)


@info "Finding syzygy..."
path_to_syzygy = get(ENV, "SYZYGY", "")
syzygy_found = false
if (path_to_syzygy == "") && !isfile(builddir*"/config.jl")
    @info "Syzygy not found."
    @info "Please pass the location of the syzygy build to the environment 'ENV[\"SYZYGY\"]=/Path/To/Syzygy',
        and rebuild Astellarn. Astellarn should still continue to mostly function."
else
    syzygy_found = true
    @info "Syzygy found."
end

@info "Building config.jl..."
file = open(builddir*"/config.jl", "w")
write(file, "const SYZYGY_PATH = \"$(path_to_syzygy)\"\nconst FATHOM_PATH = \"$(output)\"")
close(file)
@info "Config set."

@info "Setting executable flag for AstellarnEngine.jl"
run(`cd ../src`)
run(`chmod a+x Astellarn.jl`)

@info "Build finished."

if syzygy_found == false
    error("Build finished - however syzygy path was not found. Please pass the location of the syzygy build to the environmental variables via 'ENV[\"SYZYGY\"]=/Path/To/Syzygy', and rebuild Astellarn.")
end
