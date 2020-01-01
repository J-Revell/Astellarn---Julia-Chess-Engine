const builddir = (@__DIR__)
isdir(builddir) || mkdir(builddir)

const CFLAGS = `-std=c99 -O2 -Wall -D TB_NO_THREADS -fPIC -shared`
input = builddir*"/tbprobe.c"
output = builddir*"/tbprobe.so"

@info "Building fathom's tbprobe..."
cmd = `gcc $(CFLAGS) -I.. $input -o $output`
run(cmd)

@info "Finding syzygy..."
path_to_syzygy = get(ENV, "SYZYGY", "")
if (path_to_syzygy == "") && !isfile(builddir*"/config.jl")
    @error "Please pass the location of the syzygy build to the environment 'ENV[\"SYZYGY\"]=/Path/To/Syzygy'"
else
    @info "Building config.jl..."
    file = open(builddir*"/config.jl", "w")
    write(file, "const SYZYGY_PATH = \"$(path_to_syzygy)\"")
    close(file)
end