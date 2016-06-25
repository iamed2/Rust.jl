module AST

export emit

"Correspondence between Julia types and Rust types from libc"
const RUST_TYPES = Dict{DataType, String}(
    Int8 => "int8_t",
    Int16 => "int16_t",
    Int32 => "int32_t",
    Int64 => "int64_t",
    UInt8 => "uint8_t",
    UInt16 => "uint16_t",
    UInt32 => "uint32_t",
    UInt64 => "uint16_t",
    Float32 => "c_float",
    Float64 => "c_double",
)

"Correspondence between Julia functions and Rust functions"
const RUST_FUNCTIONS = Dict{Symbol, String}(
    :+ => "add",
    :div => "div",
    :* => "mul",
    :% => "rem",
    :- => "sub",
    :~ => "not",
    :& => "bitand",
    :| => "bitor",
    :$ => "bitxor",
    :<< => "shl",
    :>> => "shr", # I believe this is the correct shift
)


function emit(li::LambdaInfo, sn::SlotNumber)::String
    emit(li, li.slotnames[sn.id])
end

"Generates a valid Rust identifier from a Julia Symbol"
function emit(li::LambdaInfo, s::Symbol)::String
    replace(string(s), r"[#0-9]", "")
end

function emit(li::LambdaInfo, t::DataType)::String
    RUST_TYPES[t]
end

"This will only handle global references to functions"
function emit(li::LambdaInfo, f::GlobalRef)::String
    RUST_FUNCTIONS[f.name]
end

function emit(li::LambdaInfo, ex::Expr)::String
    result = ""

    if ex.head === :call
        if length(ex.args) == 1
            result = "$(emit(li, ex.args[1]))()"
        else
            io = IOBuffer()
            print(io, "(", emit(li, ex.args[2]), ").", emit(li, ex.args[1]), "(")
            join(io, map(ex.args[3:end]) do arg
                emit(li, arg)
            end, ", ")
            print(io, ")")
            result = String(io)
        end

        if isleaftype(ex.typ)
            result_type = emit(li, ex.typ)
            result = "($result) as $result_type"
        end
    elseif ex.head === :return
        if isleaftype(ex.typ)
            result_type = emit(li, ex.typ)
            result = "return $(emit(li, ex.args[1])) as $result_type"
        else
            result = "return $(emit(li, ex.args[1]))"
        end
    elseif ex.head === :line
        result = ""
    else
        error("Unhandled expression type $(ex.head)")
    end

    if isleaftype(ex.typ)
        result_type = emit(li, ex.typ)
        result = "($result) as $result_type"
    end

    return result
end

function emit(li::LambdaInfo)::String
    ast = Base.uncompressed_ast(li)

    io = IOBuffer()
    print(io, "fn ", emit(li, li.def.name), "(")
    join(io, map(li.slotnames[2:end], li.slottypes[2:end]) do name, typ
        "$(emit(li, name)): $(emit(li, typ))"
    end, ", ")
    print(io, ") -> ", emit(li, li.rettype), " { ")
    for ex in ast
        println(io, "    ", emit(li, ex))
    end
    println(io, "}")

    return String(io)
end

function generate_rust(func::Function, args::ANY)::Tuple{String, String}
    li = code_typed(func, args; optimize=false)[1]

    if !li.inferred
        error("Unable to infer types. Try adding lots of type assertions!")
    end

    emit(li, li.def.name), emit(li)
end

end
