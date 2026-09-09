import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch
import os

plt.rcParams['font.family'] = 'Consolas'
plt.rcParams['font.size'] = 9

BG = '#1a1a2e'
CPU = '#4A90D9'
BUS = '#E8A838'
MEM = '#5CB85C'
PER = '#D9534F'
IO = '#9B59B6'

def box(ax, x, y, w, h, color, label, sub=None, fs=9, alpha=0.85):
    ax.add_patch(FancyBboxPatch((x,y),w,h,boxstyle="round,pad=0.008",facecolor=color,edgecolor='none',alpha=alpha))
    if sub:
        ax.text(x+w/2, y+h/2+0.015, label, ha='center', va='center', color='white', fontsize=fs, fontweight='bold')
        ax.text(x+w/2, y+h/2-0.02, sub, ha='center', va='center', color='#ddd', fontsize=fs-2)
    else:
        ax.text(x+w/2, y+h/2, label, ha='center', va='center', color='white', fontsize=fs, fontweight='bold')

def arrow(ax, x1,y1,x2,y2, c=BUS):
    ax.annotate('',xy=(x2,y2),xytext=(x1,y1),arrowprops=dict(arrowstyle='->',color=c,lw=1.5))

# ===== ARCHITECTURE =====
fig,ax = plt.subplots(figsize=(16,10),facecolor=BG)
ax.set_facecolor(BG); ax.set_xlim(0,1); ax.set_ylim(0,1); ax.axis('off')
ax.text(0.5,0.97,'Advanced FPGA SoC — System Architecture',ha='center',va='top',color='white',fontsize=16,fontweight='bold')
ax.text(0.5,0.94,'Basys 3 (Artix-7 XC7A35T) | 100MHz | RISC-V RV32I Pipeline',ha='center',va='top',color='#888',fontsize=10)

ax.add_patch(FancyBboxPatch((0.02,0.62),0.96,0.28,boxstyle="round,pad=0.01",facecolor='none',edgecolor=CPU,lw=2))
ax.text(0.04,0.88,'5-STAGE PIPELINE CPU',color=CPU,fontsize=11,fontweight='bold')
stages=['IF\nFetch','ID\nDecode','EX\nExecute','MEM\nAccess','WB\nWriteBack']
subs=['PC, IMem','RegFile, Ctrl','ALU, Fwd','Load/Store','Reg Write']
sx=[0.04,0.22,0.40,0.58,0.76]
for i,(l,s) in enumerate(zip(stages,subs)):
    box(ax,sx[i],0.72,0.15,0.12,CPU,l,s,fs=9)
    if i<4: arrow(ax,sx[i]+0.15,0.78,sx[i+1],0.78,CPU)
box(ax,0.22,0.64,0.15,0.05,'#2C5F8A','Hazard Detection',fs=8)
box(ax,0.40,0.64,0.15,0.05,'#2C5F8A','Forwarding Unit',fs=8)

ax.add_patch(FancyBboxPatch((0.02,0.50),0.96,0.08,boxstyle="round,pad=0.008",facecolor=BUS,edgecolor='none',alpha=0.9))
ax.text(0.5,0.54,'WISHBONE BUS  |  32-bit Addr  |  32-bit Data  |  Byte-Enable',ha='center',color='white',fontsize=10,fontweight='bold')
arrow(ax,0.5,0.62,0.5,0.58,BUS)

ax.add_patch(FancyBboxPatch((0.02,0.28),0.35,0.18,boxstyle="round,pad=0.01",facecolor='none',edgecolor=MEM,lw=1.5))
ax.text(0.04,0.44,'MEMORY SUBSYSTEM',color=MEM,fontsize=10,fontweight='bold')
box(ax,0.04,0.32,0.14,0.09,MEM,'Instruction\nMemory','1KB ROM',fs=8)
box(ax,0.20,0.32,0.14,0.09,MEM,'Data\nMemory','1KB RAM',fs=8)
arrow(ax,0.18,0.50,0.18,0.47,BUS)

ax.add_patch(FancyBboxPatch((0.40,0.28),0.58,0.18,boxstyle="round,pad=0.01",facecolor='none',edgecolor=PER,lw=1.5))
ax.text(0.42,0.44,'PERIPHERALS',color=PER,fontsize=10,fontweight='bold')
for i,(n,x) in enumerate(zip(['UART\nFIFO','Timer\n32-bit','GPIO\n16-bit','IntCtrl\n8-Src'],[0.42,0.57,0.72,0.87])):
    box(ax,x,0.32,0.12,0.09,PER,n,fs=8)
arrow(ax,0.7,0.50,0.7,0.47,BUS)

ax.add_patch(FancyBboxPatch((0.02,0.08),0.96,0.15,boxstyle="round,pad=0.01",facecolor='none',edgecolor=IO,lw=1.5))
ax.text(0.04,0.21,'BOARD I/O',color=IO,fontsize=10,fontweight='bold')
for n,x in zip(['7-Seg','LED','Switch','UART','Buttons','Clock'],[0.04,0.20,0.36,0.52,0.68,0.84]):
    box(ax,x,0.10,0.13,0.08,IO,n,fs=8)
arrow(ax,0.5,0.28,0.5,0.23,BUS)

ax.legend(handles=[mpatches.Patch(color=CPU,label='CPU'),mpatches.Patch(color=BUS,label='Bus'),
    mpatches.Patch(color=MEM,label='Memory'),mpatches.Patch(color=PER,label='Peripherals'),
    mpatches.Patch(color=IO,label='I/O')],loc='lower center',ncol=5,fontsize=8,
    facecolor='#222244',edgecolor='#444',labelcolor='#aaa',bbox_to_anchor=(0.5,-0.02))
plt.tight_layout()
base='C:/Users/sohan/Downloads/sih hacathon sohan/fpga-soc-project/docs/images'
plt.savefig(f'{base}/architecture.png',dpi=150,bbox_inches='tight',facecolor=BG); plt.close()
print("architecture.png OK")

# ===== PIPELINE =====
fig,ax = plt.subplots(figsize=(14,7),facecolor=BG)
ax.set_facecolor(BG); ax.set_xlim(0,1); ax.set_ylim(0,1); ax.axis('off')
ax.text(0.5,0.97,'5-Stage Pipeline — Instruction Flow',ha='center',va='top',color='white',fontsize=16,fontweight='bold')
ax.text(0.5,0.93,'Hazard Detection + Data Forwarding | Branch at EX',ha='center',va='top',color='#888',fontsize=10)
for i in range(5): ax.text(0.15+i*0.17,0.87,f'Cycle {i+1}',ha='center',color='#666',fontsize=9)
ic=['#3498DB','#2ECC71','#E67E22','#9B59B6','#1ABC9C']
for row in range(5):
    y=0.78-row*0.12
    ax.text(0.06,y+0.02,f'I{row+1}',ha='center',color=ic[row],fontsize=10,fontweight='bold')
    for col in range(5-row):
        x=0.10+(col+row)*0.17
        ax.add_patch(FancyBboxPatch((x,y-0.03),0.13,0.07,boxstyle="round,pad=0.005",facecolor=ic[row],edgecolor='none',alpha=0.85))
        ax.text(x+0.065,y+0.005,['IF','ID','EX','MEM','WB'][col],ha='center',va='center',color='white',fontsize=9,fontweight='bold')
for col in range(4):
    x=0.10+(col+1)*0.17-0.015
    ax.plot([x,x],[0.75,0.28],color=BUS,lw=3,alpha=0.6,solid_capstyle='round')
ax.annotate('',xy=(0.44,0.66),xytext=(0.58,0.72),arrowprops=dict(arrowstyle='->',color='#FFD700',lw=1.5,ls='dashed'))
ax.text(0.50,0.69,'EX\u2192EX',color='#FFD700',fontsize=8,ha='center')
ax.annotate('',xy=(0.58,0.54),xytext=(0.75,0.60),arrowprops=dict(arrowstyle='->',color='#FFD700',lw=1.5,ls='dashed'))
ax.text(0.68,0.57,'MEM\u2192EX',color='#FFD700',fontsize=8,ha='center')
ax.add_patch(FancyBboxPatch((0.52,0.56),0.14,0.03,boxstyle="round,pad=0.003",facecolor='#E74C3C',edgecolor='none',alpha=0.7))
ax.text(0.59,0.575,'STALL (load-use)',ha='center',color='white',fontsize=7,fontweight='bold')
ax.add_patch(FancyBboxPatch((0.38,0.44),0.14,0.03,boxstyle="round,pad=0.003",facecolor='#E74C3C',edgecolor='none',alpha=0.7))
ax.text(0.45,0.455,'FLUSH (branch)',ha='center',color='white',fontsize=7,fontweight='bold')
ax.legend(handles=[mpatches.Patch(color=CPU,label='Stage'),mpatches.Patch(color=BUS,label='Reg'),
    plt.Line2D([0],[0],color='#FFD700',ls='--',lw=1.5,label='Forwarding'),
    mpatches.Patch(color='#E74C3C',alpha=0.7,label='Stall/Flush')],loc='lower center',ncol=4,fontsize=8,
    facecolor='#222244',edgecolor='#444',labelcolor='#aaa',bbox_to_anchor=(0.5,-0.02))
plt.tight_layout()
plt.savefig(f'{base}/pipeline.png',dpi=150,bbox_inches='tight',facecolor=BG); plt.close()
print("pipeline.png OK")

# ===== MEMORY MAP =====
fig,ax = plt.subplots(figsize=(12,9),facecolor=BG)
ax.set_facecolor(BG); ax.set_xlim(0,1); ax.set_ylim(0,1); ax.axis('off')
ax.text(0.5,0.97,'Memory Map',ha='center',va='top',color='white',fontsize=16,fontweight='bold')
ax.text(0.5,0.93,'32-bit Address Space | Memory-Mapped I/O',ha='center',va='top',color='#888',fontsize=10)

blks=[
    (0.78,0.06,0.10,MEM,'Instruction Memory (ROM)','1KB | Read-Only','0x00000000','0x00000FFF'),
    (0.65,0.06,0.10,MEM,'Data Memory (RAM)','1KB | Read-Write | Byte-Enable','0x00001000','0x00001FFF'),
    (0.52,0.06,0.10,PER,'UART Controller','TX/RX FIFO | 5 Baud | RTS/CTS','0x00002000','0x0000201F'),
    (0.39,0.06,0.10,PER,'Timer','32-bit | Compare | Auto-Reload | IRQ','0x00003000','0x0000300F'),
    (0.26,0.06,0.10,PER,'GPIO Controller','16-bit | Edge/Level IRQ | W1C','0x00004000','0x0000401F'),
]
for y,h,_,c,n,d,a1,a2 in blks:
    ax.add_patch(FancyBboxPatch((0.18,y),0.62,h,boxstyle="round,pad=0.008",facecolor=c,edgecolor='none',alpha=0.85))
    ax.text(0.20,y+h*0.65,n,color='white',fontsize=10,fontweight='bold')
    ax.text(0.20,y+h*0.3,d,color='#ddd',fontsize=8)
    ax.text(0.84,y+h*0.65,a1,ha='left',color='#FFD700',fontsize=9,fontweight='bold')
    ax.text(0.84,y+h*0.3,a2,ha='left',color='#aaa',fontsize=8)

sm=[('Int Ctrl','8-Source','0x00005000'),('7-Seg','Display','0x00006000'),('LED','16-bit','0x00007000')]
sx=[0.18,0.52,0.68]
for i,((n,d,a),x) in enumerate(zip(sm,sx)):
    w=0.14 if i==0 else 0.13
    c=IO if i>0 else PER
    ax.add_patch(FancyBboxPatch((x,0.13),w,0.10,boxstyle="round,pad=0.008",facecolor=c,edgecolor='none',alpha=0.85))
    ax.text(x+w/2,0.20,n,ha='center',color='white',fontsize=8,fontweight='bold')
    ax.text(x+w/2,0.165,a,ha='center',color='#FFD700',fontsize=7)

ax.legend(handles=[mpatches.Patch(color=MEM,label='Memory'),mpatches.Patch(color=PER,label='Peripheral'),
    mpatches.Patch(color=IO,label='I/O')],loc='lower center',ncol=3,fontsize=9,
    facecolor='#222244',edgecolor='#444',labelcolor='#aaa',bbox_to_anchor=(0.5,-0.02))
plt.tight_layout()
plt.savefig(f'{base}/memory-map.png',dpi=150,bbox_inches='tight',facecolor=BG); plt.close()
print("memory-map.png OK")
print("Done!")
