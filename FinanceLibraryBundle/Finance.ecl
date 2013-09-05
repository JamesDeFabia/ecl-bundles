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



/***************************************************************************
         Self Test
 **************************************************************************/


  EXPORT __selfTest := MODULE


// sample values for demo/testing purposes
// adjust these as needed  

LoanAmt   := 85000;  //Loan Amount 
IntRate   := 10.58;  // Rate of Interest
Term      := 3;      // Number of years
PmtsPerYr := 12;     // Number of Payments per year
Principal := 85000;  // Principal
Periods   := 12;     // Number of periods per year
FutureVal := 100000; // Future value to achieve  
OrigVal   := 80000;  // Starting value
Period    := 13;     // Single Period to return


// returns an amortization schedule detailing each periodic payment on a loan.
// This shows the ratio of principal and interest and demonstrates 
// how a loan's principal amount decreases over time.

a := Finance.Amortize(LoanAmt,IntRate,Term) ;
EXPORT Result1 := OUTPUT (a);                                                       //Result 1


//returns 13th row from the amortization schedule
// Use this to see a specific payment (Period)
EXPORT Result2 := OUTPUT (a[Period]);                                               //Result 2


//returns the payment amount for the loan period

b := Finance.Payment(LoanAmt,IntRate,Term); 
EXPORT Result3 := OUTPUT(b);                                                        //Result 3



// Calculates simple interest
// Simple interest is calculated on remaining principal amount
c := Finance.SimpleInterest(LoanAmt,IntRate);
EXPORT Result4 := OUTPUT(c);                                                         //Result 4


// returns table of compounding interest
// interest accumulates and new interest is calculated on 
// principal amount + previous interest earned
d :=  Finance.CompoundInterest(Principal,IntRate,Term);
EXPORT Result5 := OUTPUT (d);                                                         //Result 5
//returns 13th row from the compound interest table
EXPORT Result6 := OUTPUT (d[Period]);                                                 //Result 6


// Returns the present value of a future amount
e :=  Finance.PresentValue(FutureVal,IntRate,Periods);
EXPORT Result7 := OUTPUT(e);                                                          //Result 7


// Returns the net present value of a future amount

f :=  Finance.NetPresentValue(FutureVal,IntRate,Periods,OrigVal);
EXPORT Result8 := OUTPUT(f);                                                          //Result 8
                    



// Returns the future value of a present amount after a specific number of periods.

g := Finance.FutureValue(Principal,IntRate,Term,Periods,Period);
EXPORT Result9 := OUTPUT(g);                                                          //Result 9


  END;          
END;


