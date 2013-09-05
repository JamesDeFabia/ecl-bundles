
/***************************************************************************
         Self Test
 **************************************************************************/


//EXPORT __selfTest := MODULE
//IMPORT Finance;

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


//END;          