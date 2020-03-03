using Dates, DSP, HDF5, Logging, Printf, SeisIO, Test
using SeisIO.FastIO, SeisIO.Quake, SeisIO.RandSeis, SeisIO.SeisHDF
import Dates: DateTime, Hour, now
import DelimitedFiles: readdlm
import Random: rand, randperm, randstring
import SeisIO: BUF,
  KW,
  FDSN_sta_xml,
  TimeSpec,
  auto_coords,
  bad_chars,
  buf_to_double,
  checkbuf!,
  checkbuf_8!,
  code2resptyp,
  code2typ,
  datafields,
  datareq_summ,
  diff_x!,
  endtime,
  fillx_i16_le!,
  fillx_i32_be!,
  fillx_i32_le!,
  findhex,
  formats,
  get_http_post,
  get_http_req,
  get_views,
  ibmfloat,
  int2tstr,
  int_x!,
  mean,
  minreq!,
  mk_t!,
  mk_t,
  mktaper!,
  mktime,
  nx_max,
  parse_charr,
  parse_chstr,
  parse_sl,
  poly,
  polyfit,
  polyval,
  read_sacpz!,
  read_sacpz,
  read_seed_resp!,
  read_station_xml!,
  read_station_xml,
  read_sxml,
  resptyp2code,
  safe_isdir,
  safe_isfile,
  sμ,
  t_arr!,
  t_collapse,
  t_expand,
  t_extend,
  t_win,
  taper_seg!,
  tnote,
  trid,
  tstr2int,
  typ2code,
  w_time,
  webhdr,
  xtmerge!,
  μs
import SeisIO.RandSeis: getyp2codes, pop_rand_dict!
import SeisIO.Quake: unsafe_convert
import SeisIO.SeisHDF:read_asdf, read_asdf!, id_match, id_to_regex
import Statistics: mean
