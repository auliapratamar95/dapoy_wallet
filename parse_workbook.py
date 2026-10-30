import openpyxl
import json
import re

wb_val = openpyxl.load_workbook(r'assets/2026 Budget.xlsx', data_only=True)
wb_form = openpyxl.load_workbook(r'assets/2026 Budget.xlsx', data_only=False)

workbook_data = {'sheets': {}}

for sname in wb_val.sheetnames:
    ws_v = wb_val[sname]
    ws_f = wb_form[sname]
    
    # 1. Month metadata: strict MMYY pattern (01-12)(00-99)
    is_mmyy = bool(re.match(r'^(0[1-9]|1[0-2])\d{2}$', sname))
    month_num = int(sname[:2]) if is_mmyy else None
    year_num = int('20' + sname[2:]) if is_mmyy else None
    
    # Title
    title = str(ws_v['B2'].value or sname).strip()
    
    # 2. Incomes (B4:C12)
    incomes = []
    for r in range(4, 12):
        b = ws_v.cell(r, 2).value
        c = ws_v.cell(r, 3).value
        if b and str(b).strip().upper() not in ['INCOME', 'PEMASUKAN', 'TOTAL']:
            if isinstance(c, (int, float)):
                incomes.append({'source': str(b).strip(), 'amount': float(c), 'row': r})
    
    # 3. Budget Items
    budget_items = []
    for r in range(5, 36):
        d = ws_v.cell(r, 4).value
        e = ws_v.cell(r, 5).value
        f = ws_v.cell(r, 6).value
        g = ws_v.cell(r, 7).value
        h = ws_v.cell(r, 8).value
        
        # Check if this row is TOTAL
        if str(f).strip().upper() == 'TOTAL' or str(d).strip().upper() == 'TOTAL':
            continue
            
        if d and (e is not None or g is not None or h is not None):
            budget_items.append({
                'id': f'{sname}_b_{r}',
                'name': str(d).strip(),
                'budget': float(e) if isinstance(e, (int, float)) else 0.0,
                'category': str(f).strip() if f else 'Lain-lain',
                'actual': float(g) if isinstance(g, (int, float)) else 0.0,
                'remaining': float(h) if isinstance(h, (int, float)) else ((float(e) if isinstance(e, (int, float)) else 0.0) - (float(g) if isinstance(g, (int, float)) else 0.0)),
                'row': r,
                'formula_output': str(ws_f.cell(r, 7).value or ''),
            })
            
    # 4. KPI Cards
    kpis = {}
    for r in range(4, 10):
        j = ws_v.cell(r, 10).value
        k = ws_v.cell(r, 11).value
        if j and k is not None:
            k_clean = str(j).strip()
            if isinstance(k, (int, float)):
                kpis[k_clean] = float(k)
                
    # 5. Category Summaries (rows 10-20)
    category_summaries = []
    for r in range(10, 20):
        j = ws_v.cell(r, 10).value
        k = ws_v.cell(r, 11).value
        l = ws_v.cell(r, 12).value
        m = ws_v.cell(r, 13).value
        if j and str(j).strip().upper() not in ['TOTAL', 'BUDGET', 'KATEGORI'] and isinstance(k, (int, float)):
            category_summaries.append({
                'category': str(j).strip(),
                'budget': float(k) if isinstance(k, (int, float)) else 0.0,
                'actual': float(l) if isinstance(l, (int, float)) else 0.0,
                'remaining': float(m) if isinstance(m, (int, float)) else 0.0,
            })
            
    # 6. Bank & Selisih
    bank_balance = None
    discrepancy = None
    for r in range(19, 26):
        j = str(ws_v.cell(r, 10).value or '').strip().lower()
        k = ws_v.cell(r, 11).value
        if 'saldo' in j and isinstance(k, (int, float)):
            bank_balance = float(k)
        elif 'selisih' in j and isinstance(k, (int, float)):
            discrepancy = float(k)
            
    # 7. Transactions
    tx_header_row = None
    for r in range(30, 45):
        j = str(ws_v.cell(r, 10).value or '').strip().upper()
        l = str(ws_v.cell(r, 12).value or '').strip().upper()
        if j == 'TANGGAL' or l == 'KETERANGAN':
            tx_header_row = r
            break
            
    transactions = []
    if tx_header_row:
        cur_date = ''
        for r in range(tx_header_row + 1, ws_v.max_row + 1):
            j = ws_v.cell(r, 10).value
            k = ws_v.cell(r, 11).value
            l = ws_v.cell(r, 12).value
            m = ws_v.cell(r, 13).value
            
            # Date group header row
            if j and (k is None and l is None and m is None):
                cur_date = str(j).strip()
            elif l is not None or m is not None:
                if j and str(j).strip():
                    cur_date = str(j).strip()
                desc = str(l).strip() if l else ''
                amount = float(m) if isinstance(m, (int, float)) else 0.0
                entry_num = int(k) if isinstance(k, (int, float)) else len(transactions) + 1
                
                # Check mapping from formula
                linked_item = None
                row_ref = f'M{r}'
                for bi in budget_items:
                    if row_ref in bi['formula_output']:
                        linked_item = bi['name']
                        break
                        
                transactions.append({
                    'id': f'{sname}_tx_{r}',
                    'date': cur_date,
                    'entry_number': entry_num,
                    'description': desc,
                    'amount': amount,
                    'linked_budget_item': linked_item,
                    'row': r,
                })
                
    workbook_data['sheets'][sname] = {
        'sheet_name': sname,
        'title': title,
        'is_mmyy': is_mmyy,
        'month': month_num,
        'year': year_num,
        'incomes': incomes,
        'budget_items': budget_items,
        'kpis': kpis,
        'category_summaries': category_summaries,
        'bank_balance': bank_balance,
        'discrepancy': discrepancy,
        'transactions': transactions,
    }

with open('assets/budget_data.json', 'w', encoding='utf-8') as f:
    json.dump(workbook_data, f, indent=2, ensure_ascii=False)

print('Exported assets/budget_data.json successfully!')
for k, v in workbook_data['sheets'].items():
    print(f"Sheet {k}: {len(v['budget_items'])} budget items, {len(v['transactions'])} txs, {len(v['incomes'])} incomes")

