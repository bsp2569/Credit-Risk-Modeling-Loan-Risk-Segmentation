# Actual results (fill in after SAS execution)

Dataset rows imported: ____ (expected 1000)
Train count: ____ | Test count: ____
Bad credit rate: ____
Holdout ROC-AUC: ____
Holdout accuracy at threshold 0.50: ____
Confusion matrix: TP ____ TN ____ FP ____ FN ____
Holdout total misclassification cost at 0.50: ____
Lowest-cost threshold in exploratory grid: ____ | cost: ____
Top observed high-risk segment(s): ____
Data quality exceptions: ____

## Resume bullets — fill only after verification
- Built an end-to-end SAS credit-risk analytics workflow on 1,000 historical applicant records using DATA Step, PROC SQL, and data-quality checks.
- Developed and evaluated a logistic regression risk classifier using PROC LOGISTIC, achieving **[verified holdout AUC]** ROC-AUC and **[verified accuracy]** accuracy.
- Compared decision thresholds using an asymmetric 5:1 misclassification cost framework and created risk segmentation reports using PROC SQL and PROC SGPLOT.
