IMPORT STD;

EXPORT Finance := MODULE, FORWARD

                EXPORT Bundle := MODULE(Std.BundleBase)
                                EXPORT Name := 'Finance';
                                EXPORT Description := 'Generally useful Finance functions';
                                EXPORT Authors := ['Jim DeFabia','Richard Taylor','Bob Foreman'];
                                EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
                                EXPORT Copyright := 'Copyright (C) 2013 HPCC Systems';
                                EXPORT DependsOn := [];
                                EXPORT Version := '1.0.0';
                                EXPORT PlatformVersion := '4.0.0';
                END;

/**
* Returns the payment amount per loan period.
* 
* @param LoanAmt       The total loan amount.
* @param IntRate       The yearly interest rate charged.
* @param Term          The number of years in the loan term.
* @param PmtsPerYr     The number of payments paid per year. If omitted, the default is 12
* @return              The payment amount per period.
*/
                EXPORT UDECIMAL9_2 Payment(UDECIMAL9_2 LoanAmt, REAL4 IntRate, UNSIGNED2 Term, UNSIGNED2 PmtsPerYr=12) := FUNCTION
                                NumPmts := Term * PmtsPerYr;
                                Prate   := IntRate/PmtsPerYr/100;
                                POW     := POWER(1+Prate,NumPmts);
                                Raw     := LoanAmt * Prate * (POW / (POW-1));
                                RETURN ROUND(Raw,2);
                END;

/**
* Returns an amortization table.
* 
* @param LoanAmt       The total loan amount.
* @param IntRate       The yearly interest rate charged.
* @param Term          The number of years in the loan term.
* @param PmtsPerYr     The number of payments paid per year. If omitted, the default is 12
* @return              A recordset with a record for each loan period.
*/
                EXPORT Amortize(UDECIMAL9_2 LoanAmt, REAL4 IntRate, UNSIGNED2 Term, UNSIGNED2 PmtsPerYr=12) := FUNCTION

                                PaymentAmt := Payment(LoanAmt,IntRate, Term, PmtsPerYr);

                                OutRec := RECORD
                                                UNSIGNED2    PeriodNum;
                                                UDECIMAL9_2  Payment;
                                                UDECIMAL9_2  Principal;
                                                UDECIMAL9_2  Interest;
                                                UDECIMAL9_2  EndingPrincipal;
                                END;
                            
                                OutRec XF1(INTEGER C) := TRANSFORM
                                                SELF.PeriodNum := C;
                                                SELF.Payment   := PaymentAmt;
                                                SELF := [];
                                END;
                            
                                ds := DATASET(Term*PmtsPerYr,XF1(COUNTER));

                                OutRec XF2(OutRec L, OutRec R) := TRANSFORM
                                                SELF.Principal       := IF(L.Principal = 0,LoanAmt,L.EndingPrincipal);
                                                SELF.Interest        := SELF.Principal * (IntRate/PmtsPerYr/100);
                                                SELF.EndingPrincipal := SELF.Principal + SELF.Interest - PaymentAmt;
                                                SELF := R;
                                END;

                                RETURN ITERATE(ds,XF2(LEFT,RIGHT));
                END;
                
/**
* Returns a simple interest value.
* 
* @param Principal     Starting amount.
* @param IntRate       The interest rate charged.
* @return              The principal with interest added.
*/
                EXPORT SimpleInterest(UDECIMAL9_2 Principal, REAL4 IntRate) := FUNCTION
    UDECIMAL9_2 Interest := Principal * (IntRate/100);
                                RETURN Principal + Interest;
                END;

/**
* Returns a compound interest table.
* 
* @param Principal     Starting amount.
* @param IntRate       The yearly interest rate charged.
* @param Term          The number of years to calculate.
* @param Periods       The number of compounding periods per year. If omitted, the default is 12
* @return              A recordset with a record for each compounding period.
*/
                EXPORT CompoundInterest(UDECIMAL9_2 Principal, REAL4 IntRate, UNSIGNED2 Term, UNSIGNED2 Periods=12) := FUNCTION
                                OutRec := RECORD
                                                UNSIGNED2    PeriodNum;
                                                UDECIMAL9_2  Principal;
                                                UDECIMAL9_2  Interest;
                                                UDECIMAL9_2  NewPrincipal;
                                END;
                            
                                OutRec XF1(INTEGER C) := TRANSFORM
                                                SELF.PeriodNum := C;
                                                SELF := [];
                                END;
                            
                                ds := DATASET(Term*Periods,XF1(COUNTER));

                                OutRec XF2(OutRec L, OutRec R) := TRANSFORM
                                                SELF.Principal       := IF(L.Principal = 0,Principal,L.NewPrincipal);
                                                SELF.Interest        := SELF.Principal * (IntRate/Periods/100);
                                                SELF.NewPrincipal    := SELF.Principal + SELF.Interest;
                                                SELF := R;
                                END;

                                RETURN ITERATE(ds,XF2(LEFT,RIGHT));
                  
                END;
                
/**
* Returns the present value of a future amount, given .
* 
* @param FutureVal     The Future value to achieve.
* @param IntRate       The interest rate per period.
* @param Periods       The total number of periods.
* @return              The present value.
*/
                EXPORT PresentValue(UDECIMAL9_2 FutureVal, REAL4 IntRate, UNSIGNED2 Periods) := FUNCTION
                                s1 := POWER(1+(IntRate/100),periods);
                                s2 := 1 / s1;
                                RETURN ROUND(FutureVal * s2, 2);
                END;

/**
* Returns the net present value of a future amount, given .
* 
* @param FutureVal     The Future value to achieve.
* @param IntRate       The interest rate per period.
* @param Periods       The total number of periods left.
* @param OrigVal       The original inverstment amount.
* @return              The present value.
*/
                EXPORT NetPresentValue(UDECIMAL9_2 FutureVal, REAL4 IntRate, UNSIGNED2 Periods, UDECIMAL9_2 OrigVal) := FUNCTION
                                s1 := PresentValue(FutureVal, IntRate, Periods);
                                RETURN ROUND(s1 - OrigVal, 2);
                END;

                
/**
* Returns the future value of a present amount, after a specific number of periods.
* 
* @param Principal     Present amount.
* @param IntRate       The yearly interest rate.
* @param Term          The number of years to calculate.
* @param Periods       The number of compounding periods per year. If omitted, the default is 12
* @param Period        The period whose value to return.
* @return              The compounded value for the specified period.
*/
                EXPORT FutureValue(UDECIMAL9_2 Principal, REAL4 IntRate, UNSIGNED2 Term, UNSIGNED2 Periods=12, UNSIGNED2 Period) := 
                                   CompoundInterest(Principal, IntRate, Term, Periods)[Period].NewPrincipal;

END;


