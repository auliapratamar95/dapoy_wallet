import json
import urllib.request
import urllib.error

SUPABASE_URL = "https://vwfriffzafrklnwkqfns.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3ZnJpZmZ6YWZya2xud2txZm5zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwODkzMDEsImV4cCI6MjEwODY2NTMwMX0.eL3qPU3s3Oo62mtuA5T7e-ma_PFM9SPNSO59nfEI_3o"

headers = {
    "apikey": ANON_KEY,
    "Authorization": f"Bearer {ANON_KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates"
}

def post(table, data):
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    req = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req) as res:
            return True, res.status
    except urllib.error.HTTPError as e:
        return False, e.read().decode("utf-8")

def main():
    print("Checking if tables exist in Supabase...")
    test_url = f"{SUPABASE_URL}/rest/v1/budget_months?select=*"
    req = urllib.request.Request(test_url, headers=headers)
    try:
        with urllib.request.urlopen(req) as res:
            pass
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8")
        if "PGRST205" in err or "Could not find" in err:
            print("\n[PERINGATAN] Tabel belum dibuat di Supabase!")
            print("Silakan jalankan script SQL 'supabase_schema.sql' terlebih dahulu di:")
            print("https://supabase.com/dashboard/project/vwfriffzafrklnwkqfns/sql")
            return
        else:
            print("Error connecting:", err)
            return

    print("Tables found! Loading data from assets/budget_data.json...")
    with open("assets/budget_data.json", "r", encoding="utf-8") as f:
        data = json.load(f)

    sheets = data["sheets"]
    for sname, sheet in sheets.items():
        if not sheet.get("is_mmyy"):
            continue

        print(f"\n--- Mengunggah data bulan {sname} ({sheet['title']}) ---")
        
        # 1. Budget Month
        month_record = {
            "id": sname,
            "display_name": f"{['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'][sheet['month']-1]} {sheet['year']}",
            "title": sheet["title"],
            "month_number": sheet["month"],
            "year_number": sheet["year"],
            "bank_balance": sheet.get("bank_balance") or 0,
            "discrepancy": sheet.get("discrepancy") or 0
        }
        ok, res = post("budget_months", month_record)
        if not ok:
            print(f"Gagal upload budget_months: {res}")
            return
        print(f"[OK] Bulan {sname} tersimpan")

        # 2. Income sources
        for inc in sheet.get("incomes", []):
            inc_record = {
                "month_id": sname,
                "source": inc["source"],
                "amount": inc["amount"],
                "row_number": inc.get("row", 0)
            }
            post("income_sources", inc_record)
        print(f"[OK] {len(sheet.get('incomes', []))} Sumber pemasukan tersimpan")

        # 3. Budget items
        items_payload = []
        for bi in sheet.get("budget_items", []):
            items_payload.append({
                "id": bi["id"],
                "month_id": sname,
                "name": bi["name"],
                "category": bi["category"],
                "budget": bi["budget"],
                "actual": bi["actual"],
                "remaining": bi["remaining"],
                "row_number": bi.get("row", 0)
            })
        if items_payload:
            ok, res = post("budget_items", items_payload)
            if not ok:
                print(f"Gagal upload budget_items: {res}")
            else:
                print(f"[OK] {len(items_payload)} Pos anggaran tersimpan")

        # 4. Daily expenses
        txs_payload = []
        for tx in sheet.get("transactions", []):
            txs_payload.append({
                "id": tx["id"],
                "month_id": sname,
                "date": tx["date"],
                "entry_number": tx["entry_number"],
                "description": tx["description"],
                "amount": tx["amount"],
                "linked_budget_item": tx.get("linked_budget_item"),
                "row_number": tx.get("row", 0)
            })
        if txs_payload:
            # Batch in chunks of 50
            for i in range(0, len(txs_payload), 50):
                chunk = txs_payload[i:i+50]
                post("daily_expenses", chunk)
            print(f"[OK] {len(txs_payload)} Transaksi tersimpan")

    print("\n[SUCCESS] SEMUA DATA EXCEL BERHASIL DI-MIGRASI KE SUPABASE!")

if __name__ == "__main__":
    main()

