import re
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_JUSTIFY
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
                                HRFlowable, ListFlowable, ListItem)

SRC = r"E:/devops/w1/drive-download-20260920T050145Z-1-001/praktikum-devops/minggu-01/dokumen/LAPORAN-PRAKTIKUM.md"
OUT = r"E:/devops/w1/drive-download-20260920T050145Z-1-001/praktikum-devops/minggu-01/dokumen/M01_4332511050_Gandhi.pdf"

def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

def inline(t):
    t = esc(t)
    t = re.sub(r'`([^`]+)`', lambda m: '<font face="Courier">' + m.group(1) + '</font>', t)
    t = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', t)
    t = re.sub(r'\*(.+?)\*', r'<i>\1</i>', t)
    return t

ss = getSampleStyleSheet()
title_style = ParagraphStyle('title', parent=ss['Title'], fontSize=18, leading=22, spaceAfter=8, textColor=colors.HexColor('#10243b'))
h2 = ParagraphStyle('h2', parent=ss['Heading2'], fontSize=13, leading=16, textColor=colors.HexColor('#1a3c5e'), spaceBefore=12, spaceAfter=6)
h1 = ParagraphStyle('h1', parent=ss['Heading1'], fontSize=15, leading=18, spaceBefore=8, spaceAfter=6)
body = ParagraphStyle('body', parent=ss['BodyText'], fontSize=10, leading=14, alignment=TA_JUSTIFY, spaceAfter=6)
quote = ParagraphStyle('quote', parent=body, leftIndent=12, rightIndent=12, textColor=colors.HexColor('#333333'),
                       backColor=colors.HexColor('#eef2f6'), borderPadding=6, spaceAfter=6)
code = ParagraphStyle('code', parent=body, fontName='Courier', fontSize=9, leading=12,
                      backColor=colors.HexColor('#f5f5f5'), borderPadding=6, spaceAfter=6)
cell = ParagraphStyle('cell', parent=body, fontSize=8, leading=11, alignment=TA_LEFT, spaceAfter=0)
cellh = ParagraphStyle('cellh', parent=cell, textColor=colors.white, fontName='Helvetica-Bold')

def parse_table(lines):
    rows = []
    for ln in lines:
        cells = [c.strip() for c in ln.strip().strip('|').split('|')]
        rows.append(cells)
    data = []
    for ri, r in enumerate(rows):
        sty = cellh if ri == 0 else cell
        data.append([Paragraph(inline(c), sty) for c in r])
    t = Table(data, colWidths=[None] * len(rows[0]), hAlign='LEFT')
    t.setStyle(TableStyle([
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#cccccc')),
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a3c5e')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f4f7fa')]),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('RIGHTPADDING', (0, 0), (-1, -1), 4),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ]))
    return t

def build():
    with open(SRC, encoding='utf-8') as f:
        raw = f.read()
    raw = raw.replace('\u274c', 'X').replace('\u2705', 'V')
    lines = raw.split('\n')
    flow, i, n = [], 0, len(lines)
    in_code, code_buf = False, []
    while i < n:
        ln = lines[i]
        if ln.strip().startswith('```'):
            if not in_code:
                in_code, code_buf = True, []
            else:
                in_code = False
                flow.append(Paragraph(esc('\n'.join(code_buf)), code))
            i += 1
            continue
        if in_code:
            code_buf.append(ln); i += 1; continue
        s = ln.strip()
        if s == '':
            i += 1; continue
        if s == '---':
            flow.append(HRFlowable(width='100%', thickness=0.6, color=colors.HexColor('#cccccc'), spaceBefore=6, spaceAfter=6))
            i += 1; continue
        if s.startswith('|') and s.endswith('|'):
            tbl = []
            while i < n and lines[i].strip().startswith('|'):
                tbl.append(lines[i]); i += 1
            if len(tbl) >= 2 and set(tbl[1].replace('|', '').replace('-', '').replace(' ', '').replace(':', '')) == set():
                tbl = [tbl[0]] + tbl[2:]
            flow.append(parse_table(tbl)); flow.append(Spacer(1, 4))
            continue
        if s.startswith('>'):
            q = []
            while i < n and lines[i].strip().startswith('>'):
                q.append(lines[i].strip()[1:].strip()); i += 1
            flow.append(Paragraph(inline(' '.join(q)), quote)); continue
        if s.startswith('- '):
            items = []
            while i < n and lines[i].strip().startswith('- '):
                items.append(ListItem(Paragraph(inline(lines[i].strip()[2:]), body))); i += 1
            flow.append(ListFlowable(items, bulletType='bullet', start='\u2022', leftIndent=14)); continue
        if s.startswith('# '):
            flow.append(Paragraph(inline(s[2:]), title_style)); i += 1; continue
        if s.startswith('## '):
            flow.append(Paragraph(inline(s[3:]), h2)); i += 1; continue
        if s.startswith('### '):
            flow.append(Paragraph(inline(s[4:]), h1)); i += 1; continue
        flow.append(Paragraph(inline(s), body)); i += 1
    return flow

doc = SimpleDocTemplate(OUT, pagesize=A4, leftMargin=2 * cm, rightMargin=2 * cm,
                        topMargin=2 * cm, bottomMargin=2 * cm,
                        title='Laporan Praktikum Minggu 1 - Gandhi',
                        author='Muhammad Gandhi Putra')
doc.build(build())
print("PDF written:", OUT)
