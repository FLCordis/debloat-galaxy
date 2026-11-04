# Le o mapa de UIDs e depois a saida de dumpsys batterystats --charged.
function seg(s,  n,i,t,v,p){ t=0; n=split(s,p," "); for(i=1;i<=n;i++){ v=p[i]+0; if(p[i]~/ms$/)t+=v/1000; else if(p[i]~/d$/)t+=v*86400; else if(p[i]~/h$/)t+=v*3600; else if(p[i]~/m$/)t+=v*60; else if(p[i]~/s$/)t+=v } return t }
function hm(t,  h,m){ h=int(t/3600); m=int((t-h*3600)/60); return (h?h"h ":"") m"min" }
function mb(s,  v){ gsub(/,/,".",s); v=s+0; if(s~/GB/)return v*1024; if(s~/MB/)return v; if(s~/KB/)return v/1024; return v/1048576 }
function chave(u,  k){ if(u~/^u0a/){k=10000+substr(u,4)} else if(u~/^[0-9]+$/){k=u+0} else k=u; return k }
function nome(u,  k){
  k=chave(u)
  if(k in pacote) return pacote[k] ((k in comp)?" (+"comp[k]" no mesmo UID)":"")
  if(k in aid) return "["aid[k]"]"
  return "[uid "k"]"
}
function compartilhado(u){ return (chave(u) in comp) }
function tempo_em(l,tag,  r,i){ i=index(l,tag); if(!i)return ""; r=substr(l,i+length(tag)); sub(/ (realtime|\().*$/,"",r); return r }
# Imprime os N maiores de v, usando rot como rotulo e ext como detalhe.
function topo(v,rot,ext,N,fmt,  m,mx,k,j,u){
  for(j=1;j<=N;j++){ mx=0; m=""; for(k in v) if(!(k in u)&&v[k]>mx){mx=v[k];m=k} if(m=="")break; u[m]=1; printf fmt, mx, rot[m], ext[m] }
}
BEGIN{
  aid[0]="kernel"; aid[1000]="sistema Android"; aid[1001]="telefonia"; aid[1002]="bluetooth"; aid[1010]="wifi"; aid[1013]="midia"
  aid[1041]="audio"; aid[1046]="codec de video"; aid[1047]="camera"; aid[1051]="DNS"; aid[1052]="DNS tether"; aid[1073]="rede"; aid[2000]="adb"
}
FNR==NR{
  if(match($0,/uid:[0-9]+/)){ k=substr($0,RSTART+4,RLENGTH-4)+0; pk=$1; sub(/^package:/,"",pk); if(k in pacote){comp[k]++} else pacote[k]=pk }
  next
}
/Time on battery:/ && !bat { bat=seg(tempo_em($0,"battery: ")) }
/Time on battery screen off:/{ s=$0; sub(/^.*screen off: /,"",s); r=s; sub(/ \(.*/,"",r); deslig=seg(r); u=s; sub(/^.*realtime, /,"",u); sub(/ \(.*/,"",u); desligup=seg(u) }
/^ *Discharge: /{ desc=$2+0 }
/Screen off discharge: /{ descoff=$(NF-1)+0 }
/Screen on discharge: /{ descon=$(NF-1)+0 }
/Device deep doze discharge: /{ deep=$(NF-1)+0 }
/Device light doze discharge: /{ light=$(NF-1)+0 }
/^ *Start clock time: /{ inicio=$NF }
/^ *Screen on: /{ s=$0; sub(/^.*Screen on: /,"",s); sub(/ \(.*/,"",s); telaon=seg(s) }
/Total partial wakelock time: /{ s=$0; sub(/^.*time: /,"",s); wlt=seg(s) }
/Connectivity changes: /{ conect=$NF }
/^ *Bluetooth scan time: /{ s=$0; sub(/^.*time: /,"",s); bts=seg(s) }
/^ *Wifi data received: /{ wrx=mb($NF) }
/^ *Wifi data sent: /{ wtx=mb($NF) }
/^ *Cellular data received: /{ crx=mb($NF) }
/^ *Cellular data sent: /{ ctx=mb($NF) }
/Amount discharged while screen off: /{ pctoff=$NF+0 }
/Amount discharged while screen on: /{ pcton=$NF+0 }
/Capacity: .*Computed drain/{ s=$0; sub(/^.*actual drain: /,"",s); real=s+0; if($0~/Capacity: [0-9]+/){c=$0; sub(/^.*Capacity: /,"",c); cap=c+0} }
/^  Estimated power use/{ est=1; glob=1; next }
est && glob && /^    [a-z_]+: /{ somaglob+=$2+0; next }
est && /^      \(/{ glob=0 }
# Sobre todos os apps, com tela desligada
/^  UID [^ ]+: [0-9.]+/{
  u=$2; sub(/:$/,"",u); uid=u; tot[u]=$3+0; rot[u]=nome(u)
  fg[u]=bg[u]=fgs[u]=0
  for(i=4;i<=NF;i++){ if($i=="fg:")fg[u]=$(i+1)+0; if($i=="bg:")bg[u]=$(i+1)+0; if($i=="fgs:")fgs[u]=$(i+1)+0 }
  ext[u]=sprintf("primeiro plano %.0f, fundo %.0f, servico %.0f", fg[u], bg[u], fgs[u])
  next
}
/^      \(on battery, screen off\/doze\)/ && uid!=""{
  o=0; n=split($0,p," ")
  for(i=1;i<=n;i++){ if(p[i]~/^(cpu|mobile_radio|wakelock|gnss)=/){ x=p[i]; sub(/^[^=]*=/,"",x); o+=x+0 } }
  off[uid]=o; offrot[uid]=rot[uid]; offext[uid]=""; next
}
# Blocos por UID
/^  (u0a[0-9]+|[0-9]+):$/{ b=$1; sub(/:$/,"",b); next }
/^  [A-Za-z]/{ b="" }
b!="" && /Wi-Fi network: /{ s=$0; sub(/^.*network: /,"",s); split(s,p," received, "); r=p[1]; t=p[2]; sub(/ .*/,"",t); nw[b]+=mb(r)+mb(t); nrot[b]=nome(b) }
b!="" && /Mobile network: /{ s=$0; sub(/^.*network: /,"",s); split(s,p," received, "); r=p[1]; t=p[2]; sub(/ .*/,"",t); nw[b]+=mb(r)+mb(t); nm[b]+=mb(r)+mb(t); nrot[b]=nome(b) }
b!="" && /Bluetooth Scan \(total actual realtime\): /{ s=$0; sub(/^.*realtime\): /,"",s); sub(/ *\(.*/,"",s); bt[b]=seg(s); btrot[b]=nome(b) }
b!="" && /^ +Job [^C]/ && / realtime \(/{
  s=$0; sub(/^ +Job /,"",s); i=index(s,": "); nm2=substr(s,1,i-1); r=substr(s,i+2); c=r; sub(/ realtime.*/,"",r); sub(/^.*realtime \(/,"",c); sub(/ times.*/,"",c)
  gsub(/\/@eM_ADDR\/androidx.work.impl.background.systemjob.SystemJobService/,"",nm2)
  id=b"|"nm2; job[id]=seg(r); jrot[id]=nome(b); jext[id]=nm2" ("c"x)"
}
b!="" && /Wakeup alarm /{ s=$0; if(match(s,/: [0-9]+ times/)){ al[b]+=substr(s,RSTART+2)+0; arot[b]=nome(b) } }
# Listas globais
/All partial wake locks:/{ wl=1; next }
/All wakeup reasons:/{ wr=1; wl=0; next }
wl && /^  Wake lock /{
  s=$0; sub(/^  Wake lock /,"",s); u=s; sub(/ .*/,"",u); r=s; sub(/^[^ ]+ /,"",r); i=index(r,": "); nm2=substr(r,1,i-1); t=substr(r,i+2); sub(/ (\(|realtime).*/,"",t)
  gsub(/\/@eM_ADDR\/androidx.work.impl.background.systemjob.SystemJobService/,"",nm2)
  gsub(/androidx.work.impl.background.systemjob.SystemJobService/,"",nm2)
  if(wln<12){ wln++; wlv[wln]=seg(t); wll[wln]=nome(u); wlx[wln]=nm2 } next
}
wl && !/^  Wake lock /{ wl=0 }
wr && /^  Wakeup reason /{ if(wrn<6){ wrn++; s=$0; sub(/^  Wakeup reason /,"",s); wrl[wrn]=s } next }
wr && !/^  Wakeup reason /{ wr=0 }
END{
  printf "Desde a ultima carga completa. Relogio do Android: %s (depois de reiniciar, mostra o reinicio)\n", inicio
  printf "Fora da tomada: %s\n", hm(bat)
  printf "Gasto total: %d mAh, de uma bateria de %d mAh\n", desc, cap
  printf "Tela ligada: %s, %d mAh (%d%% da bateria)\n", hm(telaon), descon, pcton
  if(deslig>0) printf "Tela desligada: %s, %d mAh (%d%% da bateria), cerca de %.1f%% por hora\n", hm(deslig), descoff, pctoff, pctoff/(deslig/3600)
  if(deslig>0) printf "CPU acordada com a tela desligada: %s, %d%% do tempo\n", hm(desligup), desligup*100/deslig
  printf "Doze: leve %d mAh, profundo %d mAh\n", light, deep
  printf "Wake locks parciais: %s. Varredura Bluetooth: %s. Mudancas de conectividade: %s\n", hm(wlt), hm(bts), conect
  printf "Dados: Wi-Fi %.0f MB, celular %.0f MB\n", wrx+wtx, crx+ctx
  if(real>0) printf "Nao atribuido a nenhum componente: %d%% (%d de %d mAh)\n", (real-somaglob)*100/real, real-somaglob, real
  print "Atencao: mAh de UID compartilhado e a soma do grupo inteiro, nao de um pacote so."
  print "\n-- Top 15 por consumo estimado (mAh)"; topo(tot,rot,ext,15,"%7.1f  %s: %s\n")
  print "\n-- Top 12 com tela desligada (mAh de CPU, radio, wake lock e GPS)"; topo(off,offrot,offext,12,"%7.1f  %s%s\n")
  print "\n-- Top 10 por dados (MB)"; topo(nw,nrot,nmv,10,"%8.0f  %s%s\n")
  print "\n-- Top 12 wake locks parciais"; for(i=1;i<=wln;i++) printf "%7.1f min  %s: %s\n", wlv[i]/60, wll[i], substr(wlx[i],1,70)
  print "\n-- Top 8 tarefas em segundo plano (min)"; for(k in job) jmin[k]=job[k]/60; topo(jmin,jrot,jext,8,"%7.1f min  %s: %s\n")
  print "\n-- Top 8 varredura Bluetooth, tempo real (min)"; for(k in bt) btm[k]=bt[k]/60; topo(btm,btrot,btx,8,"%7.1f min  %s%s\n")
  print "\n-- Top 8 alarmes que acordam (vezes)"; topo(al,arot,alx,8,"%7d  %s%s\n")
  print "\n-- Motivos para acordar ou nao dormir"; for(i=1;i<=wrn;i++) print "  " substr(wrl[i],1,110)
}
