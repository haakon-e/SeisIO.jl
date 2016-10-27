"""
    (i,c,u) = getcodes(b::Char)

Using band code `b`, generate quasi-sane random instrument char code (`i`) and
channel char code (`c`), plus unit string `u`.
"""
function getcodes(b::Char)
  if rand() > 0.2
    # Neglecting gravimeters ('G') and mass position sensors ('M')
    i = rand(['H','L','N'])
    if rand() > 0.1
      c = rand(['Z','N','E'])
    else
      c = rand(['A','B','C','1','2','3','U','V','W'])
    end
    if Base.in(i, ['H','L'])
      u = rand(["m", "m/s"])
    else
      u = "m/s^2"
    end
  else
    i = rand(['A','B','D','F','I','J','K','O','P','Q','R','S','T','U','V','W',
      'Z'])
    if i == 'A' # tiltmeter
      c = rand(['N','E'])
      u = "rad"
    elseif i == 'B' # creep meter
      c = '_'
      u = "m"
      # C is calibration input
    elseif i == 'D' # pressure (barometer, infrasound, hydrophone ∈ 'D')
      c = rand(['O','I','D','F','H','U'])
      u = "Pa"
      # E is an electronic test point
    elseif i == 'F' # magnetometer
      c = rand(['Z','N','E'])
      u = "T"
    elseif i == 'I' # humidity
      c = rand(['O','I','D'])
      u = "%"
    elseif i == 'J' # rotational seismometer
      c = rand(['Z','N','E','A','B','C','T','R','1','2','3','U','V','W'])
      u = rand(["rad", "rad/s", "rad/s^2"])
    elseif i == 'K' # thermal (thermometer or radiometer)
      c = rand(['O', 'I', 'D'])
      u = rand(["C","K"])
    elseif i == 'O' # current gauge
      c = '_'
      u = "m/s"
    elseif i == 'P' # very short-period geophone
      c = rand(['Z','N','E'])
      u = rand(["m", "m/s", "m/s^2"])
    elseif i == 'Q' # voltmeter
      c = '_'
      u = "V"
    elseif i == 'R' # rain gauge
      c = '_'
      u = rand(["m", "m/s"])
    elseif i == 'S' # strain gauge
      c = rand(['Z','N','E'])
      u = "m/m"
    elseif i == 'T' # tide gauge
      c = 'Z'
      u = "m"
    elseif i == 'U' # bolometer
      c = '_'
      u = "(% cloud cover)"
    elseif i == 'V' # volumetric strainmeter
      c = '_'
      u = "m^3/m^3"
    elseif i == 'W' # wind speed ('S') or direction ('D')
      c = rand(['S','D'])
      u = c == 'S' ? "m/s" : "(direction vector)"
      # X, Y are instrument-specific
    elseif i == 'Z' # synthesized beam or stack
      c = rand(['I','C','F','O'])
      u = rand(["m", "m/s", "m/s^2"])
    end
  end
  return i,c,u
end

"""
    populate_chan!(S::SeisChannel)

Populate all empty fields of S with quasi-random values.
"""
function populate_chan!(S::SeisChannel; c=false::Bool)
  fc_vals = [1/120 1/60 1/30 0.2 1.0 1.0 1.0 2.0 4.5 15.0]
  fs_vals = [0.1, 1.0, 2.0, 5.0, 10.0, 20.0, 25.0, 40.0, 50.0, 60.0, 62.5,
    80.0, 100.0, 120.0, 125.0, 250.0]
  bcodes =  ['V', 'L', 'M', 'M',  'B',  'S',  'S',  'S',  'S',  'S',  'S',
    'H',  'S',   'E',   'E',   'C']
  seiscodes = ['H','L','N']
  irregular_units = ["K", "tonnes SO2", "rad", "W", "m"]
  isempty(S.name) && (S.name = randstring(12))                          # name
  (isempty(S.fs) || S.fs == 0 || isnan(S.fs)) && (S.fs = rand(fs_vals))  # fs
  fc = rand(fc_vals[fc_vals .< S.fs/2])

  # An empty ID generates codes and units to match values real data might have
  if isempty(S.id)
    bcode = getbandcode(S.fs)
    (icode,ccode,units) = getcodes(bcode)
    chan = join([bcode, icode, ccode])
    net = uppercase(randstring(2))
    sta = uppercase(randstring(4))
    S.id = join([net,sta,"",chan],'.')                                  # id
  end
  (isempty(S.units) || S.units == "unknown") && (S.units = units)       # units
  (isempty(S.gain) || isnan(S.gain)) && (S.gain = rand()*10^rand(5:10)) # gain
  isempty(S.loc) && (S.loc = [90, 180, 500, 90, 45].*(rand(5)-0.5))     # loc

  # Need this even if S had an ID value when populate_chan! was called
  ccode = split(S.id, '.')[4][2]

  # Random miscellany
  if isempty(S.misc)
    for i = 1:rand(2:12)
      n = rand(1:6)
      n == 1 && (S.misc[randstring(rand(2:12))] = rand(UInt128))
      n == 2 && (S.misc[randstring(rand(3:13))] = rand(Float32))
      n == 3 && (S.misc[randstring(rand(4:14))] = randstring(rand(16:256)))
      if n == 4
        k = randstring(rand(5:15))
        S.misc[k] = Array{Char,2}(rand(6:18),rand(6:18))
      elseif n == 5
        k = randstring(rand(6:16))
        S.misc[k] = rand(Complex{Float64}, tuple(randcycle(rand(2:5))...))
      else
        k = randstring(rand(6:36))
        S.misc[k] = Array{String,2}(rand(2:5),rand(2:5))
        for i = 1:length(S.misc[k])
          S.misc[k][i] = randstring(rand(1:100))
        end
      end
    end
  end

  # A random instrument response function
  if isempty(S.resp)
    if Base.in(ccode,seiscodes)
      i = rand(1:4)
      zstub = zeros(2*i, 1)
      pstub = 10.*rand(i,1)
      S.resp = [complex(zstub) complex([pstub; pstub],[pstub; -pstub])] # resp
    end
  end

  # random noise for data, with random short time gaps; gaussian noise for a
  # time series, uniform noise with a random exponent otherwise
  irreg = false
  if isempty(S.x)                                                       # data
    if c
      p = rand()
      p < 0.1 && (irreg = true)
    end
    L = rand(0:9)
    ts = time()-86400+randn()                                           # time
    Lx = ceil(Int, S.fs)*(2^rand(8:12))
    if irreg
      L+=2
      S.x = rand(L) .* 10.^(rand(1:10, L))
      t = [round(Int,ts/μs); round(Int, diff(sort(rand(2:Lx, L)))/(μs*S.fs))]
      S.t = reshape(t, L, 1)
      S.fs = 0
      S.units = rand(irregular_units)
    else
      S.x = randn(Lx)
      t = zeros(2+L, 2)
      t[1,:] = [1 round(Int, ts/μs)]
      t[2:L+1,:] = [rand(2:Lx, L, 1) round(Int, rand(L,1)./μs)]
      t[L+2,:] = [Lx 0]
      S.t = sortrows(t)
    end
  end
  note(S, "Created by function populate_chan!.")
  return S
end

"""
    randseischa()

Generate a random channel of seismic data as a SeisChannel.

"""
randseischa(; c=false::Bool) = (S = populate_chan!(SeisChannel(), c=c); return S)

"""
    populate_seis!(S::SeisData)

Fill empty fields of S with random data.

    populate_seis!(S::SeisData, n=N)

Add N channels of random data to S.

    populate_seis!(S::SeisData, n=N, c=true)

Add "c=true" to either function call to allow random channels of non-timeseries
data (i.e. `c`ampaign channels, with no definable Fs).
"""
function populate_seis!(S::SeisData; c=false::Bool)
  for j = 1:1:S.n
    eflag = false
      for i in datafields(S)
        if isempty(S.(i)[j])
          eflag = true
        end
      end
    if eflag
      T = S[j]
      populate_chan!(T, c=c)
      S[j] = T
    end
  end
end
populate_seis!(S::SeisData, N::Int; c=false::Bool) = ([push!(S,
  randseischa(c=c)) for n = 1:N])

"""
    randseisdata()

Generate 8 to 24 channels of random seismic data as a SeisData object.

    randseisdata(N)

Generate N channels of random seismic data as a SeisData object.
"""
randseisdata(; c=false::Bool) = (S = SeisData();
  populate_seis!(S, rand(8:24), c=c); return S)
randseisdata(i::Int; c=false::Bool) = (S = SeisData();
  populate_seis!(S, i, c=c); return S)

function randseishdr()
  H = SeisHdr(id = rand(1:2^62), time=now(),
  lat=(rand(0:1:89)+rand())*-1^(rand(1:2)),
  lon=(rand(0:1:179)+rand())*-1^(rand(1:2)),
  dep=abs(100*randn()),
  mag=rand()*6,
  mag_auth=randstring(rand(2:8)),
  mag_typ=randstring(rand(2:4)),
  auth=randstring(rand(2:12)),
  cat=randstring(rand(2:12)),
  contrib=randstring(rand(2:12)),
  contrib_id = rand(1:2^62),
  loc_name=randstring(rand(8:24)))
end

function randseisevent(; c=false::Bool)
  D = SeisData()
  populate_seis!(D, rand(8:24), c=c)
  return SeisEvent(hdr=randseishdr(), data=D)
end