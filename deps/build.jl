const BUILD_DIR = dirname(@__FILE__)
const DEPS_FILE = joinpath(BUILD_DIR, "deps.jl")
const LIBCSHELL_DIR = joinpath(BUILD_DIR, "libcshell")

function clean_libcshell()
    run(`cargo clean`)
end

function build_libcshell()
    try
        output = readstring(`cargo build --verbose --release`)
        libc_rlib = match(r"libc=(.*liblibc.*\.rlib)", output).captures[1]
    catch e
        println(STDERR, "Failed to build the rust libc rlib due to the following error:")
        rethrow(e)
    end
end

function write_depsfile(text)
    open(DEPS_FILE, "w") do fp
        println(fp, text)
    end
end

function generate_deps()
    cd(LIBCSHELL_DIR)
    clean_libcshell()
    libc_rlib = build_libcshell()
    write_depsfile("const LIBC_RLIB = \"$libc_rlib\"")
end

generate_deps()
