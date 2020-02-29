export d2u, j2md, md2j, parsetimewin, timestamp, u2d, timespec

function tstr(t::DateTime)
  Y, M, D, h, m, s, μ = year(t), month(t), day(t), hour(t), minute(t), second(t), millisecond(t)
  Y = lpad(Y, 4, "0")
  M = lpad(M, 2, "0")
  D = lpad(D, 2, "0")
  h = lpad(h, 2, "0")
  m = lpad(m, 2, "0")
  s = lpad(s, 2, "0")
  return string(Y, "-", M, "-", D, "T", h, ":", m, ":", s)
end

"Alias to Dates.unix2datetime"
u2d(k::Real) = Dates.unix2datetime(k)
"Alias to Dates.datetime2unix"
d2u(k::DateTime) = Dates.datetime2unix(k)

@doc """
    timestamp()

Return current time formatted YYYY-mm-ddTHH:MM:SS.
""" timestamp
timestamp() = tstr(Dates.unix2datetime(time()))
timestamp(t::DateTime) = tstr(t)
timestamp(t::Real) = tstr(u2d(t))
timestamp(t::String) = tstr(Dates.DateTime(t))
tnote(s::String) = string(timestamp(), " ¦ ", s)

"""
    m,d = j2md(y,j)

Convert Julian day j of year y to month m, day d
"""
function j2md(y::T, j::T) where T<:Integer
  if T != Int32
    y = Int32(y)
    j = Int32(j)
  end
  z = zero(Int32)
  o = one(Int32)
  m = z
  d = o
  if j > Int32(31)
    leapyear = ((j > 59) && ((y % Int32(400) == z) || (y % Int32(4) == z && y % Int32(100) != z)))
    while j > z
      d = j
      m += o
      j -= days_per_month[m]
      if leapyear && m == 2
        j -= o
      end
    end
  else
    m = o
    d = j
  end
  return m,d
end

"""
    j = md2j(y, m, d)

Convert month `m`, day `d` of year `y` to Julian day (day of year)
"""
function md2j(y::T, m::T, d::T) where T<:Integer
  j = zero(Int32)
  if T != Int32
    y = Int32(y)
    m = Int32(m)
    d = Int32(d)
  end
  z = zero(Int32)
  i = one(Int8)
  while i < m
    j = j+getindex(days_per_month, i)
    i = i+1
  end
  j = j+d
  if m > 2 && ((y % Int32(400) == z) ||
               (y % Int32(4)   == z &&
                y % Int32(100) != z))
    j = j+1
  end
  return T(j)
end
md2j(y::AbstractString, m::AbstractString, d::AbstractString) = md2j(parse(Int, y), parse(Int, m), parse(Int, d))


@doc """
# Time Specification

Most functions that allow time specification use two reserved keywords to track
time:
* `s`: Start (begin) time
* `t`: Termination (end) time

The values passed to keywords `s` and `t` can be real numbers, DateTime objects,
or ASCII strings; details and specific requirements are given in the time API (https://github.com/jpjones76/SeisIO.jl/blob/master/docs/DevGuides/time.md).

## **parsetimewin Behavior**
In all cases, parsetimewin outputs a pair of strings, sorted so that the first string corresponds to the earlier start time.

| typeof(s) | typeof(t) | Behavior                                          |
|:------    |:------    |:-------------------------------------             |
| DateTime  | DateTime  | sort                                              |
| DateTime  | Real      | add *t* seconds to *s*, then sort                 |
| DateTime  | String    | convert *t* => DateTime, then sort                |
| DateTime  | String    | convert *t* => DateTime, then sort                |
| Real      | DateTime  | add *s* seconds to *t*, then sort                 |
| Real      | Real      | treat *s*, *t* as seconds from current time; sort |
| String    | DateTime  | convert *s* => DateTime, then sort                |
| String    | Real      | convert *s* => DateTime, then sort                |

### Timekeeping with Real values
Numeric time values are interpreted relative to the start of the current minute. Thus, if `-s` or `-t` is 0, the data request begins (or ends) at the start of the minute in which the request is submitted.
""" timespec
timespec() = nothing

"""
    (str0, str1) = parsetimewin(ts1::TimeSpec, ts2::TimeSpec)

Convert times `s` and `t` to strings and sorts s.t. d0 < d1.

See also: ?timespec
"""
function parsetimewin(s::DateTime, t::DateTime)
  if s < t
    return (string(s), string(t))
  else
    return (string(t), string(s))
  end
end
parsetimewin(s::DateTime, t::String) = parsetimewin(s, DateTime(t))
parsetimewin(s::DateTime, t::Real) = parsetimewin(s, u2d(d2u(s)+t))
parsetimewin(s::Real, t::DateTime) = parsetimewin(t, u2d(d2u(t)+s))
parsetimewin(s::String, t::Union{Real,DateTime}) = parsetimewin(DateTime(s), t)
parsetimewin(s::Union{Real,DateTime}, t::String) = parsetimewin(s, DateTime(t))
parsetimewin(s::String, t::String) = parsetimewin(DateTime(s), DateTime(t))
parsetimewin(s::Real, t::Real) = parsetimewin(u2d(60*floor(Int, time()/60) + s), u2d(60*floor(Int, time()/60) + t))

# =========================================================
# Not for export
function y2μs(y::T) where T<:Integer
  y = Int64(y)-1
  return 86400000000 * (y*365 + div(y,4) - div(y,100) + div(y,400)) - 62135596800000000
end

# ts = round(Int64, d2u(DateTime(iv[1], m, d, iv[3], iv[4], iv[5], iv[6]))*sμ
mktime(y::T, j::T, h::T, m::T, s::T, μ::T) where T<:Integer = (y2μs(y) +
          Int64(j-one(T))*86400000000 +
          Int64(h)*3600000000 +
          Int64(m)*60000000 +
          Int64(s)*1000000 +
          Int64(μ))
mktime(t::Array{T,1}) where T<:Integer =(y2μs(t[1]) +
          Int64(t[2]-one(T))*86400000000 +
          Int64(t[3])*3600000000 +
          Int64(t[4])*60000000 +
          Int64(t[5])*1000000 +
          Int64(t[6]))

# convert a formatted time string to integer μs from the Unix epoch
function tstr2int(s::String)
  str = split(s, ".", limit=2)
  if length(str) < 2
    μ = 0
  else
    μ = parse(Int64, rpad(str[2], 6, '0'))
  end
  return DateTime(str[1]).instant.periods.value*1000 - dtconst + μ
end

# convert a time in integer μs (measured from the Unix epoch) to a string
function int2tstr(t::Int64)
  dt = unix2datetime(div(t, 1000000))
  v = 1000*getfield(getfield(getfield(dt, :instant), :periods), :value)
  r = string(t - v + dtconst)
  s = string(dt) * "." * lpad(r, 6, '0')
  return s
end

# =========================================================
# Time windowing functions
"""
    t = endtime(T::Array{Int64,2}, Δ::Int64)

Compute the time of the last sample in *T* sampled at interval *Δ* [μs] or frequency *fs* [Hz]. Output is integer μs measured from the Unix epoch.
"""
function endtime(t::Array{Int64,2}, Δ::Int64)
  if isempty(t)
    t_end = 0
  else
    L = size(t,1)
    t_end = (t[L,1]-1)*Δ
    if L > 2
      t_end += getindex(sum(t, dims=1),2)
    else
      t_end += t[1,2]
    end
    # t_end = getindex(sum(t, dims=1),2) + (t[L,1]-1)*Δ
  end
  return t_end
end
function endtime(t::Array{Int64,2}, fs::Float64)
  if fs == 0.0
    return t[size(t,1), 2]
  else
    return endtime(t, round(Int64, 1.0/(fs*μs)))
  end
end

"""
    t_extend(T::Array{Int64,2}, t_new::Int64, n_new::Int64, Δ::Int64)

Extend SeisIO time matrix *T* sampled at interval *Δ* μs or frequency *fs* Hz. For matrix *Tᵢ*:
* *t_new* is the start time of the next segment in data vector *Xᵢ*
* *n_new* is the expected number of samples in the next segment of *Xᵢ*

`check_for_gap!` acts as a more specfic case of `t_extend` that operates on a
GphysData structure where `n_new` is known and no time gaps are possible
in the new segment.

This function has a mini-API in the time API (https://github.com/jpjones76/SeisIO.jl/blob/master/docs/DevGuides/time.md).

See Also: check_for_gap!
"""
function t_extend(t::Array{Int64,2}, ts::Integer, nx::Integer, Δ::Int64)
  nt = size(t, 1)
  n0 = 0

  # channel has some data already
  if nt > 0
    n0 = t[nt, 1]
    t0 = endtime(t, Δ)
    if t[nt, 2] == 0
      t = t[1:nt-1,:]
    end
    if nx > 0
      if ts-t0 > 3*div(Δ,2)
        t = vcat(t, [1+n0 ts-t0-Δ; nx+n0 0])
      else
        t = vcat(t, [nx+n0 0])
      end
    else
      t = vcat(t, [1+n0 ts-t0-Δ])
    end
    return t

  # extend t to end at ts (counterintuitive syntax)
  elseif nx == 0
    return mk_t(nx, ts)[1:1,:]

  # behavior for a new channel
  else
    return mk_t(nx, ts)
  end
end
t_extend(T::Array{Int64,2}, ts::Integer, n::Integer, fs::Float64) = t_extend(T, ts, n, round(Int64, 1.0e6/fs))

function t_expand(t::Array{Int64,2}, fs::Float64)
  fs == 0.0 && return t[:,2]
  t[end,1] == 1 && return [t[1,2]]
  dt = round(Int64, 1.0/(fs*μs))
  tt = dt.*ones(Int64, t[end,1])
  tt[1] -= dt
  for i = 1:size(t,1)
    tt[t[i,1]] += t[i,2]
  end
  cumsum!(tt, tt)
  return tt
end

function t_collapse(tt::Array{Int64,1}, fs::Float64)
  if fs == 0.0
    t = hcat(collect(1:1:length(tt)), tt)
  else
    dt = round(Int64, 1.0/(fs*μs))
    ts = Array{Int64,1}([dt; diff(tt)::Array{Int64,1}])
    L = length(tt)
    i = findall(ts .!= dt)
    t = Array{Int64,2}([[1 tt[1]];[i ts[i].-dt]])
    if isempty(i) || i[end] != L
      t = vcat(t, hcat(L,0))
    end
  end
  return t
end

function x_inds(t::Array{Int64,2})
  nt = size(t, 1)-1
  inds = zeros(Int64, nt, 2)
  for i in 1:nt
    inds[i,1] = t[i,1]
    inds[i,2] = t[i+1,1] - (i == nt ? 0 : 1)
  end
  return inds
end

function t_win(T::Array{Int64,2}, Δ::Int64)
  isempty(T) && return(T)
  n = size(T,1)-1
  if T[n+1,2] != 0
    T = vcat(T, [T[n+1,1] 0])
    n += 1
  end
  w0 = -(Δ)
  W = Array{Int64,2}(undef,n,2)
  for i = 1:n
    W[i,1] = T[i,2] + w0 + Δ
    W[i,2] = W[i,1] + Δ*(T[i+1,1]-T[i,1]-1)
    w0 = W[i,2]
  end
  W[n,2] += Δ
  return W
end
t_win(T::Array{Int64,2}, fs::Float64) = t_win(T, round(Int64, 1000000.0/fs))

function w_time(W::Array{Int64,2}, Δ::Int64)
  n = size(W,1)+1
  T = Array{Int64,2}(undef,n,2)
  T[1,1] = Int64(1)
  T[1,2] = W[1,1]
  for i = 2:n-1
    T[i,1] = T[i-1,1] + div(W[i-1,2]-W[i-1,1], Δ) + 1
    T[i,2] = W[i,1] - W[i-1,2] - Δ
  end
  T[n,1] = T[n-1,1] + div(W[n-1,2]-W[n-1,1], Δ)
  T[n,2] = 0
  if T[n,1] == T[n-1,1]
    T = T[1:n-1,:]
  end
  return T
end
w_time(W::Array{Int64,2}, fs::Float64) = w_time(W, round(Int64, 1000000.0/fs))

function unpack_u8(v::UInt8)
  a = signed(div(v,0x10))*Int8(10)
  b = signed(rem(v,0x10))
  return Int64(a+b)
end

function datehex2μs!(a::Array{Int64,1}, datehex::Array{UInt8,1})
  a[1] = 100*unpack_u8(getindex(datehex, 1)) + unpack_u8(getindex(datehex, 2))
  a[2] = md2j(getindex(a,1), unpack_u8(getindex(datehex, 3)), unpack_u8(getindex(datehex, 4))) - 1
  setindex!(a, y2μs(getindex(a,1)), 1)
  a[3] = unpack_u8(getindex(datehex, 5))
  a[4] = unpack_u8(getindex(datehex, 6))
  a[5] = unpack_u8(getindex(datehex, 7))
  a[6] = unpack_u8(getindex(datehex, 8))
  return a[1] + a[2]*86400000000 + a[3]*3600000000 + a[4]*60000000 + a[5]*1000000 + a[6]*10000
end

function tx_float(t::Array{Int64,2}, fs::Float64)
  fs == 0.0 && return map(Float64, t[:,2])
  t[end,1] == 1 && return Float64[t[1,2]]
  Nt = t[end,1]
  dt = 1.0/fs
  tt = dt.*ones(Float64, Nt)
  tt[1] -= dt
  for i = 2:size(t,1)
    tt[t[i,1]] += t[i,2]
  end
  cumsum!(tt, tt)
  return tt
end

function mk_t(nx::Integer, ts::Int64)
  t = Array{Int64, 2}(undef, 2, 2)
  setindex!(t, one(Int64), 1)
  setindex!(t, nx, 2)
  setindex!(t, ts, 3)
  setindex!(t, zero(Int64), 4)
  return t
end

@doc """
    t_arr!(B::Array{Int32,1}, t::Int64)

Convert `t` to [year, day of year, hour, minute, second, frac_second], overwriting the first 6 values in `B` with the result.
""" t_arr!
function t_arr!(tbuf::Array{Int32, 1}, t::Int64)
  dt = u2d(t*μs)
  tbuf[1] = Int32(year(dt))
  tbuf[2] = md2j(tbuf[1], Int32(month(dt)), Int32(day(dt)))
  tbuf[3] = Int32(hour(dt))
  tbuf[4] = Int32(minute(dt))
  tbuf[5] = Int32(second(dt))
  tbuf[6] = Int32(millisecond(dt))
  return nothing
end
