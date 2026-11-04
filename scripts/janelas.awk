# Le dumpsys batterystats --history e acha os periodos fora da tomada com a tela desligada.
# Toques curtos na tela (menos de 2 minutos) nao quebram o periodo. Assim a noite aparece sozinha.
function t(d,h,  m,a,x,dia,c){
  split("0 31 59 90 120 151 181 212 243 273 304 334",a," ")
  split(d,m,"-"); split(h,x,":")
  dia=a[m[1]+0]+m[2]
  return dia*86400+x[1]*3600+x[2]*60+x[3]
}
function hm(s,  h,m){ h=int(s/3600); m=int((s-h*3600)/60); return (h?h"h ":"") m"min" }
function fecha(fim,lvl,  d){
  if(!em) return
  d=fim-ini
  if(d>=1800){ n++; jd[n]=d; ji[n]=rotini; jf[n]=rotfim; jl1[n]=lini; jl2[n]=lvl; jb[n]=toques; jo[n]=ligada }
  em=0
}
function abre(r,tm,lvl){ em=1; ini=tm; lini=lvl; rotini=r; toques=0; ligada=0 }
$3 !~ /^[0-9][0-9][0-9]$/ { next }
{
  agora=t($1,$2); lvl=$3+0; rot=$1" "substr($2,1,5); ult=agora; ultl=lvl; ultr=rot
  for(i=4;i<=NF;i++){
    if($i ~ /^plug=/){
      novo=$i; sub(/^plug=/,"",novo)
      if(novo!=plug){
        if(novo!="none"){ rotfim=rot; fecha(agora,lvl) }
        else if(tela==0) abre(rot,agora,lvl)
        plug=novo
      }
    }
    else if($i=="+screen"){ tela=1; lig=agora; llig=lvl; rlig=rot }
    else if($i=="-screen"){
      dur=agora-lig
      tela=0
      if(em && lig>0 && dur<120){ toques++; ligada+=dur }
      else {
        if(em){ rotfim=rlig; fecha(lig,llig) }
        if(plug=="none") abre(rot,agora,lvl)
      }
    }
  }
}
END{
  if(em){ rotfim=ultr" (ainda em curso)"; fecha(ult,ultl) }
  if(!n){ print "nenhum periodo de 30 minutos ou mais fora da tomada com a tela desligada"; exit }
  for(i=1;i<=n;i++){
    q=jl1[i]-jl2[i]
    printf "%s ate %s: %s, de %d%% para %d%%, %.1f%% por hora, %d toques curtos na tela\n", ji[i], jf[i], hm(jd[i]), jl1[i], jl2[i], q/(jd[i]/3600), jb[i]
  }
}
