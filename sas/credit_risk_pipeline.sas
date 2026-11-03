/* German Credit Risk | Base SAS + SAS/STAT | Run after download_data.py */
%let root=/home/your_username/sas_credit_risk; /* EDIT THIS PATH */
%let seed=2026;
libname out "&root./outputs";
filename source "&root./data/german_credit.csv";

/* Import with fixed schema to avoid PROC IMPORT type guessing. */
data work.raw;
 infile source dsd firstobs=2 truncover lrecl=32767;
 length checking_status $4 credit_history $4 purpose $5 savings $4 employment $4
        personal_status $4 guarantor $4 property $4 other_installments $4
        housing $4 job $4 telephone $4 foreign_worker $4;
 input checking_status :$4. duration_months credit_history :$4. purpose :$5.
       credit_amount savings :$4. employment :$4. installment_rate
       personal_status :$4. guarantor :$4. residence_years property :$4.
       age_years other_installments :$4. housing :$4. existing_credits
       job :$4. dependents telephone :$4. foreign_worker :$4. credit_label;
 row_id=_n_;
 bad_credit=(credit_label=2); /* UCI: 1 good, 2 bad */
run;

/* Quality controls: keep failures visible instead of silently deleting rows. */
proc sql;
 create table out.quality_summary as
 select count(*) as rows_loaded,
        sum(missing(checking_status)) as missing_checking,
        sum(missing(duration_months)) as missing_duration,
        sum(missing(credit_amount)) as missing_amount,
        sum(missing(credit_label)) as missing_target,
        sum(duration_months<=0 or credit_amount<=0 or age_years<18) as invalid_ranges,
        sum(credit_label not in (1,2)) as invalid_labels
 from work.raw;
quit;
proc sort data=work.raw out=work.unique nodupkey dupout=out.duplicate_rows;
 by row_id;
run;
data work.model_base;
 set work.unique;
 if cmiss(of checking_status credit_history savings employment)=0
    and nmiss(duration_months,credit_amount,age_years,credit_label)=0
    and duration_months>0 and credit_amount>0 and age_years>=18
    and credit_label in (1,2);
 length duration_band $8 amount_band $8;
 if duration_months<=12 then duration_band='0-12';
 else if duration_months<=24 then duration_band='13-24';
 else duration_band='25+';
 if credit_amount<2000 then amount_band='<2000';
 else if credit_amount<5000 then amount_band='2000-4999';
 else amount_band='5000+';
run;

/* EDA and business segmentation */
proc freq data=work.model_base; tables bad_credit checking_status*bad_credit / missing; run;
proc means data=work.model_base n mean median min max;
 class bad_credit; var duration_months credit_amount age_years; run;
proc sql;
 create table out.segment_risk as
 select checking_status, count(*) as applicants,
        sum(bad_credit) as bad_cases,
        mean(bad_credit) as bad_rate format=percent8.2,
        sum(credit_amount) as total_requested_amount
 from work.model_base group by checking_status;
quit;

/* Reproducible stratified train/test split (70/30). */
proc surveyselect data=work.model_base out=work.split
 method=srs samprate=0.70 seed=&seed outall;
 strata bad_credit;
run;
data work.train work.test;
 set work.split;
 if Selected then output work.train;
 else output work.test;
run;

/* Logistic regression: event='1' explicitly means BAD credit. */
proc logistic data=work.train descending;
 class checking_status(ref='A14') credit_history(ref='A32')
       savings(ref='A65') employment(ref='A73')
       housing(ref='A152') / param=ref;
 model bad_credit(event='1') = duration_months credit_amount age_years
      installment_rate existing_credits checking_status credit_history
      savings employment housing;
 score data=work.test out=out.test_scores;
 store out.credit_model;
run;

/* PROC LOGISTIC SCORE output contains P_1 (bad-credit probability).
   Review variable names in PROC CONTENTS if SAS version differs. */
proc contents data=out.test_scores; run;
data out.risk_decisions;
 set out.test_scores;
 bad_probability=P_1;
 if missing(bad_probability) then delete;
 predicted_bad=(bad_probability>=0.50);
 if bad_probability>=0.60 then risk_band='HIGH  ';
 else if bad_probability>=0.30 then risk_band='MEDIUM';
 else risk_band='LOW   ';
 false_negative=(bad_credit=1 and predicted_bad=0);
 false_positive=(bad_credit=0 and predicted_bad=1);
 /* Dataset cost matrix: FN (bad predicted good)=5, FP=1. */
 misclassification_cost=5*false_negative+false_positive;
run;
proc sql;
 create table out.model_metrics as
 select count(*) as test_n,
        mean(predicted_bad=bad_credit) as accuracy format=percent8.2,
        sum(predicted_bad=1 and bad_credit=1) as tp,
        sum(predicted_bad=0 and bad_credit=0) as tn,
        sum(predicted_bad=1 and bad_credit=0) as fp,
        sum(predicted_bad=0 and bad_credit=1) as fn,
        sum(misclassification_cost) as total_cost,
        sum(misclassification_cost)/count(*) as cost_per_applicant
 from out.risk_decisions;
quit;
/* Evaluate thresholds under asymmetric cost assumptions. */
data work.threshold_grid;
 set out.risk_decisions;
 do threshold=0.05 to 0.95 by 0.05;
  decision_bad=(bad_probability>=threshold);
  cost=5*(bad_credit=1 and decision_bad=0)
       +(bad_credit=0 and decision_bad=1);
  output;
 end;
run;
proc sql;
 create table out.threshold_costs as
 select threshold format=4.2, count(*) as n,
        sum(cost) as total_cost, mean(cost) as mean_cost
 from work.threshold_grid group by threshold order by mean_cost;
quit;
/* For ROC-AUC on holdout: use predictions as single predictor in PROC LOGISTIC.
   AUC is printed in Association of Predicted Probabilities and Observed Responses. */
proc logistic data=out.risk_decisions plots(only)=roc;
 model bad_credit(event='1')=bad_probability;
 roc 'Holdout score' pred=bad_probability;
run;
proc sgplot data=out.segment_risk;
 vbar checking_status / response=bad_rate datalabel;
 yaxis label='Observed bad-credit rate' valuesformat=percent8.0;
 title 'Observed bad-credit rate by checking-account status';
run;
proc report data=out.threshold_costs nowd; title 'Decision threshold cost comparison'; run;
