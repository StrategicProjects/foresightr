# Run from this folder: python3 make.py writes architecture.svg and backtest.svg;
# copy them to man/figures, vignettes (backtest-diagram.svg) and to pyforesight.
# Two diagrams shared by the R and Python packages.
INK="#1f2430"; MUTED="#5d6478"; BRAND="#5b43d6"; TEAL="#1a9e84"; FAINT="#e7e9f0"
BG="#ffffff"; CARD="#f6f7fb"; LINE="#d9deea"; AMBER="#d98a00"
FONT="font-family=\"Inter, 'Segoe UI', system-ui, -apple-system, Helvetica, Arial, sans-serif\""
MONO="font-family=\"ui-monospace, SFMono-Regular, Menlo, Consolas, monospace\""

from xml.sax.saxutils import escape
def text(x,y,s,size=14,fill=INK,weight=400,anchor="start",mono=False,extra=""):
    f=MONO if mono else FONT
    s=escape(s)
    return f'<text x="{x}" y="{y}" {f} font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}" {extra}>{s}</text>'

def box(x,y,w,h,fill=BG,stroke=LINE,r=12,sw=1.5,dash=""):
    d=f' stroke-dasharray="{dash}"' if dash else ""
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}/>'

def arrow(x1,y1,x2,y2,color=MUTED,dash="",sw=1.8):
    d=f' stroke-dasharray="{dash}"' if dash else ""
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{sw}"{d} marker-end="url(#tip)"/>'

def svg(w,h,body,title,desc):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" aria-labelledby="t d">
  <title id="t">{title}</title>
  <desc id="d">{desc}</desc>
  <defs>
    <marker id="tip" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" fill="{MUTED}"/>
    </marker>
    <linearGradient id="core" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#f1eeff"/><stop offset="1" stop-color="#e9f8f4"/>
    </linearGradient>
  </defs>
  <rect x="0.75" y="0.75" width="{w-1.5}" height="{h-1.5}" rx="18" fill="{BG}" stroke="{LINE}" stroke-width="1.5"/>
{body}
</svg>
'''

# ------------------------------------------------------------ architecture
W,H=1000,600
b=[]
b.append(text(40,52,"How the packages fit together",22,INK,700))
b.append(text(40,78,"One implementation in Rust; R and Python call it, so the numbers are the same everywhere.",14,MUTED))
# users row
users=[("R","foresightr","extendr · ts in, data frames out","library(foresightr)"),
       ("Python","pyforesight","PyO3 · prebuilt wheels","import foresight as fs"),
       ("Rust","foresight","any Rust program","cargo add foresight")]
ux=[40,265,490]; uw=205; uy=110; uh=108
for (lang,name,how,code),x in zip(users,ux):
    b.append(box(x,uy,uw,uh))
    b.append(text(x+18,uy+30,lang.upper(),11,BRAND,700,extra='letter-spacing="1.2"'))
    b.append(text(x+18,uy+54,name,18,INK,700))
    b.append(text(x+18,uy+75,how,12.5,MUTED))
    b.append(text(x+18,uy+96,code,12,INK,mono=True))
    b.append(arrow(x+uw/2,uy+uh,x+uw/2,uy+uh+44))
# go: an independent port, beside the callers
gx,gw=735,225
b.append(box(gx,uy,gw,uh,dash="6 5"))
b.append(text(gx+18,uy+30,"GO",11,TEAL,700,extra='letter-spacing="1.2"'))
b.append(text(gx+18,uy+54,"foresight-go",18,INK,700))
b.append(text(gx+18,uy+75,"the same methods, rewritten",12.5,MUTED))
b.append(text(gx+18,uy+94,"in pure Go",12.5,MUTED))
b.append(arrow(gx+gw/2,uy+uh,gx+gw/2,uy+uh+44,dash="5 5"))
b.append(text(gx+gw/2+10,uy+uh+28,"checked against it",11,MUTED))
# core
cx,cy,cw,ch=40,262,920,220
b.append(box(cx,cy,cw,ch,fill="url(#core)",stroke=BRAND,sw=2))
b.append(text(cx+22,cy+36,"foresight",21,INK,700))
b.append(text(cx+122,cy+36,"— the Rust crate: every computation, zero dependencies, deterministic",14,MUTED))
chips=[("Models","Naive · Theta · Holt-Winters","ARIMA · ETS · Prophet · TBATS","Croston · ensembles · Box-Cox"),
       ("Backtest","rolling origin on all cores","error by horizon and the choice","empirical intervals and totals"),
       ("Decomposition","STL and MSTL","forecasts of the seasonally","adjusted series"),
       ("Cleaning and tests","gaps and outliers","KPSS · differences","seasonal strength · accuracy")]
gap=12; qw=(cw-44-3*gap)/4; qh=132; qx0=cx+22; qy=cy+62
for i,(t,a1,c1,d1) in enumerate(chips):
    x=qx0+i*(qw+gap)
    b.append(box(x,qy,qw,qh,fill=BG,stroke=LINE,r=10,sw=1.2))
    b.append(text(x+16,qy+30,t,14.5,BRAND if i!=1 else TEAL,700))
    for j,l in enumerate([a1,c1,d1]):
        b.append(text(x+16,qy+60+j*22,l,12.5,INK))
# checks row
ky=522
b.append(text(40,ky,"CHECKED",11,MUTED,700,extra='letter-spacing="1.2"'))
b.append(text(40,ky+24,"Against the R packages forecast 9.0.2 and prophet 1.1.7 on public data, and in every package against the",13,INK))
b.append(text(40,ky+45,"results recorded by the crate: likelihoods, forecasts, choices and intervals.",13,INK))
open("architecture.svg","w").write(svg(W,H,"\n".join("  "+x for x in b),
  "Architecture of foresight",
  "The Rust crate foresight holds every model, the backtest, decomposition and cleaning. The R package foresightr (extendr) and the Python package pyforesight (PyO3) call it; Rust programs use it directly. foresight-go is an independent Go port checked against results recorded by the crate. The crate is checked against the R packages forecast and prophet."))

# ------------------------------------------------------------ backtest
W,H=1000,620
b=[]
b.append(text(40,52,"How a model is chosen",22,INK,700))
b.append(text(40,78,"Every candidate is refitted at every origin with the data before it, and judged on what came next.",14,MUTED))
# rolling origin grid
gx0,gy0=40,112
b.append(text(gx0,gy0,"1  Replay the past",15,INK,700))
cell,gapc=15,3; ncol=24; horizon=4; rows=6
for r in range(rows):
    y=gy0+22+r*(cell+10)
    origin=13+r*2
    for c in range(ncol):
        x=gx0+c*(cell+gapc)
        if c<origin: col=INK; op=0.85
        elif c<origin+horizon: col=BRAND; op=1
        else: col=FAINT; op=1
        b.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" rx="3" fill="{col}" opacity="{op}"/>')
    b.append(text(gx0+ncol*(cell+gapc)+6,y+12,f"origin {r+1}",11.5,MUTED))
ly=gy0+22+rows*(cell+10)+14
b.append(f'<rect x="{gx0}" y="{ly}" width="12" height="12" rx="3" fill="{INK}" opacity="0.85"/>')
b.append(text(gx0+18,ly+11,"data used to fit",12,MUTED))
b.append(f'<rect x="{gx0+140}" y="{ly}" width="12" height="12" rx="3" fill="{BRAND}"/>')
b.append(text(gx0+158,ly+11,"forecast, 1 to h periods ahead",12,MUTED))
# errors
ex=560; ey=gy0
b.append(arrow(gx0+ncol*(cell+gapc)+70,gy0+90,ex-14,gy0+90))
b.append(text(ex,ey,"2  Measure the errors",15,INK,700))
b.append(box(ex,ey+18,400,150,fill=CARD))
hs=[("h = 1",3.2),("h = 2",3.6),("h = 3",4.0),("h = 4",4.3)]
for i,(lab,v) in enumerate(hs):
    y=ey+38+i*26
    b.append(text(ex+18,y+11,lab,12,MUTED,mono=True))
    b.append(f'<rect x="{ex+80}" y="{y}" width="{v*50:.0f}" height="14" rx="4" fill="{BRAND}" opacity="{0.45+0.12*i:.2f}"/>')
    b.append(text(ex+88+v*50,y+11,f"{v:.1f}%",11.5,MUTED))
b.append(text(ex+18,ey+156,"MAPE, bias, MAE, RMSE and MASE, by horizon",12,MUTED))
# outputs
oy=350
rx=40+260
b.append(arrow(ex+60,ey+172,rx+60,oy-16))
b.append(arrow(ex+200,ey+172,ex+200,oy-16))
# ranking
rx=40+260
b.append(text(rx-260,oy+6,"3  Choose",15,INK,700))
b.append(box(rx-260,oy+20,470,182,fill=CARD))
cand=[("mean(best two)",3.4,True),("log ARIMA",3.7,False),("ARIMA",3.9,False),("Prophet",5.5,False),("seasonal naive",11.5,False)]
for i,(n,v,ch) in enumerate(cand):
    y=oy+40+i*28
    b.append(text(rx-242,y+11,n,12.5,INK,600 if ch else 400))
    b.append(f'<rect x="{rx-110}" y="{y}" width="{v*20:.0f}" height="15" rx="4" fill="{BRAND if ch else "#c9cddb"}"/>')
    b.append(text(rx-104+v*20,y+12,f"{v:.1f}",11.5,MUTED))
b.append(text(rx-242,oy+190,"The average of the best models competes too.",11.5,MUTED))
# intervals
ix=ex
b.append(text(ix,oy+6,"4  Take the intervals from the errors",15,INK,700))
b.append(box(ix,oy+20,400,182,fill=CARD))
import math
x0,y0=ix+24,oy+140
pts=[(x0+i*11,y0-8*math.sin(i/1.7)-i*2) for i in range(11)]
hist=" ".join(f"{x:.0f},{y:.0f}" for x,y in pts)
fx=[pts[-1][0]+i*14 for i in range(0,9)]
fm=[pts[-1][1]-i*2.6-6*math.sin((10+i)/1.7)+6*math.sin(10/1.7) for i in range(9)]
def band(k): 
    up=[(x,m-k*math.sqrt(i)*9) for i,(x,m) in enumerate(zip(fx,fm))]
    lo=[(x,m+k*math.sqrt(i)*9) for i,(x,m) in enumerate(zip(fx,fm))]
    return " ".join(f"{x:.0f},{y:.0f}" for x,y in up+lo[::-1])
b.append(f'<polygon points="{band(1.9)}" fill="{BRAND}" opacity="0.16"/>')
b.append(f'<polygon points="{band(1.1)}" fill="{BRAND}" opacity="0.32"/>')
b.append(f'<polyline points="{hist}" fill="none" stroke="{INK}" stroke-width="2.2" stroke-linejoin="round"/>')
b.append(f'<polyline points="{" ".join(f"{x:.0f},{y:.0f}" for x,y in zip(fx,fm))}" fill="none" stroke="{BRAND}" stroke-width="2.6" stroke-linejoin="round"/>')
b.append(text(ix+262,oy+62,"80% · 95%",12,BRAND,700))
b.append(text(ix+262,oy+84,"quantiles of the",12,MUTED))
b.append(text(ix+262,oy+102,"relative errors,",12,MUTED))
b.append(text(ix+262,oy+120,"horizon by horizon,",12,MUTED))
b.append(text(ix+262,oy+138,"and of totals",12,MUTED))
b.append(text(ix+262,oy+156,"of the next k",12,MUTED))
b.append(text(ix+262,oy+174,"periods",12,MUTED))
b.append(text(40,H-26,"No information criterion decides, and no distribution is assumed: both the choice and the intervals come from forecasts made without seeing the answer.",12.5,MUTED))
open("backtest.svg","w").write(svg(W,H,"\n".join("  "+x for x in b),
  "How foresight chooses a model",
  "1: at each of the last origins every candidate is fitted on the data before it and forecasts 1 to h periods ahead. 2: the errors are measured by horizon. 3: the candidates, and the average of the best, are ranked by their error and the best is chosen. 4: the intervals are quantiles of the relative errors, by horizon and for totals."))
