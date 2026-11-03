# Credit Risk Modeling & Loan Risk Segmentation in SAS

**Stack:** Base SAS, SAS/STAT, DATA Step, PROC SQL, PROC SURVEYSELECT, PROC LOGISTIC, PROC SGPLOT, PROC REPORT.

## Business problem
Estimate probability of an applicant being classified as **bad credit**, segment risk, and compare decision thresholds with asymmetric error costs. This is a **portfolio demonstration**, not a production lending decision system.

## Dataset
UCI Statlog (German Credit Data), 1,000 records and 20 predictors, originally donated 1994. Labels: `1=good`, `2=bad`. UCI specifies a misclassification cost of 5 for classifying bad credit as good and 1 for classifying good credit as bad. Historical data, not representative of modern lending; not suitable for real lending decisions. Source: https://archive.ics.uci.edu/dataset/144/statlog-german-credit-data (DOI 10.24432/C5NC77, CC BY 4.0).

## Run
1. Install Python 3 and run `python download_data.py` from project root (requires internet); alternatively download `german.data` from UCI and adapt the downloader.
2. Use a SAS installation with SAS/STAT and SAS/STAT survey procedures. Set `%let root=` in `sas/credit_risk_pipeline.sas` to the absolute project directory (use forward slashes).
3. Run the SAS program. SAS output datasets appear in `outputs/` as SAS data files. Review log and PROC output for warnings.
4. Capture the *actual* test ROC-AUC, confusion matrix, accuracy, false-negative count and threshold-cost results in `RESULTS_TEMPLATE.md`.

## Workflow
- Fixed-schema CSV import and checks for missing, invalid and duplicate records.
- Descriptive risk analysis by checking account status and financial attributes.
- Seeded stratified 70/30 split; logistic model fitted on training only.
- Score unseen test observations, evaluate threshold 0.50 and a 0.05–0.95 grid using UCI's asymmetric costs.
- Visualize observed bad-credit rate and report threshold comparisons.

## Caveats
- The outcome is a **good/bad credit risk label**, not a timestamped observed loan default event. Do not describe it as a verified default probability.
- AUC calculated on the holdout set; threshold chosen from that same test set is exploratory only. For a defensible threshold, add a separate validation set or cross-validation and reserve the test set for final evaluation.
- Demographic variables are omitted from modeling where possible, but checking for discrimination and regulatory compliance is still required for any real use.
- No SAS runtime was available to execute this SAS code in this environment; check your installation/version and validate output before claiming results.
