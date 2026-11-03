"""Fetch original UCI Statlog German Credit dataset and convert to typed CSV."""
from pathlib import Path
import csv
import urllib.request
ROOT = Path(__file__).resolve().parent
URL = 'https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/german/german.data'
cols = ['checking_status','duration_months','credit_history','purpose','credit_amount',
'savings','employment','installment_rate','personal_status','guarantor','residence_years',
'property','age_years','other_installments','housing','existing_credits','job',
'dependents','telephone','foreign_worker','credit_label']
try:
    raw = urllib.request.urlopen(URL, timeout=30).read().decode('ascii')
except Exception as exc:
    raise SystemExit(f'Download failed: {exc}. Get german.data from UCI dataset 144 and save it in data/, then rerun.')
lines = [line.split() for line in raw.splitlines() if line.strip()]
assert len(lines) == 1000, f'Expected 1000 rows, found {len(lines)}'
assert all(len(row)==21 for row in lines)
assert {row[-1] for row in lines} == {'1','2'}
(ROOT/'data').mkdir(exist_ok=True)
with (ROOT/'data'/'german_credit.csv').open('w', newline='') as f:
    writer=csv.writer(f); writer.writerow(cols); writer.writerows(lines)
print('Created data/german_credit.csv with 1000 rows; target 1=good, 2=bad')
