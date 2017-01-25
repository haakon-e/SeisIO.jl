using Base.Test, Compat

# script to test each compatible type
D = Dict{String,Any}()
D["0"] = 'c'
D["1"] = randstring(rand(51:100))
D["16"] = rand(UInt8)
D["17"] = rand(UInt16)
D["18"] = rand(UInt32)
D["19"] = rand(UInt64)
D["20"] = rand(UInt128)
D["32"] = rand(Int8)
D["33"] = rand(Int16)
D["34"] = rand(Int32)
D["35"] = rand(Int64)
D["36"] = rand(Int128)
D["48"] = rand(Float16)
D["49"] = rand(Float32)
D["50"] = rand(Float64)
D["80"] = rand(Complex{UInt8})
D["81"] = rand(Complex{UInt16})
D["82"] = rand(Complex{UInt32})
D["83"] = rand(Complex{UInt64})
D["84"] = rand(Complex{UInt128})
D["96"] = rand(Complex{Int8})
D["97"] = rand(Complex{Int16})
D["98"] = rand(Complex{Int32})
D["99"] = rand(Complex{Int64})
D["100"] = rand(Complex{Int128})
D["112"] = rand(Complex{Float16})
D["113"] = rand(Complex{Float32})
D["114"] = rand(Complex{Float64})
D["128"] = collect(rand(Char, rand(4:24)))
D["129"] = collect(repeated(randstring(rand(4:24)), rand(4:24)))
D["144"] = collect(rand(UInt8, rand(4:24)))
D["145"] = collect(rand(UInt16, rand(4:24)))
D["146"] = collect(rand(UInt32, rand(4:24)))
D["147"] = collect(rand(UInt64, rand(4:24)))
D["148"] = collect(rand(UInt128, rand(4:24)))
D["160"] = collect(rand(Int8, rand(4:24)))
D["161"] = collect(rand(Int16, rand(4:24)))
D["162"] = collect(rand(Int32, rand(4:24)))
D["163"] = collect(rand(Int64, rand(4:24)))
D["164"] = collect(rand(Int128, rand(4:24)))
D["176"] = collect(rand(Float16, rand(4:24)))
D["177"] = collect(rand(Float32, rand(4:24)))
D["178"] = collect(rand(Float64, rand(4:24)))
D["208"] = collect(rand(Complex{UInt8}, rand(4:24)))
D["209"] = collect(rand(Complex{UInt16}, rand(4:24)))
D["210"] = collect(rand(Complex{UInt32}, rand(4:24)))
D["211"] = collect(rand(Complex{UInt64}, rand(4:24)))
D["212"] = collect(rand(Complex{UInt128}, rand(4:24)))
D["224"] = collect(rand(Complex{Int8}, rand(4:24)))
D["225"] = collect(rand(Complex{Int16}, rand(4:24)))
D["226"] = collect(rand(Complex{Int32}, rand(4:24)))
D["227"] = collect(rand(Complex{Int64}, rand(4:24)))
D["228"] = collect(rand(Complex{Int128}, rand(4:24)))
D["240"] = collect(rand(Complex{Float16}, rand(4:24)))
D["241"] = collect(rand(Complex{Float32}, rand(4:24)))
D["242"] = collect(rand(Complex{Float64}, rand(4:24)))

io = open("crapfile.bin","w")
write_misc(io, D)
close(io)

io = open("crapfile.bin","r")
DD = read_misc(io)
close(io)

[@test_approx_eq(D[k]==DD[k],true) for k in sort(collect(keys(D)))]

rm("crapfile.bin")
