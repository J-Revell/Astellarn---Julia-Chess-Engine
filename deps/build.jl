@info "Building Astellarn..."
@info "Setting flags and outputs..."

const builddir = (@__DIR__)
isdir(builddir) || mkdir(builddir)

const CFLAGS = `-std=c99 -O2 -Wall -D TB_NO_THREADS -fPIC -shared`
if Sys.iswindows()
    input = builddir*"\\tbprobe.c"
    output = builddir*"\\tbprobe.exe"
    @info "Setting flags and outputs complete."
    @info "Building fathom's tbprobe..."
    cmd = `x86_64-w64-mingw32-gcc $(CFLAGS) -I.. $input -o $output`
else
    input = builddir*"/tbprobe.c"
    output = builddir*"/tbprobe.so"
    @info "Setting flags and outputs complete."
    @info "Building fathom's tbprobe..."
    cmd = `gcc $(CFLAGS) -I.. $input -o $output`
end
run(cmd)

@info "Building config.jl..."
file = open(builddir*"/config.jl", "w")
write(file, "const FATHOM_PATH = \"$(output)\"")
close(file)
@info "Config set."

@info "Setting executable flag for AstellarnEngine.jl"
cd("../src")
if Sys.islinux()
    run(`chmod a+x Astellarn.jl`)
end

@info "Build finished."
