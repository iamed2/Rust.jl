module Rust

export compile_code, compile_function

import Base.Libdl: dlext, dlopen, dlsym

include(joinpath(dirname(@__FILE__), "..", "deps", "deps.jl"))
include(joinpath(dirname(@__FILE__), "AST.jl"))

import .AST

global file_counter = -1
global generated_file_dir = ""

function compile_file_num()
    global file_counter
    file_counter += 1
    return file_counter
end

function generation_dir()
    global generated_file_dir

    if !isdir(generated_file_dir)
        generated_file_dir = mktempdir()
    end

    return generated_file_dir
end

rust_file_name(crate_name) = "$crate_name.rs"
rust_lib_name(crate_name) = "lib$crate_name.$dlext"

unique_crate_name(name="") = "$name$(compile_file_num())"

const RUST_FILE_BOILERPLATE = """
    extern crate libc;
    use libc::*;
    use std::ops::*;
"""

const RUST_FUNCTION_BOILERPLATE = "#[no_mangle]\npub extern """

function compile_code(rust_code)
    crate_name = unique_crate_name()
    dir = generation_dir()
    rust_path = joinpath(dir, rust_file_name(crate_name))

    open(rust_path, "w") do fp
        println(fp, rust_code)
    end

    lib_path = compile_file(crate_name, dir, rust_path)
    return dlopen(lib_path)
end

function compile_function(func::Function, args::ANY)
    func_name, code = AST.generate_rust(func, args)

    io = IOBuffer()
    println(io, RUST_FILE_BOILERPLATE)
    println(io)
    println(io, RUST_FUNCTION_BOILERPLATE, code)

    lib = compile_code(String(io))
    func = dlsym(lib, func_name)
end

function compile_file(crate_name, dir, rust_path)
    run(`rustc $rust_path --crate-name $crate_name --crate-type dylib -C opt-level=3 --out-dir $dir --emit=dep-info,link --extern libc=$LIBC_RLIB`)

    lib_path = joinpath(dir, rust_lib_name(crate_name))
    if !isfile(lib_path)
        error("Compilation succeeded but Rust.jl failed to generate the library in the correct place")
    end

    return lib_path
end

end # module
